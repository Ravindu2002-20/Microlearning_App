import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../learning/models/lesson_model.dart';

class QuizResultsScreen extends StatefulWidget {
  final LessonModel lesson;
  final int score;
  final int total;
  final List<Map<String, dynamic>> answers;

  const QuizResultsScreen({
    super.key,
    required this.lesson,
    required this.score,
    required this.total,
    required this.answers,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  bool _savedAttempt = false;

  @override
  void initState() {
    super.initState();
    _insertAttemptIfPossible();
  }

  Future<void> _insertAttemptIfPossible() async {
    if (_savedAttempt) return;
    _savedAttempt = true;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('quiz_attempts').insert({
      'user_id': user.id,
      'lesson_id': widget.lesson.id,
      'lesson_title': widget.lesson.title,
      'score': widget.score,
      'total_questions': widget.total,
      'percentage': widget.total == 0 ? 0 : ((widget.score / widget.total) * 100).round(),
      'answers': widget.answers,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final text = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: text,
        title: const Text('Quiz Results'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score', style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 10),
              Text('${widget.score} / ${widget.total}', style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 40)),
              const SizedBox(height: 14),
              Text('Correct answers: ${widget.score}', style: TextStyle(color: text.withValues(alpha: 0.85), fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Total questions: ${widget.total}', style: TextStyle(color: text.withValues(alpha: 0.85), fontWeight: FontWeight.w700)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
