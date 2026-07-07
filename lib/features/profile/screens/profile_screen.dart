import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';

import '../../../core/services/theme_service.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../auth/screens/onboarding_screen.dart';
import '../../learning/repositories/learning_repository.dart';


import '../../admin/screens/admin_review_screen.dart';
import '../../../core/services/admin_service.dart';
import 'edit_profile_screen.dart';



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
// DB-backed data (no mock values)
// ─────────────────────────────────────────────────────────────────────────────


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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_rounded,
                      size: 72, color: AppColors.textSecondaryDark),
                  const SizedBox(height: 16),
                  const Text(
                    'You are signed out',
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in to see your profile, saved lessons, and progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (_) => false,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
            _MyLearningCategoriesSection(),

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
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return FutureBuilder<Map<String, dynamic>?>(
      future: user == null
          ? Future.value(null)
          : LearningRepository(Supabase.instance.client)
              .fetchUserProfile(userUuid: user.id),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final fullName = (profile?['full_name'] as String?)?.trim();
        final username = (profile?['username'] as String?)?.trim();
        final avatarUrl = (profile?['avatar_url'] as String?)?.trim();

        final displayName =
            (fullName != null && fullName.isNotEmpty) ? fullName : null;
        final handle = username != null && username.isNotEmpty
            ? (username.startsWith('@') ? username : '@$username')
            : null;

        final initials = _initialsFor(displayName ?? user?.email ?? 'U');

        final hasAnyHeaderData =
            displayName != null || handle != null || (avatarUrl != null && avatarUrl.isNotEmpty);

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
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _InitialAvatar(initials: initials),
                        )
                      : _InitialAvatar(initials: initials),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),

            // Name + Username
            Text(
              displayName ?? 'No records',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
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
                Text(
                  handle ?? '@user',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSm),

            // Bio (only show if some profile row exists)
            if (hasAnyHeaderData)
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
              )
            else
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
                child: const Text(
                  'no records',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _initialsFor(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initials;
  const _InitialAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundDark,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}


// ── Stats Row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
          border: Border.all(
            color: AppColors.textSecondaryDark.withValues(alpha: 0.08),
          ),
        ),
        child: const Center(
          child: Text(
            'no records',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: LearningRepository(Supabase.instance.client)
          .fetchUserStatsFromProgress(userUuid: user.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
              border: Border.all(
                color: AppColors.textSecondaryDark.withValues(alpha: 0.08),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final lessonsCount = (data['lessonsCount'] as int?) ?? 0;
        final totalXp = (data['totalXp'] as int?) ?? 0;
        final streak = (data['streak'] as int?) ?? 0;
        final rank = (data['rank'] as int?) ?? 0;

        final stats = [
          _StatData(Icons.menu_book_rounded, '${lessonsCount}', 'Lessons'),
          _StatData(
            Icons.auto_awesome_rounded,
            totalXp.toString(),
            'XP',
          ),
          _StatData(
            Icons.local_fire_department_rounded,
            '${streak}',
            'Streak',
          ),
          _StatData(Icons.emoji_events_rounded, '#${rank}', 'Rank'),
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
      },
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

class _MyLearningCategoriesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const _NoRecordsCard(message: 'no records');
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: LearningRepository(Supabase.instance.client)
          .fetchUserRecentCategoriesFromProgress(userUuid: user.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 40,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );

        }

        final cats = snapshot.data!;
        if (cats.isEmpty) {
          return const _NoRecordsCard(message: 'no records');
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cats.map((c) {
            final name = (c['name'] as String?)?.trim();
            if (name == null || name.isEmpty) return const SizedBox.shrink();
            return _CategoryChipCard(category: name);
          }).toList(),
        );
      },
    );
  }
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

class _CategoryChipCard extends StatelessWidget {
  final String category;
  const _CategoryChipCard({required this.category});

  @override
  Widget build(BuildContext context) {
    // Simple card-like chip for now; can be enhanced to include count/icon.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        border: Border.all(
          color: AppColors.textSecondaryDark.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
      ),
    );
  }
}

// NOTE: _SubjectProgressCard is currently unused.
// It was partially commented out but left behind invalid Dart code.
// Commenting out the entire widget to restore analyzer/build stability.
// NOTE: _SubjectProgressCard is currently unused.
// The previous code was partially commented out and left the file with an
// invalid (unterminated) multi-line comment, which breaks parsing.
//
// Re-enable this widget later when it’s ready to display.



// ── Leaderboard Section

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

        FutureBuilder<List<Map<String, dynamic>>>(
          future: LearningRepository(Supabase.instance.client)
              .fetchLeaderboardFromProgress(weekly: showWeekly, limit: 10),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final rows = snapshot.data!;
            if (rows.isEmpty) {
              return const _NoRecordsCard(message: 'no records');
            }

            final user = Supabase.instance.client.auth.currentUser;

            return Column(
              children: rows.map((r) {
                final rank = (r['rank'] as num?)?.toInt() ?? 0;
            final name = r['name']?.toString() ?? '';
                final handle = (r['handle'] as String?)?.toString() ?? '@user';
                final xp = (r['xp'] as num?)?.toInt() ?? 0;
                final uid = (r['user_id'] as String?)?.toString();

                final isCurrentUser = user != null && uid != null && uid == user.id;

                return _LeaderboardRow(
                  entry: LeaderboardEntry(
                    rank: rank,
                    name: name,
                    handle: handle,
                    xp: xp,
                    isCurrentUser: isCurrentUser,
                    trendingUp: true,
                  ),
                  isTop3: rank <= 3,
                );
              }).toList(),
            );
          },
        ),



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

class _NoRecordsCard extends StatelessWidget {
  final String message;
  const _NoRecordsCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        border: Border.all(
          color: AppColors.textSecondaryDark.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryDark,
        ),
      ),
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
      _SettingItem(Icons.notifications_outlined, 'Notifications'),
      _SettingItem(Icons.lock_outline, 'Privacy'),
      _SettingItem(Icons.tune_outlined, 'Learning Preferences'),
    ];

    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.cardRadiusLg),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
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
          child: SingleChildScrollView(
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
                    borderRadius:
                        BorderRadius.circular(AppDimensions.cardRadiusMd),
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
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
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
                            gradient:
                                isDark ? AppColors.primaryGradientLight : null,
                            color: isDark
                                ? null
                                : AppColors.textSecondaryLight
                                    .withValues(alpha: 0.2),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: isDark
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
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
            FutureBuilder<bool>(
              future: LearningRepository(Supabase.instance.client)
                  .isAdmin(Supabase.instance.client.auth.currentUser?.id ?? ''),
              builder: (context, snapshot) {
                if (snapshot.data != true) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminReviewScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingLg,
                      vertical: AppDimensions.spacingSm,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingLg,
                      vertical: AppDimensions.spacingMd,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.cardRadiusMd),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Panel',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Review pending lessons',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.warning,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ...settings.map((item) => _SettingsTile(item: item)),
            const SizedBox(height: AppDimensions.spacingMd),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingLg,
                vertical: AppDimensions.spacingSm,
              ),
              child: GestureDetector(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Log Out',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  final rootNav = Navigator.of(context, rootNavigator: true);
                  if (context.mounted) Navigator.of(context).pop();
                  try {
                    await performLogout();
                    rootNav.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                      (_) => false,
                    );
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logout failed. Please try again.')),
                      );
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
          ],
        ),
          ),
        ),
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
      onTap: () async {
        // Close the sheet first.
        Navigator.of(context).pop();

        if (item.label == 'Edit Profile') {
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EditProfileScreen(),
            ),
          );
        }
      },
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

