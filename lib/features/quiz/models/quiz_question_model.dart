class QuizQuestionModel {
  final String questionText;
  final List<String>? options;
  final String correctAnswer;
  final String explanation;
  final String questionType; // 'mcq' | 'short_answer'
  final List<String> acceptedAnswers;

  const QuizQuestionModel({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.questionType,
    required this.acceptedAnswers,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];

    List<String>? options;
    if (rawOptions == null) {
      options = null;
    } else if (rawOptions is List) {
      options = rawOptions.map((e) => e.toString()).toList();
    } else {
      // Some schemas might store options as JSON string.
      final s = rawOptions.toString();
      if (s.trim().isEmpty) {
        options = null;
      } else {
        options = [s];
      }
    }

    final qType = json['question_type']?.toString() ??
        (options != null && options.isNotEmpty ? 'mcq' : 'short_answer');

    return QuizQuestionModel(
      questionText: json['question_text']?.toString() ??
          json['questionText']?.toString() ??
          '',
      options: options,
      correctAnswer: json['correct_answer']?.toString() ??
          json['correctAnswer']?.toString() ??
          '',
      explanation: json['explanation']?.toString() ?? '',
      questionType: qType,
      acceptedAnswers: _parseAcceptedAnswers(json['accepted_answers'] ?? json['acceptedAnswers']),
    );
  }

  static List<String> _parseAcceptedAnswers(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return [raw.trim()];
    }
    return const [];
  }

  Map<String, dynamic> toJson() {
    return {
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'question_type': questionType,
      'accepted_answers': acceptedAnswers,
    };
  }
}

