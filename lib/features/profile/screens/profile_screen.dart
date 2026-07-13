import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';

import '../../../core/services/theme_service.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../auth/screens/onboarding_screen.dart';
import '../../learning/models/lesson_model.dart';
import '../../learning/repositories/learning_repository.dart';
import '../../learning/repositories/xp_calculation.dart';
import '../../learning/services/saved_videos_service.dart';
import '../../lessons/screens/lesson_detail_screen.dart';


import '../../admin/screens/admin_review_screen.dart';
import '../../../core/services/admin_service.dart';
import 'edit_profile_screen.dart';
import 'learning_preferences_screen.dart';



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
  final int level;
  final bool isCurrentUser;
  final bool trendingUp;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.handle,
    required this.xp,
    required this.level,
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
    final brightness = Theme.of(context).brightness;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundFor(brightness),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off_rounded,
                      size: 72, color: AppColors.textSecondaryFor(brightness)),
                  const SizedBox(height: 16),
                  Text(
                    'You are signed out',
                    style: TextStyle(
                      color: AppColors.textPrimaryFor(brightness),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in to see your profile, saved lessons, and progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondaryFor(brightness),
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
                      child: Text(
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
      backgroundColor: AppColors.backgroundFor(brightness),
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
                  iconColor: AppColors.textSecondaryFor(brightness),
                ),
              ],
            ),

            // ── Avatar Section ──
            _ProfileHeader(),
            const SizedBox(height: AppDimensions.spacingXxl),

            // ── Stats Row ──
            _StatsRow(),
            const SizedBox(height: AppDimensions.spacingXxl),

            _SavedVideosSection(),
            const SizedBox(height: AppDimensions.spacingXxl),

            // ── Learning Progress Section ──
            _SectionHeader(
              title: 'My Learning',
              action: 'View All',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _MyLearningRecordsPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            _MyLearningRecordsSection(),

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
    final brightness = Theme.of(context).brightness;

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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.backgroundFor(brightness),
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryFor(brightness),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryFor(brightness),
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
                  color: AppColors.surfaceFor(brightness),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
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
                        color: AppColors.textSecondaryFor(brightness),
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
                  color: AppColors.surfaceFor(brightness),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  'no records',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryFor(brightness),
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
    final brightness = Theme.of(context).brightness;
    return Container(
      color: AppColors.backgroundFor(brightness),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.textPrimaryFor(brightness),
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
    final brightness = Theme.of(context).brightness;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(brightness),
          borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
          border: Border.all(
            color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            'no records',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryFor(brightness),
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
              color: AppColors.surfaceFor(brightness),
              borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
              border: Border.all(
                color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.08),
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
            _formatXp(totalXp),
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
            color: AppColors.surfaceFor(brightness),
            borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
            border: Border.all(
              color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.08),
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryFor(brightness),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      stat.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryFor(brightness),
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

  String _formatXp(int xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(xp % 1000 == 0 ? 0 : 1)}k';
    }
    return xp.toString();
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
        return AppColors.textSecondaryLight;
    }
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  const _StatData(this.icon, this.value, this.label);
}

class _MyLearningRecordsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const _NoRecordsCard(message: 'no records');
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: LearningRepository(Supabase.instance.client)
          .fetchUserRecentLearningRecords(userUuid: user.id, limit: 3),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 40,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );

        }

        final records = snapshot.data!;
        if (records.isEmpty) {
          return const _NoRecordsCard(message: 'no learning records');
        }

        return Column(
          children: records.map((record) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LearningRecordCard(record: record),
            );
          }).toList(),
        );
      },
    );
  }
}

