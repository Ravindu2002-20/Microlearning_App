import 'dart:convert';

import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';

class QuizJsonParser {
  QuizModel? parse(String rawText, {required String lessonId}) {
    try {
      final cleaned = _cleanRawText(rawText);
      final decoded = jsonDecode(cleaned);
      if (decoded is! Map<String, dynamic>) return null;

      final questionsRaw = decoded['questions'];
      if (questionsRaw is! List || questionsRaw.length < 8 || questionsRaw.length > 10) {
        return null;
      }

      final questions = <QuizQuestionModel>[];

      for (final item in questionsRaw) {
        final map = item is Map<String, dynamic>
            ? item
            : item is Map
                ? Map<String, dynamic>.from(item)
                : null;
        if (map == null) return null;

        final questionType = map['type']?.toString().toLowerCase().trim();
        if (questionType != 'mcq') return null;

        final options = _parseOptions(map['options']);
        final correctAnswer = map['correct_answer']?.toString() ?? '';
        final explanation = map['explanation']?.toString() ?? '';
        final questionText = map['question']?.toString() ?? '';

        if (questionText.trim().isEmpty) return null;
        if (correctAnswer.trim().isEmpty) return null;
        if (explanation.trim().isEmpty) return null;
        if (options == null || options.length != 4) return null;

        final correctNormalized = correctAnswer.trim();
        final matchesOption = options.any((option) => option.trim() == correctNormalized);
        if (!matchesOption) return null;

        questions.add(
          QuizQuestionModel(
            questionText: questionText,
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanation,
            questionType: 'mcq',
            acceptedAnswers: const [],
          ),
        );
      }

      return QuizModel(
        lessonId: lessonId,
        title: decoded['title']?.toString() ?? '',
        description: decoded['description']?.toString() ?? '',
        questions: questions,
      );
    } catch (_) {
      return null;
    }
  }

  String _cleanRawText(String rawText) {
    return rawText
        .trim()
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .replaceAll(RegExp(r'```\s*$', multiLine: true), '');
  }

  List<String>? _parseOptions(dynamic raw) {
    if (raw is! List) return null;
    final options = raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    return options.isEmpty ? null : options;
  }


}
