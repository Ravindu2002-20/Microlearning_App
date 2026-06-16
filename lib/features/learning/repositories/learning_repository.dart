import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson_model.dart';
import '../../../core/services/context_engine_service.dart';

class LearningRepository {
  final SupabaseClient _supabase;

  static List<LessonModel> _offlineCache = [];

  LearningRepository(this._supabase);

  // Upload a new lesson - saves as pending
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

  // Fetch lessons uploaded by the current user (all statuses)
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

  // Admin only - fetch all pending lessons
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

  // Admin only - approve a lesson
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

  // Admin only - reject a lesson with a reason
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

  // Check if current user is admin
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
        _offlineCache = results;
      }

      return results;
    } catch (e, st) {
      debugPrint('fetchAdaptiveViewportFeed error: $e\n$st');

      if (_offlineCache.isNotEmpty) {
        return _offlineCache.where((l) {
          if (ambientContext.isInMotion && !l.safeForMotion) return false;
          if (ambientContext.networkStrength == AppNetworkStrength.weak && l.format == 'video') {
            return false;
          }
          return true;
        }).toList();
      }

      return [];
    }
  }

  Future<List<LessonModel>> _fetchFromSupabase({
    required String userUuid,
    required UserContextState ambientContext,
  }) async {
    // 1) Gather completed lesson ids
    final completedRows = await _supabase
        .from('user_progress')
        .select('lesson_id')
        .eq('user_id', userUuid);

    final List<int> completedLessonIds = (completedRows as List<dynamic>?)
            ?.map((row) {
              final v = (row as Map<String, dynamic>)['lesson_id'];
              if (v is int) return v;
              if (v is num) return v.toInt();
              if (v is String) return int.tryParse(v) ?? -1;
              return -1;
            })
            .where((id) => id >= 0)
            .toList() ??
        [];

    // 2) Build the lessons query
    PostgrestFilterBuilder<PostgrestList> query = _supabase
        .from('lessons')
        .select()
        .eq('status', 'approved');

    if (completedLessonIds.isNotEmpty) {
      query = query.not('id', 'in', completedLessonIds);
    }

    if (ambientContext.isInMotion) {
      query = query.eq('safe_for_motion', true);
    }

    switch (ambientContext.networkStrength) {
      case AppNetworkStrength.weak:
        query = query.eq('min_network_strength', 'weak').neq('format', 'video');
        break;
      case AppNetworkStrength.medium:
        query = query.inFilter('min_network_strength', ['weak', 'medium']);
        break;
      case AppNetworkStrength.strong:
        // No restriction
        break;
    }

    final response = await query
        .order('id', ascending: true)
        .limit(10);

    final data = response as List<dynamic>;
    return data
        .map((row) => LessonModel.fromJson(row as Map<String, dynamic>))
        .toList();

  }

  Future<void> logLessonCompletion({
    required String userUuid,
    required int lessonId,
    required int score,
  }) async {
    try {
      final nowIso = DateTime.now().toIso8601String();

      await _supabase.from('user_progress').upsert({
        'user_id': userUuid,
        'lesson_id': lessonId,
        'score': score,
        'completed_at': nowIso,
      });
    } catch (e, st) {
      debugPrint('logLessonCompletion error: $e\n$st');
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile({
    required String userUuid,
  }) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userUuid);

      if (response.isEmpty) return null;
      return response.first;
    } catch (e, st) {
      debugPrint('fetchUserProfile error: $e\n$st');
      return null;
    }
  }
}

