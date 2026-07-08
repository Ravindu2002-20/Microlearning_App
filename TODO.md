# TODO — AI Quiz Feature

- [ ] Create quiz feature models: `QuizModel`, `QuizQuestionModel` with `fromJson()`, `toJson()`, `toInsertJson()`.
- [ ] Create `QuizRepository` with `getOrGenerateQuiz(LessonModel lesson)`:
  - [ ] Check `quiz_questions` by `lesson_id == lesson.id`
  - [ ] If found: build `QuizModel` from downloaded questions
  - [ ] If not found: call `GeminiService.generateReply()` with the exact prompt, parse/validate JSON (retry once)
  - [ ] Return `QuizModel` (and insert generated questions if repository is expected to do so via `toInsertJson()`).
- [ ] Wire Home dashboard Quiz section “Start” button:
  - [ ] Choose a lesson (simple approach: pick first from approved lessons or open a simple modal list)
  - [ ] Navigate to `QuizPlayScreen` with the selected lesson.
- [ ] Implement `QuizPlayScreen` (one question at a time):
  - [ ] Loading + progress (Question X of 5)
  - [ ] MCQ option cards (4 options)
  - [ ] Free-text questions with custom `TextInputFormatter` (max 3 words)
  - [ ] Disable Next until answer selected
  - [ ] Submit answer, show correct/incorrect styling + explanation, then auto-advance
- [ ] Implement `QuizResultsScreen` showing score, correct answers, total questions + Back to Home.
- [ ] On completion, insert one row into `quiz_attempts` with `answers` JSON payload.
- [ ] Add TODO comment about quiz XP integration depending on DB CHECK constraint extension for `content_type='quiz'`.


