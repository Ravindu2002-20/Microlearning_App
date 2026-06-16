import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/lesson_model.dart';

class LessonRepository {
  final SupabaseClient _client;

  LessonRepository(this._client);

  Future<String> uploadVideo({
    required String lessonId,
    required File videoFile,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final path = 'public/${user.id}/video.mp4';


      debugPrint('[uploadVideo] currentUser=${user?.id ?? 'null'}');

      debugPrint('[uploadVideo] bucket=lesson_videos');
      debugPrint('[uploadVideo] path=$path');
      debugPrint('[uploadVideo] fileLengthBytes=${await videoFile.length()}');

      await _client.storage.from('lesson_videos').upload(
        path,
        videoFile,
        fileOptions: const FileOptions(upsert: true),
      );
      return path;
    } catch (e, st) {
      debugPrint('uploadVideo error: $e');
      debugPrint('uploadVideo stackTrace: $st');
      rethrow;
    }
  }


  Future<void> submitLesson({
    required LessonModel lesson,
    required File videoFile,
  }) async {
    final lessonId = lesson.id.isEmpty ? const Uuid().v4() : lesson.id;
    final videoPath = await uploadVideo(
      lessonId: lessonId,
      videoFile: videoFile,
    );

    final payload = lesson.copyWith(
      id: lessonId,
      videoPath: videoPath,
      status: 'pending',
      isPublished: false,
      createdAt: lesson.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _client.from('lessons').upsert(payload.toJson());
  }

  Future<List<LessonModel>> getApprovedLessons() async {
    try {
      final response = await _client
          .from('lessons')
          .select()
          .eq('status', 'approved')
          .eq('is_published', true)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => LessonModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getApprovedLessons error: $e');
      return [];
    }
  }

  Future<List<LessonModel>> getPendingLessons() async {
    try {
      final response = await _client
          .from('lessons')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => LessonModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getPendingLessons error: $e');
      return [];
    }
  }

  Future<void> approveLesson({
    required String lessonId,
    required String adminId,
  }) async {
    await _client.from('lessons').update({
      'status': 'approved',
      'is_published': true,
      'approved_by': adminId,
      'approved_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', lessonId);
  }

  Future<void> rejectLesson({
    required String lessonId,
    required String adminId,
    required String notes,
  }) async {
    await _client.from('lessons').update({
      'status': 'rejected',
      'is_published': false,
      'admin_notes': notes,
      'approved_by': adminId,
      'approved_at': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', lessonId);
  }

  Future<String> getVideoUrl(String storagePath) async {
    if (storagePath.isEmpty) {
      throw Exception('Missing video path');
    }
    return _client.storage.from('lesson_videos').getPublicUrl(storagePath);
  }

  Future<LessonModel?> getLessonById(String lessonId) async {
    try {
      final response = await _client
          .from('lessons')
          .select()
          .eq('id', lessonId)
          .maybeSingle();
      if (response == null) return null;
      return LessonModel.fromJson(response);
    } catch (e) {
      debugPrint('getLessonById error: $e');
      return null;
    }
  }
}
