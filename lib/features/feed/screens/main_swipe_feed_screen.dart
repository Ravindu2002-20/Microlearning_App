import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../core/constants/constants.dart';
import '../../../core/services/session_manager.dart';
import '../../learning/models/lesson_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../controllers/feed_providers.dart';

class MainSwipeFeedScreen extends ConsumerStatefulWidget {
  final bool isTabActive;
  const MainSwipeFeedScreen({super.key, required this.isTabActive});

  @override
  ConsumerState<MainSwipeFeedScreen> createState() =>
      _MainSwipeFeedScreenState();
}

class _MainSwipeFeedScreenState extends ConsumerState<MainSwipeFeedScreen> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _activeIndex = 0;
  bool _appIsResumed = true;

  @override
  void initState() {
    super.initState();
    // Ensure the first page is aligned with the initial active index.
    _activeIndex = 0;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause playback when app goes to background.
    setState(() {
      _appIsResumed = state == AppLifecycleState.resumed;
    });
  }



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
    WidgetsBinding.instance.removeObserver(this);
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
    final userAsync = ref.watch(sessionUserProvider);
    final user = userAsync.asData?.value;

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
                    onPageChanged: (index) {
                      setState(() {
                        _activeIndex = index;
                      });
                    },
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

                      final effectiveIsActive = widget.isTabActive &&
                          _appIsResumed &&
                          index == _activeIndex;


                      return _FeedCard(
                        isActive: effectiveIsActive,
                        lesson: lesson,
                        isLiked: isLiked,
                        isSaved: isSaved,
                        likeCount: likeCount,
                        cardGradient: cardGradient,
                        avatarUrl: avatarUrl,
                        initials: initials,
                        onLike: () => _toggleLike(lesson),
                        onSave: () => _toggleSave(lesson),
                        onShare: () => _shareLesson(lesson),
                        onComment: () => _openComments(context),
                        onAvatarTap: user == null
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                );
                              },
                        onSearch: () => _openSearch(context),
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

class _FeedCard extends StatefulWidget {
  final LessonModel lesson;
  final bool isLiked;
  final bool isSaved;
  final String likeCount;
  final Gradient cardGradient;
  final String? avatarUrl;
  final String initials;
  final bool isActive;

  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback? onAvatarTap;
  final VoidCallback onSearch;

