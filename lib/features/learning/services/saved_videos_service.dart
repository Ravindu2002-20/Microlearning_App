import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson_model.dart';

class SavedVideosService {
  static const _prefix = 'saved_videos_';

  String _key(String userId) => '$_prefix$userId';

  Future<List<LessonModel>> getSavedVideos(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? const <String>[];
    return raw
        .map((item) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            return LessonModel.fromJson(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<LessonModel>()
        .toList();
  }

  Future<void> saveVideo(String userId, LessonModel lesson) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key(userId)) ?? <String>[];
    final filtered = current.where((item) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['id']?.toString() != lesson.id;
      } catch (_) {
        return true;
      }
    }).toList();

    final payload = jsonEncode({
      'id': lesson.id,
      'title': lesson.title,
      'description': lesson.description,
      'content': lesson.content,
      'category': lesson.category,
      'video_url': lesson.videoUrl,
      'thumbnail_url': lesson.thumbnailUrl,
      'created_at': (lesson.createdAt ?? DateTime.now()).toIso8601String(),
      'format': lesson.format,
      'difficulty_level': lesson.difficultyLevel,
      'min_network_strength': lesson.minNetworkStrength,
      'safe_for_motion': lesson.safeForMotion,
      'status': lesson.status,
      'uploaded_by': lesson.uploadedBy,
      'is_published': lesson.isPublished,
    });

    filtered.insert(0, payload);
    await prefs.setStringList(_key(userId), filtered);
  }

  Future<void> removeVideo(String userId, String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key(userId)) ?? <String>[];
    final filtered = current.where((item) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['id']?.toString() != lessonId;
      } catch (_) {
        return false;
      }
    }).toList();
    await prefs.setStringList(_key(userId), filtered);
  }

  Future<bool> isSaved(String userId, String lessonId) async {
    final saved = await getSavedVideos(userId);
    return saved.any((lesson) => lesson.id == lessonId);
  }
}

final savedVideosRefreshProvider = StateProvider<int>((ref) => 0);
