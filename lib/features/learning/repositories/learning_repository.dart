import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson_model.dart';
import '../models/video_model.dart';
import '../../../core/services/context_engine_service.dart';

class LearningRepository {
  final SupabaseClient _supabase;

  // Offline cache stores only Storage lessons (LessonModel).
  // YouTube videos are always fetched fresh.
  static List<LessonModel> _offlineLessonCache = [];

  LearningRepository(this._supabase);

  // ── Upload / admin ────────────────────────────────────────────────────────

  Future<LessonModel?> uploadLesson(LessonModel lesson) async {
    try {
      final response = await _supabase
          .from('lessons')
          .insert(lesson.toInsertJson())
          .select()
          .single();
      return LessonModel.fromJson(response);
    } catch (e) {
      debugPrint('uploadLesson error: $e');
      return null;
    }
  }

  Future<List<LessonModel>> fetchMyUploads(String userId) async {
    try {
      final response = await _supabase
          .from('lessons')
          .select()
          .eq('uploaded_by', userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => LessonModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('fetchMyUploads error: $e');
      return [];
    }
  }

  Future<List<LessonModel>> fetchPendingLessons() async {
    try {
      final response = await _supabase
          .from('lessons')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => LessonModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('fetchPendingLessons error: $e');
      return [];
    }
  }

  Future<bool> approveLesson(String lessonId, String adminId) async {
    try {
      await _supabase.from('lessons').update({
        'status': 'approved',
        'reviewed_by': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', lessonId);
      return true;
    } catch (e) {
      debugPrint('approveLesson error: $e');
      return false;
    }
  }

  Future<bool> rejectLesson(
      String lessonId, String adminId, String reason) async {
    try {
      await _supabase.from('lessons').update({
        'status': 'rejected',
        'reviewed_by': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
      }).eq('id', lessonId);
      return true;
    } catch (e) {
      debugPrint('rejectLesson error: $e');
      return false;
    }
  }

  Future<bool> isAdmin(String userId) async {
    try {
      final response = await _supabase
          .from('admin_users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // ── Adaptive feed ─────────────────────────────────────────────────────────

  /// Returns a combined feed of Storage lessons + YouTube videos,
  /// filtered by context (motion, network) and sorted newest-first.
  Future<List<LessonModel>> fetchAdaptiveViewportFeed({
    required String userUuid,
    required UserContextState ambientContext,
  }) async {
    try {
      final results = await _fetchFromSupabase(
        userUuid: userUuid,
        ambientContext: ambientContext,
      );

      if (results.isNotEmpty) {
        _offlineLessonCache = results;
      }

      return results;
    } catch (e, st) {
      debugPrint('fetchAdaptiveViewportFeed error: $e\n$st');

      // Offline fallback — only Storage lessons are cached.
      if (_offlineLessonCache.isNotEmpty) {
        return _offlineLessonCache.where((l) {
          if (ambientContext.isInMotion && !l.safeForMotion) return false;
          if (ambientContext.networkStrength == AppNetworkStrength.weak &&
              l.format == 'video') return false;
          return true;
        }).toList();
      }

      return [];
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<List<LessonModel>> searchLessons({required String query}) async {
    try {
      final response = await _supabase
          .from('lessons')
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%,content.ilike.%$query%')
          .limit(20);

      return (response as List<dynamic>)
          .map((row) => LessonModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('searchLessons error: $e\n$st');
      return [];
    }
  }

  // ── Progress ──────────────────────────────────────────────────────────────

  Future<void> logLessonCompletion({
    required String userUuid,
    required String lessonId, // uuid, matches user_progress.lesson_id
    required int score,
  }) async {
    try {
      await _supabase.from('user_progress').upsert({
        'user_id': userUuid,
        'lesson_id': lessonId,
        'score': score,
        'last_accessed': DateTime.now().toIso8601String(),
        'is_completed': true,
      });
    } catch (e, st) {
      debugPrint('logLessonCompletion error: $e\n$st');
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchUserProfile({
    required String userUuid,
  }) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userUuid);

      if ((response as List).isEmpty) return null;
      return response.first;
    } catch (e, st) {
      debugPrint('fetchUserProfile error: $e\n$st');
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<List<LessonModel>> _fetchFromSupabase({
    required String userUuid,
    required UserContextState ambientContext,
  }) async {
    // Completed lesson UUIDs to exclude.
    final completedRows = await _supabase
        .from('user_progress')
        .select('lesson_id')
        .eq('user_id', userUuid)
        .eq('is_completed', true);

    final completedIds = (completedRows as List<dynamic>)
        .map((row) => (row as Map<String, dynamic>)['lesson_id']?.toString())
        .whereType<String>()
        .toList();

    // Fetch both tables in parallel.
    final results = await Future.wait([
      _fetchApprovedLessons(
        ambientContext: ambientContext,
        completedIds: completedIds,
      ),
      _fetchYouTubeVideos(),
    ]);

    final lessons = results[0] as List<LessonModel>;
    final ytAsLessons = results[1] as List<LessonModel>;

    final combined = [...lessons, ...ytAsLessons];
    combined.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return combined.take(20).toList();
  }

  /// Fetches approved, published lessons from `public.lessons`.
  /// Applies context filters (motion, network strength) that only exist here.
  Future<List<LessonModel>> _fetchApprovedLessons({
    required UserContextState ambientContext,
    required List<String> completedIds,
  }) async {
    try {
      var query = _supabase
          .from('lessons')
          .select()
          .eq('status', 'approved')
          .eq('is_published', true);

      if (completedIds.isNotEmpty) {
        query = query.not('id', 'in', completedIds);
      }

      if (ambientContext.isInMotion) {
        query = query.eq('safe_for_motion', true);
      }

      switch (ambientContext.networkStrength) {
        case AppNetworkStrength.weak:
          query = query
              .eq('min_network_strength', 'weak')
              .neq('format', 'video');
          break;
        case AppNetworkStrength.medium:
          query = query
              .inFilter('min_network_strength', ['weak', 'medium']);
          break;
        case AppNetworkStrength.strong:
          break;
      }

      final response =
          await query.order('created_at', ascending: false).limit(10);

      return (response as List<dynamic>)
          .map((row) => LessonModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('_fetchApprovedLessons error: $e\n$st');
      return [];
    }
  }

  /// Fetches all rows from `public.videos` (YouTube) and adapts them into
  /// [LessonModel] so the existing feed UI can render them without changes.
  ///
  /// The `video_url` field is set to `yt:<youtube_video_id>` so downstream
  /// players know to use the YouTube player instead of Chewie.
  Future<List<LessonModel>> _fetchYouTubeVideos() async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List<dynamic>).map((row) {
        final v = VideoModel.fromJson(row as Map<String, dynamic>);
        return LessonModel(
          id: v.id,
          title: v.title,
          description: v.description ?? '',
          content: '',
          category: v.topic ?? v.channelTitle ?? 'YouTube',
          videoUrl: 'yt:${v.youtubeVideoId}',
          thumbnailUrl: v.thumbnail,
          durationSeconds: v.durationSeconds,
          // YouTube videos have no storage-specific constraints.
          difficultyLevel: 'beginner',
          format: 'video',
          minNetworkStrength: 'medium',
          safeForMotion: false,
          status: 'approved',
          isPublished: true,
          createdAt: v.createdAt,
        );
      }).toList();
    } catch (e, st) {
      debugPrint('_fetchYouTubeVideos error: $e\n$st');
      return [];
    }
  }
}