import '../../learning/models/lesson_model.dart';

class QuizPromptBuilder {
  String build({
    required LessonModel lesson,
    required int questionCount,
  }) {
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
- ALL questions must be multiple choice (type: "mcq"). Do NOT generate short-answer or typing questions.
- Each question must have exactly 4 options and exactly one correct answer that matches one of the options exactly.
- Questions must test understanding, not memorization.
- Avoid duplicate or vague questions.
- Match the lesson difficulty level: easy, medium, or hard.
- Every question must include a short explanation (1-2 sentences) for why the answer is correct.

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
