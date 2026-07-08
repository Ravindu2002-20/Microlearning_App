import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ai_bot/services/gemini_service.dart';
import '../../learning/models/lesson_item.dart';
import '../../learning/models/lesson_model.dart';
import '../../learning/models/video_model.dart';

import '../../learning/repositories/learning_repository.dart';

/// Minimal shape we return to the Home UI.
class RecommendedVideo {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final Color? fallbackColor;

  const RecommendedVideo({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.fallbackColor,
  });
}

final videoRecommendationServiceProvider = Provider<VideoRecommendationService>((ref) {
  final supabase = Supabase.instance.client;
  final learningRepo = LearningRepository(supabase);
  final gemini = GeminiService();
  return VideoRecommendationService(
    supabaseClient: supabase,
    learningRepository: learningRepo,
    geminiService: gemini,
  );
});

class VideoRecommendationService {
  VideoRecommendationService({
    required SupabaseClient supabaseClient,
    required LearningRepository learningRepository,
    required GeminiService geminiService,
  })  : _supabaseClient = supabaseClient,
        _learningRepository = learningRepository,
        _geminiService = geminiService;

  final SupabaseClient _supabaseClient;
  final LearningRepository _learningRepository;
  final GeminiService _geminiService;

  /// Uses the existing Gemini model to rank videos from the existing lesson feed.
  /// Returns up to [topN] lessons/videos.
  Future<List<LessonModel>> recommendForUser({
    required String userUuid,
    int topN = 4,
    int candidatePool = 25,
  }) async {
    // 1) Load user details (age + interesting fields).
    final userPrefs = await _fetchUserPrefs(userUuid);
    final userProfile = await _fetchUserProfile(userUuid);

    final age = (userProfile['age'] ?? userProfile['birth_year'] ?? userPrefs['age'])?.toString();
    final interesting = extractInterestingFields(userPrefs, userProfile);

    // 2) Load candidate videos from the existing lesson feed.
    final candidates = await _loadCandidates(candidatePool);

    if (candidates.isEmpty) return const [];

    // 3) Try Gemini first, but never let that block the home feed.
    final prompt = _buildRecommendationPrompt(
      user: {
        'age': age,
        'interesting': interesting,
        'topN': topN,
      },
      candidates: candidates,
    );

    final byId = {for (final v in candidates) v.id: v};
    final selected = <LessonModel>[];

    try {
      // Keep history empty for deterministic behavior.
      final aiText = await _geminiService.generateReply(
        prompt: prompt,
        history: const [],
        timeout: const Duration(seconds: 35),
      );

      final pickedIds = _parseIdsFromAi(aiText).take(topN).toSet();

      // First, use AI picks.
      for (final id in pickedIds) {
        final v = byId[id];
        if (v == null) continue;
        selected.add(v);
      }
    } catch (e, st) {
      debugPrint('Recommendation AI failed, falling back to heuristic ranking: $e\n$st');
    }

    // Fallback: if AI returned nothing/invalid, use heuristic ranking.
    if (selected.length < topN) {
      final heuristic = candidates.toList()
        ..sort((a, b) => _scoreCandidate(b, interesting).compareTo(_scoreCandidate(a, interesting)));
      for (final v in heuristic) {
        if (selected.length >= topN) break;
        if (selected.any((item) => item.id == v.id)) continue;
        selected.add(v);
      }
    }

    if (selected.isEmpty) {
      final fallback = candidates.toList()
        ..sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
      return fallback.take(topN).toList();
    }

    // Limit.
    return selected.take(topN).toList();
  }

  Future<List<LessonModel>> _loadCandidates(int candidatePool) async {
    try {
      final fromRepo = (await _learningRepository.getAllLessonItems())
          .take(candidatePool)
          .toList();

      if (fromRepo.isNotEmpty) {
        return fromRepo.map(lessonModelFromItem).toList();
      }

      final lessonRows = await _supabaseClient
          .from('lessons')
          .select()
          .eq('status', 'approved')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(candidatePool);

      final lessonCandidates = (lessonRows as List<dynamic>)
          .map((row) => row as Map<String, dynamic>)
          .map(_lessonModelFromSupabaseRow)
          .toList();

      final videoRows = await _supabaseClient
          .from('videos')
          .select()
          .order('created_at', ascending: false)
          .limit(candidatePool);

      final videoCandidates = (videoRows as List<dynamic>)
          .map((row) => row as Map<String, dynamic>)
          .map(_lessonModelFromVideoRow)
          .toList();

      final combined = [...lessonCandidates, ...videoCandidates];
      combined.shuffle();
      return combined;
    } catch (e, st) {
      debugPrint('Failed to load direct recommendations candidates: $e\n$st');
      return const [];
    }
  }

  LessonModel lessonModelFromItem(LessonItem item) {
    switch (item) {
      case StorageLesson(:final lesson):
        return lesson;
      case YoutubeVideo(:final video):
        return LessonModel(
          id: video.id,
          title: video.title,
          description: video.description ?? '',
          content: '',
          category: video.topic ?? video.channelTitle ?? 'YouTube',
          videoUrl: 'yt:${video.youtubeVideoId}',
          thumbnailUrl: video.thumbnail,
          durationSeconds: video.durationSeconds,
          difficultyLevel: 'beginner',
          format: 'video',
          minNetworkStrength: 'medium',
          safeForMotion: false,
          status: 'approved',
          isPublished: true,
          createdAt: video.createdAt,
        );
    }
  }

