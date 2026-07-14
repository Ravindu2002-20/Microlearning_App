import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ai_bot/services/gemini_service.dart';
import '../../learning/models/lesson_item.dart';
import '../../learning/models/lesson_model.dart';

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
    try {
      final userPrefs = await _fetchUserPrefs(userUuid);
      final interesting = extractInterestingFields(userPrefs);
      final selectedCategories = _extractStringList(
        userPrefs,
        const ['selected_categories', 'categories'],
      );
      final age = (userPrefs['age'] as num?)?.toInt();
      final educationStatus = userPrefs['education_status']?.toString();
      final recentWatched = await _learningRepository.fetchUserRecentLearningRecords(
        userUuid: userUuid,
        limit: 5,
      );
      final watchedTitles = recentWatched
          .map((row) => row['title']?.toString())
          .whereType<String>()
          .toList();

      final candidates = await _loadCandidates(
        candidatePool,
        userUuid: userUuid,
        selectedCategories: selectedCategories,
        interestingFields: interesting,
        age: age,
        educationStatus: educationStatus,
      );
      if (candidates.isEmpty) return const [];

      final prompt = _buildRecommendationPrompt(
        user: {
          'interesting': interesting,
          'selectedCategories': selectedCategories,
          'age': age,
          'educationStatus': educationStatus,
          'watchedTitles': watchedTitles,
          'topN': topN,
        },
        candidates: candidates,
      );

      final byId = {for (final v in candidates) v.id: v};
      final selected = <LessonModel>[];

      try {
        final aiText = await _geminiService.generateReply(
          prompt: prompt,
          history: const [],
          timeout: const Duration(seconds: 35),
        );

        final pickedIds = _parseIdsFromAi(aiText).take(topN).toSet();
        for (final id in pickedIds) {
          final v = byId[id];
          if (v == null) continue;
          selected.add(v);
        }
      } catch (e, st) {
        debugPrint('Recommendation AI failed, falling back to heuristic ranking: $e\n$st');
      }

      if (selected.length < topN) {
        final heuristic = candidates.toList()
          ..sort((a, b) => _scoreCandidate(
                b,
                interesting,
                selectedCategories,
                age,
                educationStatus,
              ).compareTo(
                _scoreCandidate(a, interesting, selectedCategories, age, educationStatus),
              ));
        for (final v in heuristic) {
          if (selected.length >= topN) break;
          if (selected.any((item) => item.id == v.id)) continue;
          selected.add(v);
        }
      }

      if (selected.isEmpty) {
        final fallback = candidates.toList()
          ..sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
              .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
        return fallback.take(topN).toList();
      }

      return selected.take(topN).toList();
    } catch (e, st) {
      debugPrint('recommendForUser error: $e\n$st');
      return _filterFallback(
        userUuid: userUuid,
        topN: topN,
        candidatePool: candidatePool,
      );
    }
  }

  Future<List<LessonModel>> _loadCandidates(
    int candidatePool, {
    required String userUuid,
    required List<String> selectedCategories,
    required List<String> interestingFields,
    int? age,
    String? educationStatus,
  }) async {
    try {
      final combined = <LessonModel>[];

      try {
        final fromRepo = await _learningRepository.getAllLessonItems();
        combined.addAll(
          fromRepo.take(candidatePool).map(lessonModelFromItem),
        );
      } catch (e, st) {
        debugPrint('Failed to load repository candidates: $e\n$st');
      }

      final lessonRows = await _supabaseClient
          .from('lessons')
          .select()
          .eq('status', 'approved')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(candidatePool * 2);

      final tokens = <String>[
        ...selectedCategories,
        ...interestingFields,
      ].map((e) => e.toLowerCase().trim()).where((e) => e.isNotEmpty).toList();

      combined.addAll(
        (lessonRows as List<dynamic>)
            .map((row) => row as Map<String, dynamic>)
            .map(_lessonModelFromSupabaseRow)
            .where((lesson) {
              if (tokens.isEmpty) return true;
              final haystack = [
                lesson.title,
                lesson.category,
                lesson.description,
              ].join(' ').toLowerCase();
              return tokens.any(haystack.contains);
            }),
      );

      combined
        ..removeWhere((v) => v.id.trim().isEmpty)
        ..sort((a, b) => _scoreCandidate(
              b,
              interestingFields,
              selectedCategories,
              age,
              educationStatus,
            ).compareTo(
              _scoreCandidate(a, interestingFields, selectedCategories, age, educationStatus),
            ));

      if (combined.isNotEmpty) {
        return combined;
      }

      return combined;
    } catch (e, st) {
      debugPrint('Failed to load direct recommendations candidates: $e\n$st');
      return const [];
    }
  }

  Future<List<LessonModel>> _filterFallback({
    required String userUuid,
    required int topN,
    required int candidatePool,
  }) async {
    try {
      final userPrefs = await _fetchUserPrefs(userUuid);
      final interesting = extractInterestingFields(userPrefs);
      final selectedCategories = _extractStringList(
        userPrefs,
        const ['selected_categories', 'categories'],
      );
      final age = (userPrefs['age'] as num?)?.toInt();
      final educationStatus = userPrefs['education_status']?.toString();
      final candidates = await _loadCandidates(
        candidatePool,
        userUuid: userUuid,
        selectedCategories: selectedCategories,
        interestingFields: interesting,
        age: age,
        educationStatus: educationStatus,
      );
      if (candidates.isEmpty) {
        return await _learningRepository.fetchAvailableLessonsPreview(limit: topN);
      }
      final sorted = candidates.toList()
        ..sort((a, b) => _scoreCandidate(
              b,
              interesting,
              selectedCategories,
              age,
              educationStatus,
            ).compareTo(
              _scoreCandidate(a, interesting, selectedCategories, age, educationStatus),
            ));
      return sorted.take(topN).toList();
    } catch (e, st) {
      debugPrint('filterFallback error: $e\n$st');
      try {
        return await _learningRepository.fetchAvailableLessonsPreview(limit: topN);
      } catch (fallbackError, fallbackStack) {
        debugPrint('Failed final recommendations fallback: $fallbackError\n$fallbackStack');
        return const [];
      }
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

  List<String> extractInterestingFields(Map<String, dynamic> prefs) {
    final candidates = <dynamic>[
      prefs['interesting_fields'],
      prefs['interests'],
      prefs['interesting'],
      prefs['preferences']?['topics'],
      prefs['preferences']?['interests'],
      prefs['preferences']?['interesting_fields'],
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
        final nested = extractInterestingFields(raw);
        for (final value in nested) {
          seen.add(value);
        }
      }
    }

    return seen.toList();
  }

  List<String> _extractStringList(
    Map<String, dynamic> prefs,
    List<String> keys,
  ) {
    final seen = <String>{};
    for (final key in keys) {
      final raw = prefs[key];
      if (raw is List) {
        for (final entry in raw) {
          final value = entry.toString().trim();
          if (value.isNotEmpty) seen.add(value);
        }
      } else if (raw is String) {
        for (final entry in raw.split(RegExp(r'[,;\n]'))) {
          final value = entry.trim();
          if (value.isNotEmpty) seen.add(value);
        }
      }
    }
    return seen.toList();
  }

  String _buildRecommendationPrompt({
    required Map<String, dynamic> user,
    required List<LessonModel> candidates,
  }) {
    final interesting = (user['interesting'] as List<String>? ?? const []).toList();
    final topN = (user['topN'] as int?) ?? 4;
    final age = user['age'];
    final educationStatus = user['educationStatus']?.toString() ?? '';
    final watchedTitles = (user['watchedTitles'] as List<String>? ?? const []).toList();

    final candidateJson = candidates.map((v) => {
          'id': v.id,
          'title': v.title,
          'topic': v.category,
          'channelTitle': null,
          'description': v.description,
        });

    return '''You are a recommender assistant for a microlearning app.
You will be given a user profile and a list of candidate lessons/videos from the lessons table.
Your task: select the TOP $topN most relevant lessons for the user.

Rules:
- Respond ONLY with JSON in this exact format: {"video_ids": ["id1","id2", ...]}
- video_ids must be chosen from the provided candidates' ids.
- Prefer lessons whose categories/titles/descriptions match the user's interesting fields.

User profile:
- interesting_fields: ${jsonEncode(interesting)}
- age: ${age ?? 'unknown'}
- education_status: $educationStatus
- watched_history: ${jsonEncode(watchedTitles)}

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

  int _scoreCandidate(
    LessonModel v,
    List<String> interesting,
    List<String> selectedCategories,
    int? age,
    String? educationStatus,
  ) {
    if (interesting.isEmpty) {
      // If no interests, rely on recency-like field.
      var score = (v.createdAt?.millisecondsSinceEpoch ?? 0).toInt();
      final categoryHay = v.category.toLowerCase();
      for (final token in selectedCategories) {
        final t = token.toLowerCase().trim();
        if (t.isEmpty) continue;
        if (categoryHay.contains(t)) score += 10;
      }
      return score;
    }

    final descriptionHay = v.description.toLowerCase();
    final titleHay = v.title.toLowerCase();
    final categoryHay = v.category.toLowerCase();
    int score = 0;

    for (final token in interesting) {
      final t = token.toLowerCase().trim();
      if (t.isEmpty) continue;
      if (descriptionHay.contains(t)) score += 12;
      if (categoryHay == t) score += 5;
      if (titleHay.contains(t)) score += 3;
    }

    for (final token in selectedCategories) {
      final t = token.toLowerCase().trim();
      if (t.isEmpty) continue;
      if (categoryHay.contains(t)) score += 8;
    }

    final role = (educationStatus ?? '').toLowerCase();
    final difficulty = v.difficultyLevel.toLowerCase();
    if (age != null) {
      if (age < 18 && difficulty.contains('beginner')) score += 6;
      if (age >= 18 && age < 23 && role.contains('undergraduate')) {
        if (difficulty.contains('medium') || difficulty.contains('beginner')) score += 8;
      }
      if (age >= 23 && role.contains('working')) {
        if (difficulty.contains('medium') || difficulty.contains('hard')) score += 8;
      }
    }
    if (role.contains('school') && difficulty.contains('beginner')) score += 5;
    if (role.contains('undergraduate') && (difficulty.contains('medium') || difficulty.contains('hard'))) score += 5;
    if (role.contains('working_professional') && difficulty.contains('hard')) score += 5;

    // Slight recency bias as a tie-breaker, without overpowering content match.
    score += ((v.createdAt?.millisecondsSinceEpoch ?? 0) ~/ 1000000000);
    return score;
  }

  // Expose for testing/extensibility.
}

