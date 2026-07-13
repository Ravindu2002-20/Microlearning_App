import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../learning/models/lesson_model.dart';
import '../../learning/repositories/xp_calculation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/floating_glow.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/widgets/main_app_shell.dart';

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

  int get _safeTotal => widget.total <= 0 ? 0 : widget.total;

  double get _percentage {
    if (_safeTotal == 0) return 0;
    return (widget.score / _safeTotal) * 100;
  }

  bool get _isPerfect => _safeTotal != 0 && widget.score == _safeTotal;

  String get _motivationalMessage {
    final p = _percentage;
    if (_safeTotal == 0) return 'Let’s get started—take another quiz!';
    if (_isPerfect) return 'Perfect score! Outstanding work ✨';
    if (p >= 80) return 'Amazing! You’re really on a roll 🚀';
    if (p >= 50) return 'Nice progress—keep improving 📈';
    return 'Good effort—review and try again 💪';
  }


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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final background = AppColors.backgroundFor(brightness);
    final textPrimary = AppColors.textPrimaryFor(brightness);
    final textSecondary = AppColors.textSecondaryFor(brightness);

    final heroGradient = isDark ? AppColors.primaryGradientDark : AppColors.primaryGradient;
    final percentageRounded = _percentage.round().clamp(0, 100);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textPrimary,
        title: Text(
          'Quiz Results',
          style: AppTypography.headlineSmall(brightness),
        ),
      ),
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: percentageRounded.toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, animatedPercent, _) {
            final animatedP = animatedPercent.clamp(0, 100);

            final successColor = isDark ? const Color(0xFF00C781) : AppColors.success;
            final badgeText = _motivationalMessage;

            return Stack(
              children: [
                Positioned(
                  top: 40,
                  left: -30,
                  child: FloatingGlow(
                    color: isDark ? const Color(0xFF7B61FF) : AppColors.primaryLight,
                    size: 220,
                    opacity: 0.35,
                  ),
                ),
                Positioned(
                  top: 120,
                  right: -40,
                  child: FloatingGlow(
                    color: isDark ? const Color(0xFF00E5FF) : AppColors.secondaryLight,
                    size: 200,
                    opacity: 0.30,
                  ),
                ),
                // Scrollable content on top, fixed "Back to Home" button pinned
                // to the bottom of the screen below it.
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 6),

                            // Gradient hero header
                            Container(
                              padding: const EdgeInsets.all(AppDimensions.spacingLg),
                              decoration: BoxDecoration(
                                gradient: heroGradient,
                                borderRadius: BorderRadius.circular(AppDimensions.cardRadiusLg),
                                boxShadow: AppDimensions.shadowLg(Colors.black.withValues(alpha: 0.12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Center(
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.lesson.title,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.headlineLarge(brightness).copyWith(
                                      color: Colors.white,
                                    ),
                                    // Show the full lesson title instead of
                                    // truncating it with an ellipsis.
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    badgeText,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodyMedium(brightness).copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Circular percentage indicator + glass score card
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Center(
                                    child: _CircularPercentage(
                                      brightness: brightness,
                                      percent: animatedP / 100,
                                      textPrimary: textPrimary,
                                      textSecondary: textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 7,
                                  child: GlassCard(
                                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                                    radius: AppDimensions.cardRadiusLg,
                                    tintColor: Colors.white,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Score',
                                          style: AppTypography.headlineSmall(brightness),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${widget.score} / ${widget.total}',
                                          style: AppTypography.displayMedium(brightness).copyWith(
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Percentage',
                                          style: AppTypography.bodySmall(brightness).copyWith(color: textSecondary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${animatedP.round()}%',
                                          style: AppTypography.displaySmall(brightness).copyWith(
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: successColor.withValues(alpha: isDark ? 0.16 : 0.12),
                                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                            border: Border.all(color: successColor.withValues(alpha: 0.35)),
                                          ),
                                          child: Text(
                                            _isPerfect ? 'Perfect run' : 'Keep going',
                                            style: TextStyle(
                                              color: successColor,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Animated statistic cards
                            _StatGrid(
                              brightness: brightness,
                              correct: widget.score,
                              wrong: _safeTotal - widget.score,
                              total: _safeTotal,
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    // Back to Home button, pinned to the bottom of the screen.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: GradientedButton(
                        label: 'Back to Home',
                        gradient: heroGradient,
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MainAppShell()),
                            (route) => false,
                          );
                        },
                        height: AppDimensions.buttonHeightLg,
                        icon: Icons.home_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CircularPercentage extends StatelessWidget {
  final Brightness brightness;
  final double percent; // 0..1
  final Color textPrimary;
  final Color textSecondary;

  const _CircularPercentage({
    required this.brightness,
    required this.percent,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSide = (constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight)
            .clamp(80.0, 170.0);

        final strokeWidth = (maxSide * 0.07).clamp(8.0, 14.0);
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: maxSide,
            height: maxSide,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: maxSide,
                  height: maxSide,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: strokeWidth,
                    backgroundColor:
                        Colors.white.withValues(alpha: isDark ? 0.10 : 0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(percent * 100).round()}%',
                      style: AppTypography.displayMedium(brightness)
                          .copyWith(color: textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Completion',
                      style: AppTypography.bodySmall(brightness)
                          .copyWith(color: textSecondary),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatGrid extends StatelessWidget {
  final Brightness brightness;
  final int correct;
  final int wrong;
  final int total;

  const _StatGrid({
    required this.brightness,
    required this.correct,
    required this.wrong,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimaryFor(brightness);
    final textSecondary = AppColors.textSecondaryFor(brightness);

    final data = [
      {
        'label': 'Correct',
        'value': correct,
        'icon': Icons.check_circle_outline,
        'color': AppColors.success,
      },
      {
        'label': 'Wrong',
        'value': wrong < 0 ? 0 : wrong,
        'icon': Icons.cancel_outlined,
        'color': AppColors.error,
      },
      {
        'label': 'Total',
        'value': total,
        'icon': Icons.quiz_outlined,
        'color': isDark ? const Color(0xFF7B61FF) : AppColors.primaryLight,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Slightly taller cells (was 1.15) so the icon + two lines of text
        // no longer overflow the card's vertical space.
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, i) {
        final d = data[i];
        final color = d['color'] as Color;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: (d['value'] as int).toDouble()),
          duration: Duration(milliseconds: 650 + i * 120),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) {
            return GlassCard(
              radius: AppDimensions.cardRadiusMd,
              tintColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: isDark ? 0.16 : 0.10),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Icon(
                      d['icon'] as IconData,
                      color: color,
                      size: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    v.round().toString(),
                    style: AppTypography.displaySmall(brightness).copyWith(color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d['label'] as String,
                    style: AppTypography.bodySmall(brightness).copyWith(color: textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}