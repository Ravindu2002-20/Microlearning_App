import '../../learning/models/lesson_model.dart';

class QuizPromptBuilder {
  String build({
    required LessonModel lesson,
    required int questionCount,
  }) {
    final shortAnswerCount = (questionCount * 0.3).round().clamp(2, questionCount);
    final mcqCount = questionCount - shortAnswerCount;
    final difficulty = lesson.difficultyLevel.toLowerCase().trim();

    return '''
You are generating a quiz for an educational app.

Use only the lesson context below.

Lesson title:
${lesson.title}

Lesson description:
${lesson.description}

Lesson category:
${lesson.category}

Lesson difficulty:
$difficulty

Lesson content:
${lesson.content}

Generate a quiz that follows these rules:
- Return STRICT JSON only.
- No markdown.
- No extra text.
- Exactly $questionCount questions.
- About 70% MCQ and 30% short answer.
- Target $mcqCount MCQ questions and $shortAnswerCount short answer questions.
- Questions must test understanding, not memorization.
- Avoid duplicate or vague questions.
- Match the lesson difficulty level: easy, medium, or hard.
- For short answers, include accepted_answers with multiple acceptable variants.
- For MCQs, provide exactly 4 options and one correct answer.
- Every question must include an explanation.

JSON schema:
{
  "title": "...",
  "description": "...",
  "questions": [
    {
      "question": "...",
      "type": "mcq",
      "options": ["...", "...", "...", "..."],
      "correct_answer": "...",
      "explanation": "..."
    },
    {
      "question": "...",
      "type": "short_answer",
      "correct_answer": "...",
      "accepted_answers": ["...", "..."],
      "explanation": "..."
    }
  ]
}

Difficulty guidance:
- easy: direct concept checks and simple application.
- medium: multi-step understanding and comparisons.
- hard: deeper reasoning and transfer of knowledge.
''';
  }
}