class _LearningRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _LearningRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final title = record['title']?.toString() ?? 'Untitled';
    final category = record['category']?.toString() ?? 'General';
    final thumbnail = _thumbnailForRecord(record);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(brightness),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        border: Border.all(
          color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        onTap: () {
          final videoUrl = record['video_url']?.toString() ?? '';
          final lesson = LessonModel(
            id: record['lesson_id']?.toString() ?? '',
            title: title,
            description: '',
            content: '',
            category: category,
            videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
            thumbnailUrl: thumbnail.isNotEmpty ? thumbnail : null,
            difficultyLevel: 'beginner',
            format: 'video',
            minNetworkStrength: 'weak',
            safeForMotion: true,
            status: 'approved',
            isPublished: true,
            createdAt: DateTime.tryParse(record['last_accessed']?.toString() ?? ''),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonDetailScreen.fromModel(lesson),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: thumbnail.isNotEmpty
                      ? Image.network(
                          thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _learningThumbFallback(brightness),
                        )
                      : _learningThumbFallback(brightness),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryFor(brightness),
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Watched ${_formatLastAccessed(record['last_accessed'])}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.primaryFor(brightness),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _learningThumbFallback(Brightness brightness) {
    return Container(
      color: AppColors.surfaceFor(brightness),
      child: Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          size: 40,
          color: AppColors.textSecondaryFor(brightness),
        ),
      ),
    );
  }

  String _thumbnailForRecord(Map<String, dynamic> record) {
    final thumbnail = record['thumbnail_url']?.toString().trim() ?? '';
    if (thumbnail.isNotEmpty) return thumbnail;
    final videoUrl = record['video_url']?.toString().trim() ?? '';
    if (videoUrl.startsWith('yt:')) {
      final id = videoUrl.substring(3).trim();
      if (id.isNotEmpty) return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    final uri = Uri.tryParse(videoUrl);
    if (uri != null) {
      if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        return 'https://img.youtube.com/vi/${uri.pathSegments.first}/hqdefault.jpg';
      }
      if (uri.host.contains('youtube.com')) {
        final v = uri.queryParameters['v'];
        if (v != null && v.isNotEmpty) {
          return 'https://img.youtube.com/vi/$v/hqdefault.jpg';
        }
      }
    }
    return '';
  }

  String _formatLastAccessed(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'recently';
    return '${parsed.month}/${parsed.day}/${parsed.year}';
  }
}

class _MyLearningRecordsPage extends StatelessWidget {
  const _MyLearningRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final brightness = Theme.of(context).brightness;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundFor(brightness),
        body: const Center(child: Text('no records')),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: LearningRepository(Supabase.instance.client)
          .fetchUserRecentLearningRecords(userUuid: user.id, limit: 1000),
      builder: (context, snapshot) {
        final records = snapshot.data ?? const <Map<String, dynamic>>[];
        return Scaffold(
          backgroundColor: AppColors.backgroundFor(brightness),
          appBar: AppBar(
            title: const Text('My Learning'),
            backgroundColor: AppColors.backgroundFor(brightness),
            foregroundColor: AppColors.textPrimaryFor(brightness),
          ),
          body: records.isEmpty
              ? const Center(child: Text('no learning records'))
              : ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.spacingLg),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _LearningRecordCard(record: records[index]);
                  },
                ),
        );
      },
    );
  }
}


// ── Section Header ────────────────────────────────────────────────────────

class _SavedVideosSection extends ConsumerWidget {
  final SavedVideosService _service = SavedVideosService();

  _SavedVideosSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final brightness = Theme.of(context).brightness;
    ref.watch(savedVideosRefreshProvider);
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<List<LessonModel>>(
      future: _service.getSavedVideos(user.id),
      builder: (context, snapshot) {
        final videos = snapshot.data ?? const <LessonModel>[];
        final visible = videos.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Saved Videos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryFor(brightness),
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: videos.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _SavedVideosPage(videos: videos),
                            ),
                          );
                        },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: videos.isEmpty
                          ? AppColors.textSecondaryFor(brightness).withValues(alpha: 0.5)
                          : AppColors.primaryFor(brightness).withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            if (videos.isEmpty)
              const _NoRecordsCard(message: 'no saved videos')
            else
              Column(
                children: visible
                    .map(
                      (lesson) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SavedVideoListItem(lesson: lesson),
                      ),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }
}

