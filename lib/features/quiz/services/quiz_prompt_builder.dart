import '../../learning/models/lesson_model.dart';

class QuizPromptBuilder {
  String build({
    required LessonModel lesson,
    required int questionCount,
    Map<String, dynamic>? userContext,
  }) {
    final difficulty = lesson.difficultyLevel.toLowerCase().trim();
    final age = userContext?['age'];
    final educationStatus = userContext?['education_status']?.toString() ?? '';
    final watchedHistory = (userContext?['watched_history'] as List<String>? ?? const <String>[]);

    return '''
You are generating a quiz for an educational app.

Use only the lesson context and the user's watched history below.

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

User profile:
- age: ${age ?? 'unknown'}
- education status: $educationStatus

Watched history:
${watchedHistory.isEmpty ? '- none provided' : watchedHistory.map((e) => '- $e').join('\n')}

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
