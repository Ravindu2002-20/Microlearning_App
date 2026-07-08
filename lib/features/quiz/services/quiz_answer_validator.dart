import '../models/quiz_question_model.dart';

class QuizAnswerValidator {
  bool isCorrect({
    required QuizQuestionModel question,
    required String givenAnswer,
  }) {
    if (question.questionType == 'mcq' || question.options != null) {
      return _normalize(givenAnswer) == _normalize(question.correctAnswer);
    }

    final normalizedGiven = _normalize(givenAnswer);
    if (normalizedGiven.isEmpty) return false;

    final accepted = <String>[
      question.correctAnswer,
      ...question.acceptedAnswers,
    ].map(_normalize).where((item) => item.isNotEmpty).toSet();

    return accepted.contains(normalizedGiven);
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
