import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson_model.dart';
import '../../../core/services/context_engine_service.dart';

class LearningRepository {
  final SupabaseClient _supabase;

  static List<LessonModel> _offlineCache = [];

  LearningRepository(this._supabase);

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
        .select();

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

