import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/lesson_item.dart';
import '../models/lesson_model.dart';
import '../models/video_model.dart';

/// Supabase Storage bucket that holds uploaded lesson videos.
/// Path format in `lessons.video_path`: `{lesson_id}/video.mp4`
const _kVideoBucket = 'lesson_videos';

class LessonRepository {
  final SupabaseClient _client;

  LessonRepository(this._client);

  // ── Storage uploads ───────────────────────────────────────────────────────

  Future<String?> uploadVideoToStorage(String filePath, String objectPath) async {
    try {
      await _client.storage.from(_kVideoBucket).upload(objectPath, File(filePath));
      return objectPath;
    } catch (e) {
      debugPrint('Video upload error: $e');
      return null;
    }
  }

  Future<String?> uploadThumbnailToStorage(String filePath, String fileName) async {
    try {
      await _client.storage.from('lesson-thumbnails').upload(fileName, File(filePath));
      return _client.storage.from('lesson-thumbnails').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Thumbnail upload error: $e');
      return null;
    }
  }

  // ── Combined feed ─────────────────────────────────────────────────────────

  /// Fetches approved lessons (Storage) AND all YouTube videos, merged and
  /// sorted newest-first. This is what the dashboard shows.
  Future<List<LessonItem>> getAllLessonItems() async {
    final results = await Future.wait([
      _fetchApprovedLessons(),
      _fetchYouTubeVideos(),
    ]);

    final items = <LessonItem>[
      ...results[0] as List<StorageLesson>,
      ...results[1] as List<YoutubeVideo>,
    ];

    items.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return items;
  }

  // ── Single-item detail ────────────────────────────────────────────────────

  /// Fetches a single Storage lesson and resolves its video_path to a
  /// signed playable URL (1-hour TTL) from the `lesson_videos` bucket.
  Future<LessonModel?> getLessonById(String lessonId) async {
    try {
      final response = await _client
          .from('lessons')
          .select()
          .eq('id', lessonId)
          .maybeSingle();

      if (response == null) return null;

      final lesson = LessonModel.fromJson(response);

      // Already a full URL — nothing to resolve.
      if (lesson.videoUrl != null && lesson.videoUrl!.startsWith('http')) {
        return lesson;
      }

      // Resolve storage path → public object URL.
      final videoPath = response['video_path']?.toString();
      if (videoPath != null && videoPath.isNotEmpty) {
        final publicUrl = _publicVideoUrl(videoPath);
        if (publicUrl != null) {
          return lesson.copyWith(videoUrl: publicUrl);
        }
      }

      return lesson;
    } catch (e) {
      debugPrint('getLessonById error: $e');
      return null;
    }
  }

  /// Fetches a single YouTube video row from `public.videos`.
  Future<VideoModel?> getVideoById(String videoId) async {
    try {
      final response = await _client
          .from('videos')
          .select()
          .eq('id', videoId)
          .maybeSingle();

      if (response == null) return null;
      return VideoModel.fromJson(response);
    } catch (e) {
      debugPrint('getVideoById error: $e');
      return null;
    }
  }

  // ── Admin lesson actions ──────────────────────────────────────────────────

  Future<void> submitLesson({
    required LessonModel lesson,
    required String videoPath,
    String? thumbnailUrl,
  }) async {
    final lessonId = lesson.id.isEmpty ? const Uuid().v4() : lesson.id;
    final payload = lesson.copyWith(
      id: lessonId,
      videoUrl: videoPath,
      thumbnailUrl: thumbnailUrl ?? lesson.thumbnailUrl,
      status: 'pending',
      isPublished: false,
      createdAt: lesson.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _client.from('lessons').upsert(payload.toJson());
  }

  Future<List<LessonModel>> getApprovedLessons() async {
    try {
      return (await _fetchApprovedLessons())
          .map((s) => s.lesson)
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

  Future<void> approveLesson({required String lessonId, required String adminId}) async {
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

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<List<StorageLesson>> _fetchApprovedLessons() async {
    final response = await _client
        .from('lessons')
        .select()
        .eq('status', 'approved')
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final row = json as Map<String, dynamic>;
      final lesson = LessonModel.fromJson(row);
      final resolvedVideoUrl = _publicVideoUrl(row['video_path']?.toString());
      return StorageLesson(
        resolvedVideoUrl == null
            ? lesson
            : lesson.copyWith(videoUrl: resolvedVideoUrl),
      );
    }).toList();
  }

  Future<List<YoutubeVideo>> _fetchYouTubeVideos() async {
    final response = await _client
        .from('videos')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => YoutubeVideo(
              VideoModel.fromJson(json as Map<String, dynamic>),
            ))
        .toList();
  }

  /// Builds the public object URL expected by the lesson player.
  /// [objectPath] may be `public/<lesson_id>/video.mp4` or just `<lesson_id>/video.mp4`.
  String? _publicVideoUrl(String? objectPath) {
    if (objectPath == null) return null;

    final cleanPath = objectPath.trim();
    if (cleanPath.isEmpty) return null;
    if (cleanPath.startsWith('http')) return cleanPath;

    final normalizedPath = cleanPath.startsWith('$_kVideoBucket/')
        ? cleanPath.substring(_kVideoBucket.length + 1)
        : cleanPath;

    return _client.storage.from(_kVideoBucket).getPublicUrl(normalizedPath);
  }
}
