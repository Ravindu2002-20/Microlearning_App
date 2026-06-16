import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';
import '../../../core/services/session_manager.dart';
import '../../../features/feed/controllers/feed_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenLessons;

  const HomeScreen({
    super.key,
    required this.onOpenLessons,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _recentSearchKey = 'recent_searches';
  final _searchController = TextEditingController();
  List<String> _recentSearches = [];
  bool _loadingSearches = true;
  String? _avatarUrl;
  String? _displayName;
  String? _initials;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(sessionUserProvider);
    final nameFromMeta = _nameFromMetadata(user);
    final avatarFromMeta = _avatarFromMetadata(user);

    String? avatarUrl = avatarFromMeta;
    String? displayName = nameFromMeta;

    if (user != null) {
      try {
        // Be tolerant to schema differences. Pick the first non-empty name field.
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name, name, username, avatar_url')
            .eq('id', user.id)
            .maybeSingle();


        if (profile != null) {
          final fullName = (profile['full_name'] as String?)?.trim();
          final name = (profile['name'] as String?)?.trim();
          final username = (profile['username'] as String?)?.trim();

          if (fullName != null && fullName.isNotEmpty) {
            displayName = fullName;
          } else if (name != null && name.isNotEmpty) {
            displayName = name;
          } else if (username != null && username.isNotEmpty) {
            displayName = username;
          }

          final avatarCandidate = (profile['avatar_url'] as String?)?.trim();
          avatarUrl = (avatarCandidate != null && avatarCandidate.isNotEmpty)
              ? avatarCandidate
              : avatarUrl;
        }

      } catch (_) {
        // Fallback to auth metadata and initials when profile row is not available yet.
      }
    }

    setState(() {
      _displayName = displayName ?? 'Learner';
      _avatarUrl = avatarUrl;
      _initials = _initialsFor(displayName ?? user?.email ?? 'L');
    });
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(_recentSearchKey) ?? [];
    if (!mounted) return;
    setState(() {
      _recentSearches = cached;
      _loadingSearches = false;
    });
  }

  Future<void> _persistRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchKey, _recentSearches);
  }

  Future<void> _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _recentSearches = [
        query,
        ..._recentSearches.where((item) => item.toLowerCase() != query.toLowerCase()),
      ].take(3).toList();
    });
    await _persistRecentSearches();

    // Best-effort backend search to keep this connected to real content.
    try {
      final repo = ref.read(learningRepositoryProvider);
      final lessons = await repo.searchLessons(query: query);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lessons.isEmpty
                ? 'No lessons matched "$query".'
                : 'Found ${lessons.length} lessons for "$query".',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search submitted for "$query".')),
      );
    }
  }

  Future<void> _clearRecentSearches() async {
    setState(() {
      _recentSearches = [];
    });
    await _persistRecentSearches();
  }

  void _openLessons() {
    widget.onOpenLessons();
  }

  void _showRecommendationSheet(String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(Icons.block_rounded),
                  title: const Text('Mark as not interested'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('Send a feedback'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.report_outlined),
                  title: const Text('Report'),
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    // Match the UI requirement wording.
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }


  @override
  Widget build(BuildContext context) {
    final userName = _displayName ?? 'Learner';
    // Keep header compact so the rest of the content is always visible.
final headerHeight = 84.0;


    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: headerHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.displayMedium?.color ??
                                      (isDark ? AppColors.textPrimaryDark : Colors.black),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$userName 👋',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.displayLarge?.color ??
                                      (isDark ? AppColors.textPrimaryDark : Colors.black),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ProfileAvatar(
                          imageUrl: _avatarUrl,
                          initials: _initials ?? 'U',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [

                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            title: 'Recent Searches',
                            action: _recentSearches.isEmpty ? null : 'Clear',
                            onAction: _recentSearches.isEmpty ? null : _clearRecentSearches,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _SearchField(
                                  controller: _searchController,
                                  onClear: () => _searchController.clear(),
                                  onSubmitted: (_) => _onSearch(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: _onSearch,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  child: Text(
                                    'Search',
                                    style: TextStyle(
                                      color: Color(0xFF5B5FEF),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_loadingSearches)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: LinearProgressIndicator(minHeight: 2),
                            )
                          else if (_recentSearches.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: Text(
                                  'No Recent Searches',
                                  style: TextStyle(
                                    color: AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._recentSearches.asMap().entries.map((entry) {
                              final isLast = entry.key == _recentSearches.length - 1;
                              return Column(
                                children: [
                                  _RecentSearchRow(label: entry.value),
                                  if (!isLast)
                                    const Divider(height: 1, thickness: 1),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeaderRow(
                            title: 'Recommended For You',
                            actionLabel: 'More',
                            onTapAction: _openLessons,
                          ),
                          const SizedBox(height: 14),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recommendedLessons.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.05,
                            ),
                            itemBuilder: (context, index) {
                              final item = _recommendedLessons[index];
                              return _RecommendationCard(
                                item: item,
                                onTap: _openLessons,
                                onMore: () => _showRecommendationSheet(item.title),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._challengeCards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChallengeCard(
                          title: card.title,
                          subtitle: card.subtitle,
                          accent: card.accent,
                          questions: card.questions,
                          xp: card.xp,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _XpProgressCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _nameFromMetadata(User? user) {
    final metadata = user?.userMetadata;
    final raw = metadata?['full_name'] ??
        metadata?['name'] ??
        metadata?['display_name'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  String? _avatarFromMetadata(User? user) {
    final metadata = user?.userMetadata;
    final raw = metadata?['avatar_url'] ?? metadata?['picture'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  String _initialsFor(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textPrimaryDark
                : Colors.black,
          ),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                color: Color(0xFF5B5FEF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onTapAction;

  const _SectionHeaderRow({
    required this.title,
    required this.actionLabel,
    required this.onTapAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textPrimaryDark
                : Colors.black,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTapAction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5B5FEF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  const _SearchField({
    required this.controller,
    required this.onClear,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 18,
            color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.8) : const Color(0xFF8E8E93),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : Colors.black,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Search courses...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark.withValues(alpha: 0.8)
                      : const Color(0xFF8E8E93),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.textSecondaryDark.withValues(alpha: 0.8)
                      : const Color(0xFF8E8E93),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  final String label;

  const _RecentSearchRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF8E8E93)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final _RecommendedLesson item;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _RecommendationCard({
    required this.item,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: item.fallbackColor),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onMore,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final int questions;
  final int xp;

  const _ChallengeCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.questions,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final tint = accent.withValues(alpha: 0.10);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '❓ $questions Questions  ✦ +$xp XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Start',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpProgressCard extends StatelessWidget {
  const _XpProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5B5FEF),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Lvl', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
                          Text('7', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total XP', style: TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('3,450', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black)),
                    SizedBox(height: 8),
                    _GradientProgressBar(fraction: 0.7),
                    SizedBox(height: 6),
                    Text('680 XP to Level 8', style: TextStyle(color: Color(0xFF5B5FEF), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE5D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFF7043)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('This Week', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
          const SizedBox(height: 12),
          _WeeklyBars(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7043), size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '7-day streak — Keep it going!',
                  style: TextStyle(color: Color(0xFFFF7043), fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '+100 XP Bonus',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  final double fraction;

  const _GradientProgressBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: 8, color: const Color(0xFFE5E5EA)),
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              height: 8,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B5FEF), Color(0xFF00D4FF)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const heights = [48.0, 62.0, 56.0, 70.0, 28.0, 60.0, 66.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(labels.length, (index) {
        final alpha = index == 4 ? 0.45 : 1.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: heights[index],
              decoration: BoxDecoration(
                color: const Color(0xFF5B5FEF).withValues(alpha: alpha),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            Text(labels[index], style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93))),
          ],
        );
      }),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;

  const _ProfileAvatar({
    required this.imageUrl,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    // Keep a fixed circle size as requested.
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF5B5FEF),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialAvatar(initials: initials),
              )
            : _InitialAvatar(initials: initials),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initials;

  const _InitialAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.surfaceDark : const Color(0xFFE8E6F0),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF5B5FEF),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RecommendedLesson {
  final String title;
  final String imageUrl;
  final Color fallbackColor;

  const _RecommendedLesson({
    required this.title,
    required this.imageUrl,
    required this.fallbackColor,
  });
}

const _recommendedLessons = [
  _RecommendedLesson(
    title: 'Robotics & AI Basics',
    imageUrl: 'https://picsum.photos/seed/robotics-ai/600/600',
    fallbackColor: Color(0xFF5B5FEF),
  ),
  _RecommendedLesson(
    title: 'Embedded Systems Explained',
    imageUrl: 'https://picsum.photos/seed/embedded-systems/600/600',
    fallbackColor: Color(0xFF2ECC8E),
  ),
  _RecommendedLesson(
    title: 'Introduction to UX Design',
    imageUrl: 'https://picsum.photos/seed/ux-design/600/600',
    fallbackColor: Color(0xFFFF7043),
  ),
  _RecommendedLesson(
    title: 'Biotechnology Fundamentals',
    imageUrl: 'https://picsum.photos/seed/biotechnology/600/600',
    fallbackColor: Color(0xFF5B5FEF),
  ),
];

class _ChallengeData {
  final String title;
  final String subtitle;
  final Color accent;
  final int questions;
  final int xp;

  const _ChallengeData({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.questions,
    required this.xp,
  });
}

const _challengeCards = [
  _ChallengeData(
    title: 'Physics Challenge',
    subtitle: 'Quiz card',
    accent: Color(0xFF5B5FEF),
    questions: 10,
    xp: 50,
  ),
  _ChallengeData(
    title: 'Vocabulary Builder',
    subtitle: 'Word skills',
    accent: Color(0xFF2ECC8E),
    questions: 8,
    xp: 35,
  ),
  _ChallengeData(
    title: 'Logic Puzzles',
    subtitle: 'Reasoning drills',
    accent: Color(0xFFFF7043),
    questions: 6,
    xp: 40,
  ),
];
