import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson_model.dart';
import '../models/video_model.dart';
import '../../../core/services/context_engine_service.dart';

const _kLessonVideoBucket = 'lesson_videos';

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
          if (ambientContext.isInMotion && !l.safeForMotion) {
            return false;
          }
          switch (ambientContext.networkStrength) {
            case AppNetworkStrength.weak:
              // Only weak-tagged content qualifies; untagged excluded (Option B).
              if (l.minNetworkStrength != 'weak') return false;
              break;
            case AppNetworkStrength.medium:
              // Weak- or medium-tagged content qualifies; untagged excluded.
              if (l.minNetworkStrength != 'weak' &&
                  l.minNetworkStrength != 'medium') {
                return false;
              }
              break;
            case AppNetworkStrength.strong:
              // No filter — everything cached qualifies.
              break;
          }
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

  /// Computes user stats from `user_progress`.
  /// - lessonsCount: number of completed lessons
  /// - totalXp: sum of `score` for completed lessons
  /// - streak: consecutive-day streak based on completion days
  /// - rank: rank by totalXp among all users (desc)
  Future<Map<String, dynamic>> fetchUserStatsFromProgress({
    required String userUuid,
  }) async {
    try {
      final completedRows = await _supabase
          .from('user_progress')
          .select('score,last_accessed,is_completed')
          .eq('user_id', userUuid)
          .eq('is_completed', true);

      final completed = (completedRows as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      final lessonsCount = completed.length;
      final totalXp = completed.fold<int>(0, (sum, row) {
        final score = row['score'];
        if (score == null) return sum;
        return sum + (score as num).toInt();
      });

      // streak: consecutive days with at least one completion (based on last_accessed day)
      final completedDates = completed
          .map((row) {
            final raw = row['last_accessed'];
            if (raw == null) return null;
            final parsed = DateTime.tryParse(raw.toString());
            if (parsed == null) return null;
            return DateTime(parsed.year, parsed.month, parsed.day);
          })
          .whereType<DateTime>()
          .toSet()
          .toList();

      completedDates.sort((a, b) => b.compareTo(a));

      int streak = 0;
      if (completedDates.isNotEmpty) {
        final latest = completedDates.first;
        var cursor = latest;
        while (completedDates.any((d) => d.isAtSameMomentAs(cursor))) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        }
      }

      // rank: sum of xp per user (completed only)
      final allCompleted = await _supabase
          .from('user_progress')
          .select('user_id,score')
          .eq('is_completed', true);

      final xpByUser = <String, int>{};
      for (final rowAny in (allCompleted as List<dynamic>)) {
        final row = rowAny as Map<String, dynamic>;
        final uid = row['user_id']?.toString();
        if (uid == null) continue;
        final score = row['score'];
        final sc = score == null ? 0 : (score as num).toInt();
        xpByUser[uid] = (xpByUser[uid] ?? 0) + sc;
      }

      final sorted = xpByUser.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final idx = sorted.indexWhere((e) => e.key == userUuid);
      final rank = idx >= 0 ? idx + 1 : sorted.length + 1;

      return {
        'lessonsCount': lessonsCount,
        'totalXp': totalXp,
        'streak': streak,
        'rank': rank,
      };
    } catch (e, st) {
      debugPrint('fetchUserStatsFromProgress error: $e\n$st');
      return {
        'lessonsCount': 0,
        'totalXp': 0,
        'streak': 0,
        'rank': 0,
      };
    }
  }

  /// Returns category names the user watched recently.
  /// Uses completed `user_progress` ordered by `last_accessed`, then maps
  /// `lesson_id -> lessons.category`.
  Future<List<Map<String, dynamic>>> fetchUserRecentCategoriesFromProgress({
    required String userUuid,
    int limit = 6,
  }) async {
    try {
      final progress = await _supabase
          .from('user_progress')
          .select('lesson_id,last_accessed')
          .eq('user_id', userUuid)
          .eq('is_completed', true)
          .order('last_accessed', ascending: false)
          .limit(120);

      final progressList = progress as List<dynamic>;

      final lessonIds = progressList
          .map((e) => (e as Map<String, dynamic>)['lesson_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      if (lessonIds.isEmpty) return [];

      final lessons = await _supabase
          .from('lessons')
          .select('id,category')
          .inFilter('id', lessonIds);

      final lessonById = <String, String>{};
      for (final rowAny in (lessons as List<dynamic>)) {
        final row = rowAny as Map<String, dynamic>;
        final id = row['id']?.toString();
        final cat = row['category']?.toString();
        if (id == null || cat == null) continue;
        lessonById[id] = cat;
      }

      final categories = <String, Map<String, dynamic>>{};
      for (final rowAny in progressList) {
        final row = rowAny as Map<String, dynamic>;
        final lid = row['lesson_id']?.toString();
        if (lid == null) continue;
        final cat = lessonById[lid];
        if (cat == null || cat.isEmpty) continue;
        if (!categories.containsKey(cat)) {
          categories[cat] = {'name': cat};
        }
        if (categories.length >= limit) break;
      }

      return categories.values.toList();
    } catch (e, st) {
      debugPrint('fetchUserRecentCategoriesFromProgress error: $e\n$st');
      return [];
    }
  }

  /// Leaderboard based on total XP from `user_progress.score` (completed only).
  /// - weekly=true: only last 7 days from last_accessed
  Future<List<Map<String, dynamic>>> fetchLeaderboardFromProgress({
    required bool weekly,
    int limit = 10,
  }) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));

      var query = _supabase
          .from('user_progress')
          .select('user_id,score')
          .eq('is_completed', true);

      if (weekly) {
        query = query.gte('last_accessed', start.toIso8601String());
      }

      final rows = await query;

      final xpByUser = <String, int>{};
      for (final rowAny in (rows as List<dynamic>)) {
        final row = rowAny as Map<String, dynamic>;
        final uid = row['user_id']?.toString();
        if (uid == null) continue;
        final score = row['score'];
        final sc = score == null ? 0 : (score as num).toInt();
        xpByUser[uid] = (xpByUser[uid] ?? 0) + sc;
      }

      if (xpByUser.isEmpty) return [];

      final sorted = xpByUser.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final top = sorted.take(limit).toList();
      final ids = top.map((e) => e.key).toList();

      final profileRows = await _supabase
          .from('profiles')
          .select('id,full_name,username')
          .inFilter('id', ids);

      final profileById = <String, Map<String, dynamic>>{};
      for (final rowAny in (profileRows as List<dynamic>)) {
        final row = rowAny as Map<String, dynamic>;
        final id = row['id']?.toString();
        if (id == null) continue;
        profileById[id] = row;
      }

      return List.generate(top.length, (i) {
        final uid = top[i].key;
        final xp = top[i].value;
        final pr = profileById[uid];

        final fullName = (pr?['full_name'] as String?)?.trim();
        final username = (pr?['username'] as String?)?.trim();

        return {
          'rank': i + 1,
          'user_id': uid,
          'name': (fullName != null && fullName.isNotEmpty)
              ? fullName
              : (username ?? uid),
          'handle': (username != null && username.isNotEmpty)
              ? (username.startsWith('@') ? username : '@$username')
              : '@user',
          'xp': xp,
          'isCurrentUser': false,
          'trendingUp': true,
        };
      });
    } catch (e, st) {
      debugPrint('fetchLeaderboardFromProgress error: $e\n$st');
      return [];
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<List<LessonModel>> _fetchFromSupabase({

    required String userUuid,
    required UserContextState ambientContext,
  }) async {
    // Fetch the user's selected learning categories to scope recommendations.
    List<String> categories = [];
    try {
      final prefsRow = await _supabase
          .from('user_preferences')
          .select('selected_categories')
          .eq('user_id', userUuid)
          .maybeSingle();
      categories =
          (prefsRow?['selected_categories'] as List<dynamic>?)?.cast<String>() ??
              [];
    } catch (e) {
      debugPrint('Failed to load user categories for feed filtering: $e');
    }

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
    final results = await Future.wait<List<LessonModel>>([
      _fetchApprovedLessons(
        ambientContext: ambientContext,
        completedIds: completedIds,
        categories: categories,
      ),
      _fetchYouTubeVideos(categories: categories),
    ]);

    final lessons = results[0];
    final ytAsLessons = results[1];

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
    List<String> categories = const [],
  }) async {
    try {
      var query = _supabase
          .from('lessons')
          .select()
          .eq('status', 'approved')
          .eq('is_published', true);

      // Only filter by category if the user has selected any — an empty
      // list means "no preference set," not "match nothing."
      if (categories.isNotEmpty) {
        query = query.inFilter('category', categories);
      }

      if (completedIds.isNotEmpty) {
        query = query.not('id', 'in', completedIds);
      }


      if (ambientContext.isInMotion) {
        query = query.eq('safe_for_motion', true);
      }

      switch (ambientContext.networkStrength) {
        case AppNetworkStrength.weak:
          // Weak signal: only content explicitly tagged safe for weak signal.
          // Untagged rows are excluded (Option B — untagged = treated as
          // requiring strong signal).
          query = query.eq('min_network_strength', 'weak');
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

      return (response as List<dynamic>).map((row) {
        final json = row as Map<String, dynamic>;
        final lesson = LessonModel.fromJson(json);
        final videoPath = json['video_path']?.toString();
        if (videoPath == null || videoPath.isEmpty) {
          return lesson;
        }
        if (videoPath.startsWith('http')) {
          return lesson.copyWith(videoUrl: videoPath);
        }

        final normalizedPath = videoPath.startsWith('$_kLessonVideoBucket/')
            ? videoPath.substring(_kLessonVideoBucket.length + 1)
            : videoPath;

        final publicUrl = _supabase.storage
            .from(_kLessonVideoBucket)
            .getPublicUrl(normalizedPath);

        return lesson.copyWith(videoUrl: publicUrl);
      }).toList();
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
  Future<List<LessonModel>> _fetchYouTubeVideos({
    List<String> categories = const [],
  }) async {
    try {
      var query = _supabase.from('videos').select();

      if (categories.isNotEmpty) {
        query = query.inFilter('topic', categories);
      }

      final response =
          await query.order('created_at', ascending: false).limit(10);


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
