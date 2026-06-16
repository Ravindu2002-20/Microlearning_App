import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/widgets/glass_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

class SubjectProgress {
  final String name;
  final IconData icon;
  final int completed;
  final int total;
  final Color color;

  const SubjectProgress({
    required this.name,
    required this.icon,
    required this.completed,
    required this.total,
    required this.color,
  });

  double get fraction => completed / total;
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final String handle;
  final int xp;
  final bool isCurrentUser;
  final bool trendingUp;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.handle,
    required this.xp,
    this.isCurrentUser = false,
    this.trendingUp = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock Data
// ─────────────────────────────────────────────────────────────────────────────

final _subjects = [
  SubjectProgress(
    name: 'AI Fundamentals',
    icon: Icons.auto_awesome_outlined,
    completed: 18,
    total: 25,
    color: AppColors.primaryDark,
  ),
  SubjectProgress(
    name: 'Data Science',
    icon: Icons.analytics_outlined,
    completed: 12,
    total: 20,
    color: AppColors.accentQuiz,
  ),
  SubjectProgress(
    name: 'Web Development',
    icon: Icons.code_outlined,
    completed: 24,
    total: 30,
    color: AppColors.accentMotion,
  ),
  SubjectProgress(
    name: 'Mathematics',
    icon: Icons.calculate_outlined,
    completed: 8,
    total: 15,
    color: AppColors.warning,
  ),
];

final _leaderboard = [
  const LeaderboardEntry(rank: 1, name: 'Sarah Chen', handle: '@sarahai', xp: 4850, trendingUp: true),
  const LeaderboardEntry(rank: 2, name: 'Alex Kim', handle: '@alexk', xp: 4320, trendingUp: true),
  const LeaderboardEntry(rank: 3, name: 'Maria Lopez', handle: '@marial', xp: 3980, trendingUp: false),
  const LeaderboardEntry(rank: 4, name: 'James Wilson', handle: '@jwilson', xp: 3650, trendingUp: true),
  const LeaderboardEntry(rank: 5, name: 'Priya Patel', handle: '@priyap', xp: 3420, trendingUp: false),
  const LeaderboardEntry(rank: 6, name: 'David Kim', handle: '@davidk', xp: 3100, trendingUp: true),
  const LeaderboardEntry(rank: 7, name: 'Emma Thompson', handle: '@emmat', xp: 2890, trendingUp: false),
  const LeaderboardEntry(rank: 8, name: 'Lucas Brown', handle: '@lucasb', xp: 2650, trendingUp: true),
  const LeaderboardEntry(rank: 9, name: 'Sophia Lee', handle: '@sophial', xp: 2410, trendingUp: false),
  const LeaderboardEntry(rank: 10, name: 'Oliver Davis', handle: '@oliverd', xp: 2180, trendingUp: true),
];

const _currentUserEntry = LeaderboardEntry(
  rank: 34,
  name: 'Ravindu Induwara',
  handle: '@ravindu',
  xp: 2350,
  isCurrentUser: true,
  trendingUp: true,
);

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showWeekly = true;

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
          ),
          children: [
            // ── Top Bar ──
            const SizedBox(height: AppDimensions.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GlassButton(
                  icon: Icons.settings_outlined,
                  onTap: _showSettings,
                  size: 40,
                  iconColor: AppColors.textSecondaryDark,
                ),
              ],
            ),

            // ── Avatar Section ──
            _ProfileHeader(),
            const SizedBox(height: AppDimensions.spacingXxl),

            // ── Stats Row ──
            _StatsRow(),
            const SizedBox(height: AppDimensions.spacingXxl),

            // ── Learning Progress Section ──
            _SectionHeader(
              title: 'My Learning',
              action: 'View All',
              onAction: () {},
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            ..._subjects.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                  child: _SubjectProgressCard(subject: s),
                )),
            const SizedBox(height: AppDimensions.spacingXxl),

            // ── Leaderboard Section ──
            _LeaderboardSection(
              showWeekly: _showWeekly,
              onToggle: () => setState(() => _showWeekly = !_showWeekly),
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Sub-Widgets
// ═════════════════════════════════════════════════════════════════════════════

// ── Profile Header (Avatar + Name + Bio) ──────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar with level ring
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                AppColors.primaryDark,
                AppColors.secondaryDark,
                AppColors.accentQuiz,
                AppColors.warning,
                AppColors.primaryDark,
              ],
              stops: [0.0, 0.3, 0.6, 0.85, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundDark,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7B61FF), Color(0xFF00E5FF)],
                ),
              ),
              child: const Center(
                child: Text(
                  'RI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),

        // Name + Username
        const Text(
          'Ravindu Induwara',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentQuiz,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '@ravindu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingSm),

        // Bio
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
            vertical: AppDimensions.spacingSm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: AppColors.textSecondaryDark.withValues(alpha: 0.08),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.accentAiSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'Learning AI one lesson at a time.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(Icons.menu_book_rounded, '245', 'Lessons'),
      _StatData(Icons.auto_awesome_rounded, '2,350', 'XP'),
      _StatData(Icons.local_fire_department_rounded, '7', 'Streak'),
      _StatData(Icons.emoji_events_rounded, '#34', 'Rank'),
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        border: Border.all(
          color: AppColors.textSecondaryDark.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: stats.map((stat) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _statColor(stat.label).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Icon(
                    stat.icon,
                    color: _statColor(stat.label),
                    size: 20,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  stat.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                    height: 1.1,
                  ),
                ),
                Text(
                  stat.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _statColor(String label) {
    switch (label) {
      case 'Lessons':
        return AppColors.primaryDark;
      case 'XP':
        return AppColors.warning;
      case 'Streak':
        return AppColors.accentStreak;
      case 'Rank':
        return AppColors.secondaryDark;
      default:
        return AppColors.textSecondaryDark;
    }
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  const _StatData(this.icon, this.value, this.label);
}

// ── Section Header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Text(
            action,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Subject Progress Card ─────────────────────────────────────────────────

class _SubjectProgressCard extends StatelessWidget {
  final SubjectProgress subject;
  const _SubjectProgressCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final fraction = subject.fraction;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        border: Border.all(
          color: AppColors.textSecondaryDark.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: subject.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  subject.icon,
                  color: subject.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${subject.completed}/${subject.total} Lessons',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(fraction * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: subject.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: fraction,
              backgroundColor: AppColors.textSecondaryDark.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(subject.color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard Section ───────────────────────────────────────────────────

class _LeaderboardSection extends StatelessWidget {
  final bool showWeekly;
  final VoidCallback onToggle;

  const _LeaderboardSection({
    required this.showWeekly,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 16,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            const Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            // Toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: AppColors.textSecondaryDark.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ToggleOption(
                    label: 'Weekly',
                    isSelected: showWeekly,
                    onTap: showWeekly ? null : onToggle,
                  ),
                  _ToggleOption(
                    label: 'All Time',
                    isSelected: !showWeekly,
                    onTap: showWeekly ? onToggle : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingLg),

        // Top 10
        ...List.generate(_leaderboard.length, (index) {
          final entry = _leaderboard[index];
          return _LeaderboardRow(
            entry: entry,
            isTop3: index < 3,
          );
        }),

        // Current user pin (if not in top 10)
        const SizedBox(height: AppDimensions.spacingMd),
        _DividerWithDot(),
        const SizedBox(height: AppDimensions.spacingMd),
        _LeaderboardRow(entry: _currentUserEntry, isTop3: false),
      ],
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ToggleOption({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryDark.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? AppColors.primaryDark
                : AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }
}

class _DividerWithDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.textSecondaryDark.withValues(alpha: 0.15),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textSecondaryDark,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.textSecondaryDark.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

// ── Leaderboard Row ───────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isTop3;

  const _LeaderboardRow({
    required this.entry,
    required this.isTop3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm + 2,
      ),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.primaryDark.withValues(alpha: 0.08)
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: entry.isCurrentUser
            ? Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.2),
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              _rankDisplay(),
              style: TextStyle(
                fontSize: isTop3 ? 16 : 14,
                fontWeight: FontWeight.w800,
                color: isTop3
                    ? _rankColor()
                    : entry.isCurrentUser
                        ? AppColors.primaryDark
                        : AppColors.textSecondaryDark,
              ),
            ),
          ),

          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: entry.isCurrentUser
                  ? AppColors.aiGradient
                  : LinearGradient(
                      colors: [
                        AppColors.textSecondaryDark.withValues(alpha: 0.2),
                        AppColors.textSecondaryDark.withValues(alpha: 0.2),
                      ],
                    ),
            ),
            child: Center(
              child: Text(
                _initials(entry.name),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: entry.isCurrentUser
                      ? Colors.white
                      : AppColors.textSecondaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),

          // Name + handle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: entry.isCurrentUser
                        ? AppColors.primaryDark
                        : AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  entry.handle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),

          // XP
          Text(
            '${entry.xp} XP',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: entry.isCurrentUser
                  ? AppColors.primaryDark
                  : AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),

          // Trend
          Icon(
            entry.trendingUp
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 18,
            color: entry.trendingUp
                ? AppColors.accentQuiz
                : AppColors.error,
          ),
        ],
      ),
    );
  }

  String _rankDisplay() {
    if (isTop3) {
      return ['🥇', '🥈', '🥉'][entry.rank - 1];
    }
    return '#${entry.rank}';
  }

  Color _rankColor() {
    if (entry.rank == 1) return const Color(0xFFFFD700);
    if (entry.rank == 2) return const Color(0xFFC0C0C0);
    if (entry.rank == 3) return const Color(0xFFCD7F32);
    return AppColors.textSecondaryDark;
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Settings Bottom Sheet
// ═════════════════════════════════════════════════════════════════════════════

class _SettingsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = [
      _SettingItem(Icons.person_outline, 'Edit Profile'),
      _SettingItem(Icons.palette_outlined, 'Appearance'),
      _SettingItem(Icons.notifications_outlined, 'Notifications'),
      _SettingItem(Icons.lock_outline, 'Privacy'),
      _SettingItem(Icons.tune_outlined, 'Learning Preferences'),
    ];

    return Container(
      margin: const EdgeInsets.only(
        left: AppDimensions.spacingLg,
        right: AppDimensions.spacingLg,
        bottom: AppDimensions.spacingXxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondaryDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingXxl,
              vertical: AppDimensions.spacingMd,
            ),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.textSecondaryDark),
          Consumer(
            builder: (context, ref, _) {
              final themeMode = ref.watch(themeProvider);
              final isDark = themeMode == ThemeMode.dark;

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingLg,
                  vertical: AppDimensions.spacingSm,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingLg,
                  vertical: AppDimensions.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primaryDark.withValues(alpha: 0.15)
                            : AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDark ? 'Dark mode' : 'Light mode',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(themeProvider.notifier).toggle(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 50,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: isDark ? AppColors.primaryGradientLight : null,
                          color: isDark
                              ? null
                              : AppColors.textSecondaryLight.withValues(alpha: 0.2),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          alignment:
                              isDark ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isDark
                                  ? Icons.nights_stay_rounded
                                  : Icons.wb_sunny_rounded,
                              size: 12,
                              color: isDark
                                  ? AppColors.primaryDark
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ...settings.map((item) => _SettingsTile(item: item)),
          const SizedBox(height: AppDimensions.spacingSm),
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String label;
  const _SettingItem(this.icon, this.label);
}

class _SettingsTile extends StatelessWidget {
  final _SettingItem item;
  const _SettingsTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingXxl,
          vertical: AppDimensions.spacingMd + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.textSecondaryDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(
                item.icon,
                size: 18,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textSecondaryDark,
            ),
          ],
        ),
      ),
    );
  }
}