  LessonModel _lessonModelFromSupabaseRow(Map<String, dynamic> row) {
    final lesson = LessonModel.fromJson(row);
    final videoPath = row['video_path']?.toString();
    if (videoPath == null || videoPath.isEmpty) return lesson;
    if (videoPath.startsWith('http')) {
      return lesson.copyWith(videoUrl: videoPath);
    }

    final normalizedPath = videoPath.startsWith('lesson_videos/')
        ? videoPath.substring('lesson_videos/'.length)
        : videoPath;

    final publicUrl = _supabaseClient.storage.from('lesson_videos').getPublicUrl(normalizedPath);
    return lesson.copyWith(videoUrl: publicUrl);
  }

  LessonModel _lessonModelFromVideoRow(Map<String, dynamic> row) {
    final video = VideoModel.fromJson(row);
    return LessonModel(
      id: video.id,
      title: video.title,
      description: video.description ?? '',
      content: '',
      category: video.topic ?? video.channelTitle ?? 'YouTube',
      videoUrl: 'yt:${video.youtubeVideoId}',
      thumbnailUrl: video.thumbnail,
      durationSeconds: video.durationSeconds,
      difficultyLevel: 'beginner',
      format: 'video',
      minNetworkStrength: 'medium',
      safeForMotion: false,
      status: 'approved',
      isPublished: true,
      createdAt: video.createdAt,
    );
  }

  Future<Map<String, dynamic>> _fetchUserProfile(String userUuid) async {
    try {
      final res = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userUuid)
          .maybeSingle();
      return res is Map<String, dynamic> ? res : <String, dynamic>{};
    } catch (e, st) {
      debugPrint('fetchUserProfile error: $e\n$st');
      return <String, dynamic>{};
    }
  }

  Future<Map<String, dynamic>> _fetchUserPrefs(String userUuid) async {
    try {
      final res = await _supabaseClient
          .from('user_preferences')
          .select()
          .eq('user_id', userUuid)
          .maybeSingle();
      return res is Map<String, dynamic> ? res : <String, dynamic>{};
    } catch (e, st) {
      debugPrint('fetchUserPrefs error: $e\n$st');
      return <String, dynamic>{};
    }
  }

  List<String> extractInterestingFields(Map<String, dynamic> prefs, Map<String, dynamic> profile) {
    final candidates = <dynamic>[
      prefs['interesting_fields'],
      prefs['interests'],
      prefs['interesting'],
      prefs['preferences']?['topics'],
      prefs['preferences']?['interests'],
      prefs['preferences']?['interesting_fields'],
      profile['interesting_fields'],
      profile['interests'],
      profile['interesting'],
      profile['profile_data']?['topics'],
      profile['profile_data']?['interests'],
      profile['profile_data']?['interesting_fields'],
    ];

    final seen = <String>{};
    for (final raw in candidates) {
      if (raw is List) {
        for (final entry in raw) {
          final value = entry.toString().trim();
          if (value.isEmpty) continue;
          seen.add(value);
        }
      } else if (raw is String) {
        final list = raw
            .split(RegExp(r'[,;\n]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        for (final value in list) {
          seen.add(value);
        }
      } else if (raw is Map<String, dynamic>) {
        final nested = extractInterestingFields(raw, const <String, dynamic>{});
        for (final value in nested) {
          seen.add(value);
        }
      }
    }

    return seen.toList();
  }

  String _buildRecommendationPrompt({
    required Map<String, dynamic> user,
    required List<LessonModel> candidates,
  }) {
    final age = user['age']?.toString() ?? '';
    final interesting = (user['interesting'] as List<String>? ?? const []).toList();
    final topN = (user['topN'] as int?) ?? 4;

    final candidateJson = candidates.map((v) => {
          'id': v.id,
          'title': v.title,
          'topic': v.category,
          'channelTitle': null,
          'description': v.description,
        });

    return '''You are a recommender assistant for a microlearning app.
You will be given a user profile and a list of candidate YouTube videos.
Your task: select the TOP $topN most relevant videos for the user.

Rules:
- Respond ONLY with JSON in this exact format: {"video_ids": ["id1","id2", ...]}
- video_ids must be chosen from the provided candidates' ids.
- Prefer videos whose topics/titles/descriptions match the user's interesting fields.

User profile:
- age: ${age.isEmpty ? '(unknown)' : age}
- interesting_fields: ${jsonEncode(interesting)}

Candidates (JSON array):
${jsonEncode(candidateJson)}
''';
  }

  Iterable<String> _parseIdsFromAi(String aiText) {
    // Try JSON first.
    try {
      final decoded = jsonDecode(aiText);
      final ids = decoded['video_ids'];
      if (ids is List) {
        return ids.map((e) => e.toString());
      }
    } catch (_) {
      // ignore
    }

    // Fallback: extract ids from any text-looking list.
    final regex = RegExp(r'"?([a-zA-Z0-9_-]{3,})"?');
    return regex.allMatches(aiText).map((m) => m.group(1) ?? '').where((s) => s.isNotEmpty);
  }

  int _scoreCandidate(LessonModel v, List<String> interesting) {
    if (interesting.isEmpty) {
      // If no interests, rely on recency-like field.
      return (v.createdAt?.millisecondsSinceEpoch ?? 0).toInt();
    }

    final hay = '${v.title} ${v.category} ${v.description}'.toLowerCase();
    int score = 0;

    for (final token in interesting) {
      final t = token.toLowerCase().trim();
      if (t.isEmpty) continue;
      if (hay.contains(t)) score += 10;
      if (v.category.toLowerCase() == t) score += 8;
      if (v.title.toLowerCase().contains(t)) score += 6;
    }
    return score;
  }

  // Expose for testing/extensibility.
}

