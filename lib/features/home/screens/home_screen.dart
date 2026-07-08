import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';

import '../../../core/services/session_manager.dart';
import '../../../features/feed/controllers/feed_providers.dart';
import '../../quiz/screens/quiz_play_screen.dart';
import '../../quiz/screens/quiz_lesson_picker_sheet.dart';
import '../services/video_recommendation_service.dart';
import '../../learning/models/lesson_model.dart';
import '../../learning/repositories/xp_calculation.dart';
import '../../learning/repositories/learning_repository.dart';

final videoRecommendationAsyncProvider = FutureProvider.family<List<LessonModel>, String>((ref, userId) async {
  final svc = ref.read(videoRecommendationServiceProvider);
  return svc.recommendForUser(userUuid: userId, topN: 4);
});

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenLessons;
  final VoidCallback onOpenProfileTab;

  const HomeScreen({
    super.key,
    required this.onOpenLessons,
    required this.onOpenProfileTab,
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
final userAsync = ref.read(sessionUserProvider);
    final user = userAsync.asData?.value;


    final nameFromMeta = _nameFromMetadata(user);
    final avatarFromMeta = _avatarFromMetadata(user);

    String? avatarUrl = avatarFromMeta;
    String? displayName = nameFromMeta;

    if (user != null) {
      try {
          final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name, username, avatar_url')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          final fullName = (profile['full_name'] as String?)?.trim();
          final username = (profile['username'] as String?)?.trim();

          if (fullName != null && fullName.isNotEmpty) {
            displayName = fullName;
          } else if (username != null && username.isNotEmpty) {
            displayName = username;
          }

          final avatarCandidate = (profile['avatar_url'] as String?)?.trim();
          avatarUrl = (avatarCandidate != null && avatarCandidate.isNotEmpty)
              ? avatarCandidate
              : avatarUrl;
        }
      } catch (_) {
        // Use auth metadata fallback.
      }
    }

    if (!mounted) return;
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

    // Update recent searches immediately (keep full history).
    setState(() {
      _recentSearches = [
        query,
        ..._recentSearches.where(
          (item) => item.toLowerCase() != query.toLowerCase(),
        ),
      ];
      _loadingSearches = true;
    });

    await _persistRecentSearches();

    try {
      // Best-effort backend search.
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
    } finally {
      if (mounted) {
        setState(() {
          _loadingSearches = false;
        });
      }
    }

  }

  Future<void> _clearRecentSearches() async {
    setState(() {
      _recentSearches = [];
    });
    await _persistRecentSearches();
  }

  Future<void> _onRecentSearchTap(String query) async {
    // Put tapped search at the top (dedupe) and keep full history.
    setState(() {
      _recentSearches = [
        query,
        ..._recentSearches.where(
          (item) => item.toLowerCase() != query.toLowerCase(),
        ),
      ];
      _searchController.text = query;
      _loadingSearches = true;
    });

    await _persistRecentSearches();

    // Run search again.
    await _onSearch();
  }

  Future<void> _showAllRecentSearches() async {
    // Always read from persistence so "View All Searches" reflects the full history,
    // not only what is currently loaded in-memory.
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getStringList(_recentSearchKey) ?? <String>[];

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.75;
        return SafeArea(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondaryDark.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'All Searches',
                        style: TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          setState(() => _recentSearches = []);
                          await _persistRecentSearches();
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            color: Color(0xFF5B5FEF),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: all.isEmpty
                      ? const Center(
                          child: Text(
                            'No searches yet.',
                            style: TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: all.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
                          itemBuilder: (context, index) {
                            final q = all[index];
                            return ListTile(
                              leading: const Icon(Icons.access_time_rounded),
                              title: Text(
                                q,
                                style: const TextStyle(
                                  color: AppColors.textPrimaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onTap: () async {
                                Navigator.of(ctx).pop();
                                await _onRecentSearchTap(q);
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }



  void _openLessons() => widget.onOpenLessons();



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
                    borderRadius: BorderRadius.circular(2),
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
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final userName = _displayName ?? 'Learner';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Header overflow fix:
    // Keep header content height constant and apply the safe-area inset exactly once.
    final topInset = MediaQuery.of(context).padding.top;
    const headerContentHeight = 65.0;
    final headerHeight = headerContentHeight + topInset;

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: headerHeight,
              width: double.infinity,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topInset,
                    left: 20,
                    right: 20,
                    bottom: 10,
                  ),
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
                                color: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.color ??
                                    (isDark
                                        ? AppColors.textPrimaryDark
                                        : Colors.black),
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
                                color: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.color ??
                                    (isDark
                                        ? AppColors.textPrimaryDark
                                        : Colors.black),
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
                      GestureDetector(
                        onTap: () {
                          // Switch to Profile tab.
                          // (MainAppShell must own/hold the tab state.)
                          // For now, push a profile route so the user can see their data.
                          // Switch to Profile tab inside MainAppShell.
                        widget.onOpenProfileTab();
                        },

                        child: _ProfileAvatar(
                          imageUrl: _avatarUrl,
                          initials: _initials ?? 'U',
                        ),
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
                          action:
                              _recentSearches.isEmpty ? null : 'Clear',
                          onAction: _recentSearches.isEmpty
                              ? null
                              : _clearRecentSearches,
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                  
                                ),
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
                          ..._recentSearches
                              .take(3)
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            final displayed = _recentSearches.take(3).toList();
                            final isLast = entry.key == displayed.length - 1;
                            final q = entry.value;

                            return Column(
                              children: [
                                _RecentSearchRow(
                                  label: q,
                                  onTap: () => _onRecentSearchTap(q),
                                ),
                                if (!isLast)
                                  const Divider(height: 1, thickness: 1),
                              ],
                            );
                          }),


                        if (!_loadingSearches && _recentSearches.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _showAllRecentSearches,
                            child: const Center(
                              child: Text(
                                'View All Searches',
                                style: TextStyle(
                                  color: Color(0xFF5B5FEF),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                        Consumer(builder: (context, ref, _) {
                          final streamUser = ref.watch(sessionUserProvider).maybeWhen(
                                data: (u) => u,
                                orElse: () => null,
                              );
                          final user = streamUser ?? Supabase.instance.client.auth.currentUser;

                          if (user == null) {
                            return const SizedBox.shrink();
                          }

                          final recAsync = ref.watch(videoRecommendationAsyncProvider(user.id));

                          return recAsync.when(
                            loading: () => GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 4,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.05,
                              ),
                              itemBuilder: (_, __) {
                                return const _RecommendationSkeleton();
                              },
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (items) {
                              if (items.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final visibleItems = items.take(4).toList();

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: visibleItems.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                                itemBuilder: (context, index) {
                                  final item = visibleItems[index];
                                  return _RecommendationCard(
                                    item: item,
                                    onTap: _openLessons,
                                    onMore: () => _showRecommendationSheet(item.title),
                                  );
                                },
                              );
                            },
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
                        const _SectionTitle(title: 'Quiz'),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B5FEF).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5B5FEF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.quiz_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Ready for a quick quiz?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () async {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) {
                                      return FractionallySizedBox(
                                        heightFactor: 0.7,
                                        child: QuizLessonPickerSheet(
                                          onPicked: (lesson) {
                                            Navigator.of(ctx).pop();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => QuizPlayScreen(
                                                  lesson: lesson,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),

                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5B5FEF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Start',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _XpProgressCard(),
                ],
              ),
            ),
          ],
        ),
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
        color: const Color.fromARGB(255, 81, 85, 99),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark.withValues(alpha: 0.8)
                : const Color(0xFF8E8E93),
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
                isDense: true,
                hintText: 'Search courses...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark.withValues(alpha: 0.8)
                      : const Color(0xFF8E8E93),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
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
  final VoidCallback onTap;

  const _RecentSearchRow({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 18, color: Color(0xFF8E8E93)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _RecommendationCard extends StatelessWidget {
  final LessonModel item;

  final VoidCallback onTap;
  final VoidCallback onMore;

  const _RecommendationCard({
    required this.item,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      item.thumbnailUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF5B5FEF),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: onMore,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_vert_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimaryDark : Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category.isNotEmpty ? item.category : 'Video',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5B5FEF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            child:
                const Icon(Icons.quiz_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : Colors.black,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Start',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpProgressCard extends StatefulWidget {
  const _XpProgressCard();

  @override
  State<_XpProgressCard> createState() => _XpProgressCardState();
}

class _XpProgressCardState extends State<_XpProgressCard> {
  Future<Map<String, dynamic>>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return {
        'totalXp': 0,
        'streak': 0,
        'level': 1,
        'xpToNextLevel': XpCalculation.xpPerLevel,
      };
    }

    return LearningRepository(Supabase.instance.client).fetchUserStatsFromProgress(
      userUuid: user.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : Colors.black;

    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        final totalXp = (data['totalXp'] as int?) ?? 0;
        final streak = (data['streak'] as int?) ?? 0;
        final level = (data['level'] as int?) ?? XpCalculation.calculateLevel(totalXp);
        final xpToNextLevel = (data['xpToNextLevel'] as int?) ?? XpCalculation.xpToNextLevel(totalXp);
        final fraction = xpToNextLevel <= 0
            ? 1.0
            : (totalXp % XpCalculation.xpPerLevel) / XpCalculation.xpPerLevel;

        final nextLevelText = xpToNextLevel <= 0
            ? 'Level up complete'
            : '$xpToNextLevel XP to Level ${level + 1}';

        return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
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
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Lvl',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total XP',
                      style: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalXp.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _GradientProgressBar(fraction: fraction.clamp(0.0, 1.0)),
                    const SizedBox(height: 6),
                    Text(
                      nextLevelText,
                      style: const TextStyle(
                        color: Color(0xFF5B5FEF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFF7043),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'This Week',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          const _WeeklyBars(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFFF7043),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  streak >= 7
                      ? '7-day streak — Bonus unlocked!'
                      : '7-day streak — Keep it going!',
                  style: const TextStyle(
                    color: Color(0xFFFF7043),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  streak >= 7 ? '+${XpCalculation.streakBonusXp} XP Bonus' : '$streak day streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
      },
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
  const _WeeklyBars();

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
            const Text(
              // visual only
              '',
              style: TextStyle(fontSize: 10, color: Color(0xFF8E8E93)),
            ),
            Text(
              labels[index],
              style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)),
            ),
          ],
        );
      }),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;

  const _ProfileAvatar({required this.imageUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
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

class _RecommendationSkeleton extends StatelessWidget {
  const _RecommendationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white10
            : Colors.black12,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

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

