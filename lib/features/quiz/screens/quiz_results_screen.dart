import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../learning/models/lesson_model.dart';
import '../../learning/repositories/xp_calculation.dart';

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

    final nowIso = DateTime.now().toIso8601String();

    await Supabase.instance.client.from('quiz_attempts').insert({
      'user_id': user.id,
      'lesson_id': widget.lesson.id,
      'lesson_title': widget.lesson.title,
      'score': widget.score,
      'total_questions': widget.total,
      'percentage': widget.total == 0 ? 0 : ((widget.score / widget.total) * 100).round(),
      'answers': widget.answers,
      'completed_at': nowIso,
    });

    // Update XP summary used by the leaderboard.
    // XP rules:
    // - video watched count (from user_progress)
    // - correct answers (from quiz_attempts score)
    // - streak bonus (based on completion dates in user_progress)
    try {
      // Compute streak based on completed lesson dates.
      final progressRows = await Supabase.instance.client
          .from('user_progress')
          .select('lesson_id,last_accessed')
          .eq('user_id', user.id)
          .eq('is_completed', true);

      final completedDates = (progressRows as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['last_accessed'])
          .whereType<dynamic>()
          .map((raw) => DateTime.tryParse(raw.toString()))
          .whereType<DateTime>()
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet()
          .toList();

      completedDates.sort((a, b) => b.compareTo(a));

      int streak = 0;
      if (completedDates.isNotEmpty) {
        final latest = completedDates.first;
        var cursor = latest;
        while (completedDates.any((d) => d.isAtSameMomentAs(cursor))) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        }
      }

      // Watched video count (completed unique lessons).
      final watchedVideoCount = (progressRows as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['lesson_id']?.toString())
          .whereType<String>()
          .toSet()
          .length;

      // Correct answers from all quiz_attempts scores for this user.
      final quizAttempts = await Supabase.instance.client
          .from('quiz_attempts')
          .select('score')
          .eq('user_id', user.id);

      final correctAnswerCount = (quizAttempts as List<dynamic>)
          .fold<int>(0, (sum, row) {
        final score = (row as Map<String, dynamic>)['score'];
        if (score == null) return sum;
        return sum + (score as num).toInt();
      });

      final totalXp = XpCalculation.calculateTotalXp(
        watchedVideoCount: watchedVideoCount,
        correctAnswerCount: correctAnswerCount,
        streak: streak,
      );

      final level = XpCalculation.calculateLevel(totalXp);

      await Supabase.instance.client.from('user_xp_summary').upsert({
        'user_id': user.id,
        'total_xp': totalXp,
        'videos_watched': watchedVideoCount,
        'correct_answers': correctAnswerCount,
        'streak': streak,
        'level': level,
        'xp_updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      // Summary update failure should not block quiz result UX.
      debugPrint('user_xp_summary upsert error: $e');
    }
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