class _SavedVideoListItem extends StatelessWidget {
  final LessonModel lesson;
  const _SavedVideoListItem({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final thumbnail = _thumbnailForLesson(lesson);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(brightness),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        border: Border.all(
          color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonDetailScreen.fromModel(lesson),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child: thumbnail.isNotEmpty
                      ? Image.network(
                          thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbnailFallback(brightness),
                        )
                      : _thumbnailFallback(brightness),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lesson.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryFor(brightness),
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.primaryFor(brightness),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnailFallback(Brightness brightness) {
    return Container(
      color: AppColors.surfaceFor(brightness),
      child: Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          size: 42,
          color: AppColors.textSecondaryFor(brightness),
        ),
      ),
    );
  }

  String _thumbnailForLesson(LessonModel lesson) {
    final thumbnail = lesson.thumbnailUrl?.trim() ?? '';
    if (thumbnail.isNotEmpty) return thumbnail;

    final videoUrl = lesson.videoUrl?.trim() ?? '';
    if (videoUrl.startsWith('yt:')) {
      final videoId = videoUrl.substring(3).trim();
      if (videoId.isNotEmpty) {
        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    }

    final ytId = _extractYoutubeVideoId(videoUrl);
    if (ytId != null) {
      return 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
    }

    return '';
  }

  String? _extractYoutubeVideoId(String url) {
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    if (uri.host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }
}

class _SavedVideosPage extends StatelessWidget {
  final List<LessonModel> videos;
  const _SavedVideosPage({required this.videos});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      appBar: AppBar(
        title: const Text('Saved Videos'),
        backgroundColor: AppColors.backgroundFor(brightness),
        foregroundColor: AppColors.textPrimaryFor(brightness),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lesson = videos[index];
          return _SavedVideoListItem(lesson: lesson);
        },
      ),
    );
  }

  String _thumbnailForLesson(LessonModel lesson) {
    final thumbnail = lesson.thumbnailUrl?.trim() ?? '';
    if (thumbnail.isNotEmpty) return thumbnail;

    final videoUrl = lesson.videoUrl?.trim() ?? '';
    if (videoUrl.startsWith('yt:')) {
      final videoId = videoUrl.substring(3).trim();
      if (videoId.isNotEmpty) {
        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    }

    final uri = Uri.tryParse(videoUrl);
    if (uri != null) {
      if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        return 'https://img.youtube.com/vi/${uri.pathSegments.first}/hqdefault.jpg';
      }
      if (uri.host.contains('youtube.com')) {
        final v = uri.queryParameters['v'];
        if (v != null && v.isNotEmpty) {
          return 'https://img.youtube.com/vi/$v/hqdefault.jpg';
        }
      }
    }

    return '';
  }
}

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
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryFor(brightness),
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
              color: AppColors.primaryFor(brightness).withValues(alpha: 0.8),
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
    final brightness = Theme.of(context).brightness;
    // Simple card-like chip for now; can be enhanced to include count/icon.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(brightness),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        border: Border.all(
          color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryFor(brightness),
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
    final brightness = Theme.of(context).brightness;
    final user = Supabase.instance.client.auth.currentUser;
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
            Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryFor(brightness),
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            // Toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceFor(brightness),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.1),
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
              .fetchLeaderboardFromProgress(weekly: showWeekly, limit: 1000),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final allRows = snapshot.data!;
            final rows = allRows.take(10).toList();
            if (rows.isEmpty) {
              return const _NoRecordsCard(message: 'no records');
            }

            final currentUserRow = user == null
                ? null
                : allRows.cast<Map<String, dynamic>?>().firstWhere(
                    (r) => (r?['user_id']?.toString() ?? '') == user.id,
                    orElse: () => null,
                  );
            final currentRank = (currentUserRow?['rank'] as num?)?.toInt() ?? 0;
            final currentXp = (currentUserRow?['xp'] as num?)?.toInt() ?? 0;
            final currentLevel = (currentUserRow?['level'] as num?)?.toInt() ??
                XpCalculation.calculateLevel(currentXp);

            final currentUserRowIndex = user == null
                ? -1
                : rows.indexWhere((r) => (r['user_id']?.toString() ?? '') == user.id);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spacingLg),
                    margin: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceFor(brightness),
                      borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
                      border: Border.all(
                        color: AppColors.textSecondaryFor(brightness)
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.aiGradient,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your rank',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondaryFor(brightness),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentRank > 0 ? '#$currentRank' : 'Not ranked yet',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryFor(brightness),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$currentXp XP | Lv $currentLevel',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondaryFor(brightness),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                ...rows.map((r) {
                  final rank = (r['rank'] as num?)?.toInt() ?? 0;
                  final name = r['name']?.toString() ?? '';
                  final handle = (r['handle'] as String?)?.toString() ?? '@user';
                  final xp = (r['xp'] as num?)?.toInt() ?? 0;
                  final uid = (r['user_id'] as String?)?.toString();
                  final level = (r['level'] as int?) ?? XpCalculation.calculateLevel(xp);

                  final isCurrentUser = user != null && uid != null && uid == user.id;

                  return _LeaderboardRow(
                    entry: LeaderboardEntry(
                      rank: rank,
                      name: name,
                      handle: handle,
                      xp: xp,
                      level: level,
                      isCurrentUser: isCurrentUser,
                      trendingUp: true,
                    ),
                    isTop3: rank <= 3,
                  );
                }),
                if (user != null && currentUserRowIndex < 0 && currentRank > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppDimensions.spacingMd),
                    child: _LeaderboardRow(
                      entry: LeaderboardEntry(
                        rank: currentRank,
                        name: 'You',
                        handle: '@you',
                        xp: currentXp,
                        level: currentLevel,
                        isCurrentUser: true,
                        trendingUp: true,
                      ),
                      isTop3: currentRank <= 3,
                    ),
                  ),
              ],
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
    final brightness = Theme.of(context).brightness;
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
              ? AppColors.primaryFor(brightness).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? AppColors.primaryFor(brightness)
                : AppColors.textSecondaryFor(brightness),
          ),
        ),
      ),
    );
  }
}

