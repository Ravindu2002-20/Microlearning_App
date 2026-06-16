import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';
import '../../../core/services/session_manager.dart';
import '../../learning/models/lesson_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../controllers/feed_providers.dart';

class MainSwipeFeedScreen extends ConsumerStatefulWidget {
  const MainSwipeFeedScreen({super.key});

  @override
  ConsumerState<MainSwipeFeedScreen> createState() =>
      _MainSwipeFeedScreenState();
}

class _MainSwipeFeedScreenState extends ConsumerState<MainSwipeFeedScreen> {
  final PageController _pageController = PageController();

  final Map<String, bool> _liked = {};
  final Map<String, bool> _saved = {};
  List<LessonModel> _allLessons = [];

  static final List<LinearGradient> _cardGradients = [
    const LinearGradient(
      colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF0f3460), Color(0xFF533483)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF2d1b69), Color(0xFF11998e)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF141e30), Color(0xFF243b55)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF200122), Color(0xFF6f0000)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static final List<LinearGradient> _cardGradientsLight = [
    const LinearGradient(
      colors: [Color(0xFFe8eaf6), Color(0xFFc5cae9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFe3f2fd), Color(0xFFbbdefb)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFf3e5f5), Color(0xFFe1bee7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFe8f5e9), Color(0xFFc8e6c9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFfff3e0), Color(0xFFffe0b2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _LessonSearchDelegate(lessons: _allLessons),
    );
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'No comments yet.\nBe the first to comment!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  children: [
                    const Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleLike(LessonModel lesson) {
    setState(() {
      _liked[lesson.id] = !(_liked[lesson.id] ?? false);
    });
  }

  void _toggleSave(LessonModel lesson) {
    final isSaved = !(_saved[lesson.id] ?? false);
    setState(() {
      _saved[lesson.id] = isSaved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved ? 'Saved to your profile' : 'Removed from saved',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareLesson(LessonModel lesson) {
    final link = 'https://microlearn.app/lesson/${lesson.id}';
    Share.share(
      'Check out this lesson on MicroLearn: ${lesson.title}\n$link',
      subject: lesson.title,
    );
  }

  String _formatLikeCount(int baseCount) {
    if (baseCount >= 1000000) {
      return '${(baseCount / 1000000).toStringAsFixed(baseCount % 1000000 == 0 ? 0 : 1)}M';
    }
    if (baseCount >= 1000) {
      return '${(baseCount / 1000).toStringAsFixed(baseCount % 1000 == 0 ? 0 : 1)}K';
    }
    return baseCount.toString();
  }

  String _initialsFromUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final rawName = (metadata['full_name'] as String?) ??
        (metadata['name'] as String?) ??
        (user.email ?? 'U');
    final parts = rawName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final initials = parts
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join();
    return initials.isEmpty ? 'U' : initials.toUpperCase();
  }

  String? _avatarUrl(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return (metadata['avatar_url'] as String?) ??
        (metadata['avatarUrl'] as String?) ??
        user.userMetadata?['picture'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final contextAsync = ref.watch(contextStateStreamProvider);
    final user = ref.watch(sessionUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return contextAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Center(
          child: Text(
            'We could not load the lessons feed.',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
      data: (currentContext) {
        final lessonsAsync = ref.watch(
          adaptiveLessonFeedProvider(currentContext),
        );

        return lessonsAsync.when(
          loading: () => Scaffold(
            backgroundColor: isDark ? Colors.black : Colors.white,
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, st) => Scaffold(
            backgroundColor: isDark ? Colors.black : Colors.white,
            body: Center(
              child: Text(
                'Failed to load lessons from the server.',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          data: (lessons) {
            _allLessons = lessons;

            if (lessons.isEmpty) {
              return Scaffold(
                backgroundColor: isDark ? Colors.black : Colors.white,
                body: const Center(
                  child: Text(
                    'No lessons available',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              );
            }

            return Scaffold(
              backgroundColor: isDark ? Colors.black : Colors.white,
              extendBodyBehindAppBar: true,
              appBar: null,
              body: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final isLiked = _liked[lesson.id] ?? false;
                      final isSaved = _saved[lesson.id] ?? false;
                      final likeCount = _formatLikeCount(1200 + (index * 73));
                      final cardGradient = isDark
                          ? _cardGradients[index % _cardGradients.length]
                          : _cardGradientsLight[index % _cardGradientsLight.length];
                      final avatarUrl = user == null ? null : _avatarUrl(user);
                      final initials =
                          user == null ? 'U' : _initialsFromUser(user);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(decoration: BoxDecoration(gradient: cardGradient)),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.12),
                                      ),
                                    ),
                                    child: Text(
                                      lesson.category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    lesson.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    lesson.content.isNotEmpty
                                        ? lesson.content
                                        : lesson.description,
                                    textAlign: TextAlign.center,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 15,
                                      height: 1.45,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: user == null
                                          ? null
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ProfileScreen(),
                                                ),
                                              );
                                            },
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundImage: avatarUrl != null
                                            ? NetworkImage(avatarUrl)
                                            : null,
                                        backgroundColor:
                                            Colors.white.withValues(alpha: 0.18),
                                        child: avatarUrl == null
                                            ? Text(
                                                initials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Text(
                                      'For You',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => _openSearch(context),
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.black.withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.search_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            bottom: 120,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ActionButton(
                                  icon: isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  label: likeCount,
                                  color: isLiked ? Colors.red : Colors.white,
                                  onTap: () => _toggleLike(lesson),
                                ),
                                const SizedBox(height: 20),
                                _ActionButton(
                                  icon: Icons.chat_bubble_rounded,
                                  label: 'Comment',
                                  onTap: () => _openComments(context),
                                ),
                                const SizedBox(height: 20),
                                _ActionButton(
                                  icon: Icons.share_rounded,
                                  label: 'Share',
                                  onTap: () => _shareLesson(lesson),
                                ),
                                const SizedBox(height: 20),
                                _ActionButton(
                                  icon: isSaved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  label: 'Save',
                                  color: isSaved ? Colors.amber : Colors.white,
                                  onTap: () => _toggleSave(lesson),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 80,
                            bottom: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    lesson.category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  lesson.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lesson.description,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 250,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.75),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonSearchDelegate extends SearchDelegate<LessonModel?> {
  final List<LessonModel> lessons;

  _LessonSearchDelegate({required this.lessons});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A1A)),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white38),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = query.isEmpty
        ? lessons
        : lessons
            .where(
              (l) =>
                  l.title.toLowerCase().contains(query.toLowerCase()) ||
                  l.category.toLowerCase().contains(query.toLowerCase()) ||
                  l.description.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No lessons found',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final lesson = results[index];
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.play_circle_outline, color: Colors.white),
          ),
          title: Text(
            lesson.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            lesson.category,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          onTap: () => close(context, lesson),
        );
      },
    );
  }
}
