import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/glass_widgets.dart';

import '../../learning/models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import '../repositories/quiz_repository.dart';
import '../services/quiz_answer_validator.dart';
import 'quiz_results_screen.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  final LessonModel lesson;

  const QuizPlayScreen({super.key, required this.lesson});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  bool _loading = true;
  String? _error;
  QuizModel? _quiz;

  final _answerValidator = QuizAnswerValidator();

  int _index = 0;
  String? _selectedOption;

  bool _submitted = false;
  bool _lastCorrect = false;

  final Map<int, String> _givenAnswersByIndex = <int, String>{};
  final Map<int, bool> _correctByIndex = <int, bool>{};

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = QuizRepository();
      final quiz = await repo.generateQuizFromLesson(widget.lesson);
      if (!mounted) return;

      setState(() {
        _quiz = quiz;
        _loading = false;
        _index = 0;
        _submitted = false;
        _selectedOption = null;
        _givenAnswersByIndex.clear();
        _correctByIndex.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Couldn't generate quiz. Please try again.";
      });
    }
  }

  void _onSubmit() {
    final quiz = _quiz;
    if (quiz == null) return;
    if (_selectedOption == null) return;

    final question = quiz.questions[_index];
    final correct = _answerValidator.isCorrect(
      question: question,
      givenAnswer: _selectedOption!,
    );

    setState(() {
      _submitted = true;
      _lastCorrect = correct;
      _givenAnswersByIndex[_index] = _selectedOption!;
      _correctByIndex[_index] = correct;
    });
  }

  void _onNext() {
    final quiz = _quiz;
    if (quiz == null) return;

    final isLast = _index >= quiz.questions.length - 1;
    if (isLast) {
      _goToResults();
      return;
    }

    setState(() {
      _index++;
      _submitted = false;
      _lastCorrect = false;
      _selectedOption = null;
    });
  }

  int _computeScore() {
    var score = 0;
    for (final value in _correctByIndex.values) {
      if (value) score++;
    }
    return score;
  }

  Future<void> _goToResults() async {
    final quiz = _quiz;
    if (quiz == null) return;

    final score = _computeScore();

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultsScreen(
          score: score,
          total: quiz.questions.length,
          lesson: widget.lesson,
          answers: _buildAttemptAnswers(quiz),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildAttemptAnswers(QuizModel quiz) {
    final answers = <Map<String, dynamic>>[];
    for (var i = 0; i < quiz.questions.length; i++) {
      final question = quiz.questions[i];
      final given = _givenAnswersByIndex[i] ?? '';
      answers.add({
        'question': question.questionText,
        'given_answer': given,
        'correct_answer': question.correctAnswer,
        'correct': _answerValidator.isCorrect(question: question, givenAnswer: given),
      });
    }
    return answers;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = AppColors.backgroundFor(brightness);
    final textPrimary = AppColors.textPrimaryFor(brightness);
    final textSecondary = AppColors.textSecondaryFor(brightness);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(bg, textPrimary),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryFor(brightness)),
              const SizedBox(height: AppDimensions.spacingLg),
              Text(
                'Generating your quiz...',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(bg, textPrimary),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: AppDimensions.spacingLg),
                Text(
                  _error!,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingXxl),
                GradientedButton(
                  label: 'Try Again',
                  gradient: AppColors.primaryGradient,
                  onTap: _loadQuiz,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final quiz = _quiz!;
    final question = quiz.questions[_index];
    final options = question.options;

    // MCQ-only contract: options must exist and have 4 items.
    if (options == null || options.length != 4) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(bg, textPrimary),
        body: Center(
          child: Text(
            'Quiz data is invalid (expected MCQ).',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final progress = (_index + 1) / quiz.questions.length;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(bg, textPrimary),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceFor(brightness),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryFor(brightness),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Text(
                    '${_index + 1}/${quiz.questions.length}',
                    style: TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXxl),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.spacingXl),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceFor(brightness),
                          borderRadius: BorderRadius.circular(AppDimensions.cardRadiusLg),
                          boxShadow: AppDimensions.shadowSm(Colors.black),
                        ),
                        child: Text(
                          question.questionText,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),

                      ...List.generate(options.length, (i) {
                        final opt = options[i];
                        final isCorrectAnswer = opt.trim() == question.correctAnswer.trim();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                          child: _QuizOptionTile(
                            label: opt,
                            index: i,
                            isSelected: _selectedOption == opt,
                            submitted: _submitted,
                            isCorrectAnswer: isCorrectAnswer,
                            brightness: brightness,
                            onTap: _submitted
                                ? null
                                : () => setState(() => _selectedOption = opt),
                          ),
                        );
                      }),

                      if (_submitted) ...[
                        const SizedBox(height: AppDimensions.spacingSm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppDimensions.spacingLg),
                          decoration: BoxDecoration(
                            color: (_lastCorrect ? AppColors.success : AppColors.error)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
                            border: Border.all(
                              color: (_lastCorrect ? AppColors.success : AppColors.error)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _lastCorrect
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: _lastCorrect ? AppColors.success : AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppDimensions.spacingSm),
                                  Text(
                                    _lastCorrect ? 'Correct!' : 'Incorrect',
                                    style: TextStyle(
                                      color: _lastCorrect ? AppColors.success : AppColors.error,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              if (!_lastCorrect) ...[
                                const SizedBox(height: AppDimensions.spacingSm),
                                Text(
                                  'Correct answer: ${question.correctAnswer}',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppDimensions.spacingSm),
                              Text(
                                question.explanation,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              GradientedButton(
                label: !_submitted
                    ? 'Submit Answer'
                    : (_index >= quiz.questions.length - 1 ? 'See Results' : 'Next Question'),
                gradient: AppColors.primaryGradient,
                onTap: !_submitted
                    ? (_selectedOption == null ? () {} : _onSubmit)
                    : _onNext,
                isLoading: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color bg, Color textPrimary) {
    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      foregroundColor: textPrimary,
      title: Text(
        widget.lesson.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
      ),
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  final String label;
  final int index;
  final bool isSelected;
  final bool submitted;
  final bool isCorrectAnswer;
  final Brightness brightness;
  final VoidCallback? onTap;

  const _QuizOptionTile({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.submitted,
    required this.isCorrectAnswer,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const letters = ['A', 'B', 'C', 'D'];

    var bgColor = AppColors.surfaceFor(brightness);
    var borderColor = Colors.transparent;
    var badgeColor = AppColors.textSecondaryFor(brightness).withValues(alpha: 0.15);
    var badgeTextColor = AppColors.textSecondaryFor(brightness);

    var textColor = AppColors.textPrimaryFor(brightness);

    IconData? trailingIcon;
    var trailingColor = Colors.transparent;

    if (submitted) {
      if (isCorrectAnswer) {
        bgColor = AppColors.success.withValues(alpha: 0.14);
        borderColor = AppColors.success;
        badgeColor = AppColors.success;
        badgeTextColor = Colors.white;
        trailingIcon = Icons.check_circle_rounded;
        trailingColor = AppColors.success;
      } else if (isSelected) {
        bgColor = AppColors.error.withValues(alpha: 0.14);
        borderColor = AppColors.error;
        badgeColor = AppColors.error;
        badgeTextColor = Colors.white;
        trailingIcon = Icons.cancel_rounded;
        trailingColor = AppColors.error;
      }
    } else if (isSelected) {
      bgColor = AppColors.primaryFor(brightness).withValues(alpha: 0.14);
      borderColor = AppColors.primaryFor(brightness);
      badgeColor = AppColors.primaryFor(brightness);
      badgeTextColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingLg,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, color: badgeColor),
              child: Center(
                child: Text(
                  letters[index.clamp(0, 3)],
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: trailingColor, size: 22),
          ],
        ),
      ),
    );
  }
}