  const _FeedCard({
    required this.lesson,
    required this.isLiked,
    required this.isSaved,
    required this.likeCount,
    required this.cardGradient,
    required this.avatarUrl,
    required this.initials,
    required this.isActive,
    required this.onLike,
    required this.onSave,
    required this.onShare,
    required this.onComment,
    required this.onAvatarTap,
    required this.onSearch,
  });

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  bool _usingVideo = false;
  YoutubePlayerController? _youtubeController;
  bool _usingYoutube = false;
  String? _videoError;

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant _FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson.id != widget.lesson.id ||
        oldWidget.lesson.videoUrl != widget.lesson.videoUrl) {
      _disposeVideo();
      _initVideo();
      return;
    }

    if (oldWidget.isActive != widget.isActive) {
      _syncPlaybackWithActiveState();
    }
  }

  void _syncPlaybackWithActiveState() {
    final shouldPlay = widget.isActive;
    if (_isPlaying == shouldPlay) return;
    _isPlaying = shouldPlay;

    if (_usingVideo && _controller != null) {
      if (shouldPlay) {
        _controller!.setVolume(1.0);
        _controller!.play();
      } else {
        _controller!.pause();
        _controller!.seekTo(Duration.zero);
      }
    }

    // YouTube player: pause/play via controller.
    if (_usingYoutube && _youtubeController != null) {
      if (shouldPlay) {
        _youtubeController!.play();
      } else {
        _youtubeController!.pause();
      }
    }
  }

  Future<void> _initVideo() async {
    final videoUrl = widget.lesson.videoUrl?.trim();
    if (videoUrl == null || videoUrl.isEmpty) return;


    try {
      _videoError = null;
      if (videoUrl.startsWith('yt:')) {
        final videoId = videoUrl.substring(3).trim();
        if (videoId.isEmpty) return;

        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            loop: true,
          ),
        );
        if (mounted) {
          setState(() {
            _usingYoutube = true;
          });
          _syncPlaybackWithActiveState();
        }
        return;
      }

      final uri = Uri.tryParse(videoUrl);
      if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        return;
      }

      final controller = VideoPlayerController.networkUrl(uri);
      final initFuture = controller.initialize();
      setState(() {
        _controller = controller;
        _initializeFuture = initFuture;
      });

      await initFuture;
      controller.setLooping(true);
      controller.setVolume(1.0);
      if (mounted) {
        setState(() {
          _controller = controller;
          _initializeFuture = initFuture;
          _usingVideo = true;
        });
        _syncPlaybackWithActiveState();
      }
    } catch (_) {
      _disposeVideo();
      _videoError = 'This video could not be loaded. It may have been moved or removed.';
    }
  }

  void _disposeVideo() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _initializeFuture = null;
    _usingVideo = false;

    _youtubeController?.pause();
    _youtubeController?.dispose();
    _youtubeController = null;
    _usingYoutube = false;

    _isPlaying = false;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

    if (_usingYoutube && _youtubeController != null) {
      // youtube_player_flutter renders with an internal fixed aspect ratio,
      // which can leave letterboxed bars on tall screens. Force a TikTok-style
      // cover crop via BoxFit.cover.
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primaryDark,
          progressColors: ProgressBarColors(
            playedColor: AppColors.primaryDark,
            handleColor: AppColors.primaryDark,
            bufferedColor: AppColors.primaryDark.withValues(alpha: 0.3),
            backgroundColor: Colors.white24,
          ),
        ),
        builder: (context, player) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              if (w == 0 || h == 0) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    player,
                    _buildOverlayContent(lesson),
                  ],
                );
              }

              // YouTube embed is effectively 16:9; scale it so it covers the
              // available area, then crop overflow.
              final scaledHeight = (w * 9 / 16);
              final scale = h / scaledHeight;
              final targetWidth = w * scale;
              return Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: targetWidth,
                      height: h,
                      child: ClipRect(
                        child: player,
                      ),
                    ),
                  ),
                  _buildOverlayContent(lesson),
                ],
              );
            },
          );
        },
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_usingVideo && _controller != null)
          FutureBuilder<void>(
            future: _initializeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if ((lesson.thumbnailUrl ?? '').isNotEmpty)
                      Image.network(
                        lesson.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(decoration: BoxDecoration(gradient: widget.cardGradient)),
                      )
                    else
                      Container(decoration: BoxDecoration(gradient: widget.cardGradient)),
                    Container(color: Colors.black.withValues(alpha: 0.08)),
                  ],
                );
              }
              if (_controller!.value.hasError) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(decoration: BoxDecoration(gradient: widget.cardGradient)),
                    _buildUnavailableOverlay(),
                  ],
                );
              }
              return FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              );
            },
          )
        else
          Container(decoration: BoxDecoration(gradient: widget.cardGradient)),
        _buildOverlayContent(lesson),
      ],
    );
  }

  Widget _buildUnavailableOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline_rounded,
                  color: Colors.white70, size: 34),
              const SizedBox(height: 8),
              const Text(
                'Video unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _videoError ?? 'This lesson video could not be loaded.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayContent(LessonModel lesson) {
    return Stack(
      fit: StackFit.expand,
      children: [

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
                    onTap: widget.onAvatarTap,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: widget.avatarUrl != null
                          ? NetworkImage(widget.avatarUrl!)
                          : null,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: widget.avatarUrl == null
                          ? Text(
                              widget.initials,
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
                    onTap: widget.onSearch,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
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
                icon: widget.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: widget.likeCount,
                color: widget.isLiked ? Colors.red : Colors.white,
                onTap: widget.onLike,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.chat_bubble_rounded,
                label: 'Comment',
                onTap: widget.onComment,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: widget.onShare,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: widget.isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: 'Save',
                color: widget.isSaved ? Colors.amber : Colors.white,
                onTap: widget.onSave,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: 0.8),
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
                ],
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
                (lesson.content.isNotEmpty ? lesson.content : lesson.description)
                    .trim(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
                maxLines: 1,
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
