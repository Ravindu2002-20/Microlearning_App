import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/ai_bot/services/gemini_service.dart';
import '../../learning/models/lesson_model.dart';
import '../../learning/repositories/learning_repository.dart';
import '../models/quiz_model.dart';
import '../services/quiz_json_parser.dart';
import '../services/quiz_prompt_builder.dart';

class QuizRepository {
  final GeminiService _gemini;
  final QuizPromptBuilder _promptBuilder;
  final QuizJsonParser _parser;
  final LearningRepository _learningRepository;

  QuizRepository({
    GeminiService? geminiService,
    QuizPromptBuilder? promptBuilder,
    QuizJsonParser? parser,
  })  : _gemini = geminiService ?? GeminiService(),
        _promptBuilder = promptBuilder ?? QuizPromptBuilder(),
        _parser = parser ?? QuizJsonParser(),
        _learningRepository = LearningRepository(Supabase.instance.client);

  Future<QuizModel> generateQuizFromLesson(LessonModel lesson) async {
    if (lesson.id.isEmpty) {
      throw ArgumentError('lesson.id is empty');
    }

    final quiz = await _generateValidatedQuiz(lesson);
    if (quiz == null) {
      throw StateError(
        "Couldn't generate quiz. Please try again.",
      );
    }

    return quiz;
  }

  Future<QuizModel?> _generateValidatedQuiz(LessonModel lesson) async {
    final user = Supabase.instance.client.auth.currentUser;
    final userContext = user == null
        ? <String, dynamic>{}
        : await _learningRepository.fetchUserLearningContext(userUuid: user.id);
    final watchedHistory = user == null
        ? const <String>[]
        : await _learningRepository.fetchUserWatchedLessonTitles(userUuid: user.id);

    final prompt = _promptBuilder.build(
      lesson: lesson,
      questionCount: 10,
      userContext: {
        ...userContext,
        'watched_history': watchedHistory,
      },
    );

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final rawText = await _gemini.generateReply(
          prompt: prompt,
          history: const [],
        );
        final parsed = _parser.parse(rawText, lessonId: lesson.id);
        if (parsed != null) return parsed;
      } catch (e) {
        debugPrint('Quiz generation attempt ${attempt + 1} failed: $e');
      }
    }

    return null;
  }
}
