import 'package:flutter_test/flutter_test.dart';
import 'package:microlearning_app/features/home/services/video_recommendation_service.dart';
import 'package:microlearning_app/features/learning/models/lesson_item.dart';
import 'package:microlearning_app/features/learning/models/lesson_model.dart';
import 'package:microlearning_app/features/learning/models/video_model.dart';
import 'package:microlearning_app/features/learning/repositories/learning_repository.dart';
import 'package:microlearning_app/features/ai_bot/services/gemini_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('VideoRecommendationService', () {
    test('extracts interests from nested profile and preference data', () {
      final service = VideoRecommendationService(
        supabaseClient: SupabaseClient('https://example.supabase.co', 'anon-key'),
        learningRepository: LearningRepository(
          SupabaseClient('https://example.supabase.co', 'anon-key'),
        ),
        geminiService: GeminiService(apiKey: 'test-key'),
      );

      final prefs = {
        'preferences': {
          'topics': ['AI', 'Productivity'],
        },
      };
      final profile = {
        'profile_data': {
          'interests': ['Science'],
        },
      };

      expect(service.extractInterestingFields(prefs, profile), ['AI', 'Productivity', 'Science']);
    });

    test('converts storage and youtube items into lesson models', () {
      final service = VideoRecommendationService(
        supabaseClient: SupabaseClient('https://example.supabase.co', 'anon-key'),
        learningRepository: LearningRepository(
          SupabaseClient('https://example.supabase.co', 'anon-key'),
        ),
        geminiService: GeminiService(apiKey: 'test-key'),
      );

      final storageLesson = LessonModel(
        id: 'storage-1',
        title: 'Storage lesson',
        description: 'Desc',
        content: '',
        category: 'AI',
        thumbnailUrl: 'https://cdn.example.com/storage.png',
        createdAt: DateTime(2024, 1, 1),
        difficultyLevel: 'beginner',
        format: 'video',
        minNetworkStrength: 'medium',
        safeForMotion: true,
      );

      final storageMapped = service.lessonModelFromItem(StorageLesson(storageLesson));
      expect(storageMapped.id, 'storage-1');
      expect(storageMapped.thumbnailUrl, 'https://cdn.example.com/storage.png');

      final youtubeVideo = VideoModel(
        id: 'youtube-1',
        youtubeVideoId: 'abc123',
        title: 'YouTube lesson',
        description: 'YouTube desc',
        thumbnail: 'https://cdn.example.com/youtube.png',
        topic: 'Science',
        createdAt: DateTime(2024, 2, 1),
      );

      final youtubeMapped = service.lessonModelFromItem(YoutubeVideo(youtubeVideo));
      expect(youtubeMapped.id, 'youtube-1');
      expect(youtubeMapped.videoUrl, 'yt:abc123');
      expect(youtubeMapped.thumbnailUrl, 'https://cdn.example.com/youtube.png');
      expect(youtubeMapped.category, 'Science');
    });
  });
}
