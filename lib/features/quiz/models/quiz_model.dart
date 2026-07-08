import 'quiz_question_model.dart';

class QuizModel {
  final String lessonId;
  final String title;
  final String description;
  final List<QuizQuestionModel> questions;

  const QuizModel({
    required this.lessonId,
    required this.title,
    required this.description,
    required this.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title']?.toString() ?? '';
    final rawDescription = json['description']?.toString() ?? '';
    final rawQuestions = json['questions'];
    final questions = <QuizQuestionModel>[];

    if (rawQuestions is List) {
      for (final item in rawQuestions) {
        if (item is Map<String, dynamic>) {
          questions.add(QuizQuestionModel.fromJson(item));
        } else if (item is Map) {
          questions.add(QuizQuestionModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return QuizModel(
      lessonId: json['lesson_id']?.toString() ?? json['lessonId']?.toString() ?? '',
      title: rawTitle,
      description: rawDescription,
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lesson_id': lessonId,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  QuizModel copyWith({
    String? lessonId,
    String? title,
    String? description,
    List<QuizQuestionModel>? questions,
  }) {
    return QuizModel(
      lessonId: lessonId ?? this.lessonId,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
    );
  }
}