class _DividerWithDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.15),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textSecondaryFor(brightness),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.15),
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
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(brightness),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        border: Border.all(
          color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryFor(brightness),
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
    final brightness = Theme.of(context).brightness;
    return Container(

      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm + 2,
      ),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.primaryFor(brightness).withValues(alpha: 0.08)
            : AppColors.surfaceFor(brightness),
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
                        ? AppColors.primaryFor(brightness)
                        : AppColors.textSecondaryFor(brightness),
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
                        AppColors.textSecondaryFor(brightness).withValues(alpha: 0.2),
                        AppColors.textSecondaryFor(brightness).withValues(alpha: 0.2),
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
                      ? AppColors.textPrimaryFor(brightness)
                      : AppColors.textSecondaryFor(brightness),
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
                        ? AppColors.primaryFor(brightness)
                        : AppColors.textPrimaryFor(brightness),
                  ),
                ),
                Text(
                  entry.handle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
              ],
            ),
          ),

          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatXp(entry.xp)} XP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: entry.isCurrentUser
                      ? AppColors.primaryFor(brightness)
                      : AppColors.textPrimaryFor(brightness),
                ),
              ),
              Text(
                'Lv ${entry.level}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
            ],
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
    return AppColors.textSecondaryLight;
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(xp % 1000 == 0 ? 0 : 1)}k';
    }
    return xp.toString();
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
    final brightness = Theme.of(context).brightness;
    final settings = [
      _SettingItem(Icons.person_outline, 'Edit Profile'),
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
            color: AppColors.surfaceFor(brightness),
            borderRadius: BorderRadius.circular(AppDimensions.cardRadiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: brightness == Brightness.dark ? 0.4 : 0.08),
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
                color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingXxl,
                vertical: AppDimensions.spacingMd,
              ),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryFor(brightness),
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.textSecondaryFor(brightness)),
            Consumer(
              builder: (context, ref, _) {
                final themeMode = ref.watch(themeProvider);
                final isDark = themeMode == ThemeMode.dark;
                final currentBrightness = isDark ? Brightness.dark : Brightness.light;

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
                    color: AppColors.surfaceFor(currentBrightness),
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
                                color: AppColors.textPrimaryFor(currentBrightness),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isDark ? 'Dark mode' : 'Light mode',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryFor(currentBrightness),
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
    final brightness = Theme.of(context).brightness;
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
        } else if (item.label == 'Learning Preferences') {
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LearningPreferencesScreen(),
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
                color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(
                item.icon,
                size: 18,
                color: AppColors.textSecondaryFor(brightness),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryFor(brightness),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textSecondaryFor(brightness),
            ),
          ],
        ),
      ),
    );
  }
}

