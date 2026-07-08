import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/learning/models/lesson_model.dart';
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
  final _textController = TextEditingController();

  bool _submitted = false;
  bool _lastCorrect = false;

  final Map<int, String> _givenAnswersByIndex = <int, String>{};
  final Map<int, bool> _correctByIndex = <int, bool>{};

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
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
        _textController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().contains("Couldn't generate")
            ? "Couldn't generate quiz. Please try again."
            : 'Quiz could not be loaded.';
      });
    }
  }

  void _onNext() {
    if (_quiz == null) return;

    final quiz = _quiz!;
    final isLast = _index >= quiz.questions.length - 1;

    if (!_submitted) {
      final answer = _computeGivenAnswer();
      final correct = _isAnswerCorrect(
        givenAnswer: answer,
        question: quiz.questions[_index],
      );

      setState(() {
        _submitted = true;
        _lastCorrect = correct;
        _givenAnswersByIndex[_index] = answer;
        _correctByIndex[_index] = correct;
      });

      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        if (isLast) {
          _goToResults();
        } else {
          _advance();
        }
      });
      return;
    }

    if (isLast) {
      _goToResults();
    } else {
      _advance();
    }
  }

  void _advance() {
    final quiz = _quiz!;
    setState(() {
      _index++;
      _submitted = false;
      _lastCorrect = false;
      _selectedOption = null;
      _textController.clear();
    });

    if (_index >= quiz.questions.length) {
      _goToResults();
    }
  }

  String _computeGivenAnswer() {
    final q = _quiz!.questions[_index];
    if (q.options != null) {
      return _selectedOption ?? '';
    }
    return _textController.text;
  }

  bool _isAnswerCorrect({
    required String givenAnswer,
    required QuizQuestionModel question,
  }) {
    return _answerValidator.isCorrect(question: question, givenAnswer: givenAnswer);
  }

  int _computeScore() {
    var score = 0;
    for (final value in _correctByIndex.values) {
      if (value) score++;
    }
    return score;
  }

  Future<void> _goToResults() async {
    if (_quiz == null) return;
    final quiz = _quiz!;
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
        'correct': _answerValidator.isCorrect(
          question: question,
          givenAnswer: given,
        ),
      });
    }
    return answers;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          foregroundColor: textPrimary,
          title: const Text('Quiz'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          foregroundColor: textPrimary,
          title: const Text('Quiz'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _error!,
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final quiz = _quiz!;
    final question = quiz.questions[_index];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: textPrimary,
        title: const Text('Quiz'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${_index + 1} of ${quiz.questions.length}',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                question.questionText,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (question.options != null) ...[
                _buildOptions(question.options!, textPrimary),
              ] else ...[
                _buildFreeText(textPrimary),
              ],
              if (_submitted) ...[
                const SizedBox(height: 16),
                Text(
                  _lastCorrect ? 'Correct' : 'Incorrect',
                  style: TextStyle(
                    color: _lastCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  question.explanation,
                  style: TextStyle(color: textPrimary.withValues(alpha: 0.85)),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit(question) ? _onNext : null,
                  child: Text(
                    _submitted
                        ? (_index >= quiz.questions.length - 1 ? 'See Results' : 'Next')
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(List<String> options, Color textPrimary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: options.asMap().entries.map((entry) {
        final opt = entry.value;
        final selected = _selectedOption == opt;
        final bg = selected
            ? const Color(0xFF5B5FEF)
            : (isDark ? Colors.white10 : Colors.grey.shade200);
        final fg = selected ? Colors.white : (isDark ? Colors.white : Colors.black);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: _submitted
                ? null
                : () {
                    setState(() {
                      _selectedOption = opt;
                    });
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                opt,
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFreeText(Color textPrimary) {
    return TextField(
      controller: _textController,
      inputFormatters: [MaxWordsTextInputFormatter(maxWords: 3)],
      enabled: !_submitted,
      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Type your answer (1-3 words)',
        hintStyle: TextStyle(color: textPrimary.withValues(alpha: 0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  bool _canSubmit(QuizQuestionModel q) {
    if (_submitted) return true;
    if (q.options != null) {
      return _selectedOption != null && _selectedOption!.trim().isNotEmpty;
    }
    return _textController.text.trim().isNotEmpty;
  }
}

class MaxWordsTextInputFormatter extends TextInputFormatter {
  final int maxWords;

  MaxWordsTextInputFormatter({required this.maxWords});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text;
    if (raw.trim().isEmpty) return newValue;

    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ');
    final parts = normalized.trim().split(' ').where((p) => p.trim().isNotEmpty).toList();

    if (parts.length <= maxWords) {
      return newValue.copyWith(text: normalized);
    }

    return oldValue;
  }
}
