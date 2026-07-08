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
      var mcqCount = 0;
      var shortAnswerCount = 0;

      for (final item in questionsRaw) {
        final map = item is Map<String, dynamic>
            ? item
            : item is Map
                ? Map<String, dynamic>.from(item)
                : null;
        if (map == null) return null;

        final question = QuizQuestionModel(
          questionText: map['question']?.toString() ?? '',
          options: _parseOptions(map['options']),
          correctAnswer: map['correct_answer']?.toString() ?? '',
          explanation: map['explanation']?.toString() ?? '',
          questionType: map['type']?.toString() ?? '',
          acceptedAnswers: _parseAcceptedAnswers(map['accepted_answers']),
        );

        if (question.questionText.trim().isEmpty || question.correctAnswer.trim().isEmpty) {
          return null;
        }

        if (question.options != null) {
          if (question.questionType != 'mcq' || question.options!.length != 4) return null;
          if (!question.options!.any((option) => option.trim() == question.correctAnswer.trim())) {
            return null;
          }
          mcqCount++;
        } else {
          if (question.questionType != 'short_answer') return null;
          if (question.acceptedAnswers.isEmpty) return null;
          shortAnswerCount++;
        }

        questions.add(question);
      }

      if (mcqCount < (questions.length * 0.7).floor()) return null;
      if (shortAnswerCount < (questions.length * 0.3).floor()) return null;

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

  List<String> _parseAcceptedAnswers(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return const [];
  }
}
