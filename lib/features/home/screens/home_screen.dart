import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — Main dashboard for the micro‑learning app
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header ───────────────────────────────────────────────
              _HomeHeader(isDark: isDark),
              const SizedBox(height: AppDimensions.spacingXxl),

              // ── Section 1: Continue Learning ────────────────────────────
              _SectionHeader(
                title: 'Continue Learning',
                actionLabel: 'See all',
                isDark: isDark,
                onAction: () {},
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _ContinueLearningCarousel(isDark: isDark),
              const SizedBox(height: AppDimensions.spacingXxxl),

              // ── Section 2: Recommended For You ──────────────────────────
              _SectionHeader(
                title: 'Recommended For You',
                actionLabel: 'More',
                isDark: isDark,
                onAction: () {},
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _RecommendedGrid(isDark: isDark),
              const SizedBox(height: AppDimensions.spacingXxxl),

              // ── Section 3: Daily Quizzes ───────────────────────────────
              _SectionHeader(
                title: 'Daily Quizzes',
                actionLabel: 'View all',
                isDark: isDark,
                onAction: () {},
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _DailyQuizzesSection(isDark: isDark),
              const SizedBox(height: AppDimensions.spacingXxxl),

              // ── Section 4: Points & Streak Summary ─────────────────────
              _PointsStreakCard(isDark: isDark),
              const SizedBox(height: AppDimensions.spacingXxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Header: Greeting + Streak Badge
// ═════════════════════════════════════════════════════════════════════════════

class _HomeHeader extends StatelessWidget {
  final bool isDark;

  const _HomeHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: AppDimensions.screenPadding.copyWith(top: 12, bottom: 0),
      child: Row(
        children: [
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ravindu 👋',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          // Streak Badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingMd,
                vertical: AppDimensions.spacingSm),
            decoration: BoxDecoration(
              gradient: AppColors.streakGradient,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentStreak.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  '7 Day Streak',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Section Header
// ═════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final bool isDark;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.isDark,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final accent = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Padding(
      padding: AppDimensions.screenPadding,
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Section 1 — Continue Learning (Horizontal Scroll Cards)
// ═════════════════════════════════════════════════════════════════════════════

class _ContinueLearningCarousel extends StatelessWidget {
  final bool isDark;

  const _ContinueLearningCarousel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: AppDimensions.screenPadding,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _continueLearningItems.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.spacingMd),
        itemBuilder: (context, index) {
          final item = _continueLearningItems[index];
          return _ContinueLearningCard(
            item: item,
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final _ContinueLearningItem item;
  final bool isDark;

  const _ContinueLearningCard({
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: surface,
        borderRadius:
            BorderRadius.circular(AppDimensions.cardRadiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: item.gradient,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(
                item.icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm + 2),

            // Title
            Text(
              item.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // Percent complete
            Row(
              children: [
                Text(
                  '${item.percentComplete}% Complete',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingXs),

            // Animated progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 4,
                width: double.infinity,
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: item.percentComplete / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradientDark,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),

            // Resume button
            Container(
              width: double.infinity,
              height: 34,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradientDark,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusXs),
              ),
              child: Center(
                child: Text(
                  'Resume',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningItem {
  final String title;
  final int percentComplete;
  final IconData icon;
  final Gradient gradient;

  const _ContinueLearningItem({
    required this.title,
    required this.percentComplete,
    required this.icon,
    required this.gradient,
  });
}

const _continueLearningItems = [
  _ContinueLearningItem(
    title: 'Machine Learning Basics',
    percentComplete: 72,
    icon: Icons.auto_awesome_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF5B5FFF), Color(0xFF7B61FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _ContinueLearningItem(
    title: 'Python for Data Science',
    percentComplete: 45,
    icon: Icons.code_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF00C781), Color(0xFF62E5A6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _ContinueLearningItem(
    title: 'UI/UX Fundamentals',
    percentComplete: 88,
    icon: Icons.palette_outlined,
    gradient: LinearGradient(
      colors: [Color(0xFFFFB547), Color(0xFFFF7A45)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _ContinueLearningItem(
    title: 'Database Design',
    percentComplete: 30,
    icon: Icons.storage_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF00D4FF), Color(0xFF5B5FFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
// Section 2 — Recommended For You (Grid)
// ═════════════════════════════════════════════════════════════════════════════

class _RecommendedGrid extends StatelessWidget {
  final bool isDark;

  const _RecommendedGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppDimensions.screenPadding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppDimensions.spacingMd,
          mainAxisSpacing: AppDimensions.spacingMd,
          childAspectRatio: 0.72,
        ),
        itemCount: _recommendedItems.length,
        itemBuilder: (context, index) {
          return _RecommendationCard(
            item: _recommendedItems[index],
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final _RecommendationItem item;
  final bool isDark;

  const _RecommendationCard({
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius:
            BorderRadius.circular(AppDimensions.cardRadiusSm),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail area
          Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: item.thumbnailGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.cardRadiusSm),
              ),
            ),
            child: Stack(
              children: [
                // Decorative pattern
                Positioned(
                  right: -10,
                  top: -10,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Icon(
                    item.thumbnailIcon,
                    color: Colors.white.withValues(alpha: 0.30),
                    size: 32,
                  ),
                ),
                // Format badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: _FormatBadge(format: item.format),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject tag
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.subjectColor.withValues(alpha: 0.14),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXs),
                  ),
                  child: Text(
                    item.subject,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: item.subjectColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),

                // Title
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),

                // Difficulty + Time
                Row(
                  children: [
                    // Difficulty indicator
                    ...List.generate(3, (i) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < item.difficulty
                              ? item.difficultyColor
                              : Colors.black
                                  .withValues(alpha: isDark ? 0.20 : 0.08),
                        ),
                      );
                    }),
                    const Spacer(),
                    SizedBox(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 12,
                              color: textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '${item.estimatedMinutes}m',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  final _ContentFormat format;

  const _FormatBadge({required this.format});

  @override
  Widget build(BuildContext context) {
    final (String label, IconData icon, Color color) = switch (format) {
      _ContentFormat.video => ('Video', Icons.play_arrow_rounded, const Color(0xFF5B5FFF)),
      _ContentFormat.quiz => ('Quiz', Icons.quiz_outlined, const Color(0xFF00C781)),
      _ContentFormat.text => ('Text', Icons.article_outlined, const Color(0xFFFFB547)),
      _ContentFormat.audio => ('Audio', Icons.headphones_rounded, const Color(0xFFFF7A45)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ContentFormat { video, quiz, text, audio }

class _RecommendationItem {
  final String subject;
  final Color subjectColor;
  final String title;
  final _ContentFormat format;
  final int difficulty;
  final int estimatedMinutes;
  final Color difficultyColor;
  final Gradient thumbnailGradient;
  final IconData thumbnailIcon;

  const _RecommendationItem({
    required this.subject,
    required this.subjectColor,
    required this.title,
    required this.format,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.difficultyColor,
    required this.thumbnailGradient,
    required this.thumbnailIcon,
  });
}

const _recommendedItems = [
  _RecommendationItem(
    subject: 'Data Science',
    subjectColor: Color(0xFF5B5FFF),
    title: 'Statistics for Machine Learning',
    format: _ContentFormat.video,
    difficulty: 2,
    estimatedMinutes: 12,
    difficultyColor: Color(0xFFFFB547),
    thumbnailGradient: LinearGradient(
      colors: [Color(0xFF5B5FFF), Color(0xFF7B61FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    thumbnailIcon: Icons.bar_chart_rounded,
  ),
  _RecommendationItem(
    subject: 'Coding',
    subjectColor: Color(0xFF00C781),
    title: 'Clean Code Principles',
    format: _ContentFormat.text,
    difficulty: 1,
    estimatedMinutes: 8,
    difficultyColor: Color(0xFF00C781),
    thumbnailGradient: LinearGradient(
      colors: [Color(0xFF00C781), Color(0xFF62E5A6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    thumbnailIcon: Icons.code_rounded,
  ),
  _RecommendationItem(
    subject: 'Design',
    subjectColor: Color(0xFFFF7A45),
    title: 'Color Theory Essentials',
    format: _ContentFormat.quiz,
    difficulty: 1,
    estimatedMinutes: 5,
    difficultyColor: Color(0xFF00C781),
    thumbnailGradient: LinearGradient(
      colors: [Color(0xFFFFB547), Color(0xFFFF7A45)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    thumbnailIcon: Icons.palette_outlined,
  ),
  _RecommendationItem(
    subject: 'Productivity',
    subjectColor: Color(0xFF00D4FF),
    title: 'Time Management Techniques',
    format: _ContentFormat.audio,
    difficulty: 2,
    estimatedMinutes: 15,
    difficultyColor: Color(0xFFFFB547),
    thumbnailGradient: LinearGradient(
      colors: [Color(0xFF00D4FF), Color(0xFF5B5FFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    thumbnailIcon: Icons.timer_outlined,
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
// Section 3 — Daily Quizzes
// ═════════════════════════════════════════════════════════════════════════════

class _DailyQuizzesSection extends StatelessWidget {
  final bool isDark;

  const _DailyQuizzesSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppDimensions.screenPadding,
      child: Column(
        children: _dailyQuizItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
            child: _QuizCard(item: item, isDark: isDark),
          );
        }).toList(),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final _DailyQuizItem item;
  final bool isDark;

  const _QuizCard({
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            surface,
            item.accentColor.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(AppDimensions.cardRadiusSm),
        border: Border.all(
          color: item.accentColor.withValues(alpha: isDark ? 0.15 : 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: item.accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Row(
          children: [
            // Quiz icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item.accentColor,
                    item.accentColor.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(
                Icons.quiz_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.topic,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.help_outline_rounded,
                          size: 14, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${item.questionCount} Questions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Icon(Icons.auto_awesome_rounded,
                          size: 14,
                          color: item.accentColor),
                      const SizedBox(width: 4),
                      Text(
                        '+${item.xpReward} XP',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: item.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Start button
            Container(
              width: 72,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item.accentColor,
                    item.accentColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Center(
                child: Text(
                  'Start',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyQuizItem {
  final String topic;
  final int questionCount;
  final int xpReward;
  final Color accentColor;

  const _DailyQuizItem({
    required this.topic,
    required this.questionCount,
    required this.xpReward,
    required this.accentColor,
  });
}

const _dailyQuizItems = [
  _DailyQuizItem(
    topic: 'Physics Challenge',
    questionCount: 10,
    xpReward: 50,
    accentColor: Color(0xFF5B5FFF),
  ),
  _DailyQuizItem(
    topic: 'Vocabulary Builder',
    questionCount: 8,
    xpReward: 35,
    accentColor: Color(0xFF00C781),
  ),
  _DailyQuizItem(
    topic: 'Logic Puzzles',
    questionCount: 6,
    xpReward: 40,
    accentColor: Color(0xFFFF7A45),
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
// Section 4 — Points & Streak Summary
// ═════════════════════════════════════════════════════════════════════════════

class _PointsStreakCard extends StatelessWidget {
  final bool isDark;

  const _PointsStreakCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: AppDimensions.screenPadding,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              surface,
              AppColors.primaryDark.withValues(alpha: isDark ? 0.08 : 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(AppDimensions.cardRadiusLg),
          border: Border.all(
            color: AppColors.primaryDark.withValues(alpha: isDark ? 0.15 : 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: isDark ? 0.15 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: Level + XP + Achievement badge
              Row(
                children: [
                  // Level badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.indigoGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.30),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lvl',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '7',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingLg),

                  // XP info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total XP',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '3,450',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Mini progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 6,
                            width: double.infinity,
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.25 : 0.06),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.68,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradientDark,
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '680 XP to Level 8',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Achievement badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accentStreak.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.accentStreak,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXxl),

              // Weekly activity heatmap
              Text(
                'This Week',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              _WeeklyHeatmap(isDark: isDark),

              const SizedBox(height: AppDimensions.spacingLg),

              // Streak achievement row
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: AppColors.accentStreak, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '7-day streak — Keep it going!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentStreak,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.streakGradient,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: const Text(
                      '+100 XP Bonus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Weekly Heatmap ─────────────────────────────────────────────────────────

class _WeeklyHeatmap extends StatelessWidget {
  final bool isDark;

  const _WeeklyHeatmap({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Simulated activity data: 7 days (0 = no activity, 1 = some, 2=good, 3=great, 4=max)
    const activityData = [4, 3, 2, 4, 1, 3, 4];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final activity = activityData[index];
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final height = (10 + activity * 12.0).clamp(10.0, 58.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: height,
              decoration: BoxDecoration(
                gradient: activity == 0
                    ? null
                    : LinearGradient(
                        colors: [
                          AppColors.primaryDark.withValues(
                              alpha: 0.2 + activity * 0.2),
                          AppColors.primaryDark.withValues(
                              alpha: 0.5 + activity * 0.12),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                color: activity == 0
                    ? Colors.black.withValues(alpha: isDark ? 0.15 : 0.04)
                    : null,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusXs),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dayNames[index],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      }),
    );
  }
}