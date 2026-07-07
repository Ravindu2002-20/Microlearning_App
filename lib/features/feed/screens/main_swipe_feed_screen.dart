import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../core/constants/constants.dart';
import '../../../core/services/session_manager.dart';
import '../../learning/models/lesson_model.dart';
import '../../learning/models/lesson_comment_model.dart';
import '../../learning/repositories/learning_repository.dart';
import '../../learning/services/saved_videos_service.dart';
import '../../profile/screens/profile_screen.dart';
import '../controllers/feed_providers.dart';

class MainSwipeFeedScreen extends ConsumerStatefulWidget {
  final bool isTabActive;
  const MainSwipeFeedScreen({super.key, required this.isTabActive});

  @override
  ConsumerState<MainSwipeFeedScreen> createState() =>
      _MainSwipeFeedScreenState();
}

class _MainSwipeFeedScreenState extends ConsumerState<MainSwipeFeedScreen>
    with WidgetsBindingObserver {
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
    if (!mounted) return;
    // Pause playback when app goes to background.
    setState(() {
      _appIsResumed = state == AppLifecycleState.resumed;
    });
  }

  final LearningRepository _repo = LearningRepository(Supabase.instance.client);
  final SavedVideosService _savedVideosService = SavedVideosService();
  final Map<String, int> _likeCounts = {};
  final Map<String, bool> _isLikedByMe = {};
  final Map<String, int> _commentCounts = {};
  final Map<String, bool> _saved = {};
  final Set<String> _watchedLessonIds = {};
  List<LessonModel> _allLessons = [];
  Set<String> _loadedMetaLessonIds = {};
  bool _metaLoading = false;

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

  void _scheduleMetaLoad(List<LessonModel> lessons) {
    final lessonIds = lessons.map((e) => e.id).toSet();
    if (lessonIds.isEmpty ||
        _metaLoading ||
        lessonIds == _loadedMetaLessonIds) {
      return;
    }
    _loadedMetaLessonIds = lessonIds;
    _metaLoading = true;
    Future.microtask(() async {
      final ids = lessonIds.toList();
      final results = await Future.wait([
        _repo.getLikeCountsForLessons(ids),
        _repo.getMyLikedLessonIds(ids),
        _repo.getCommentCountsForLessons(ids),
      ]);
      if (!mounted) return;
      setState(() {
        _likeCounts
          ..clear()
          ..addAll(results[0] as Map<String, int>);
        _isLikedByMe
          ..clear()
          ..addEntries(
              (results[1] as Set<String>).map((id) => MapEntry(id, true)));
        _commentCounts
          ..clear()
          ..addAll(results[2] as Map<String, int>);
        _metaLoading = false;
      });
    });
  }

  Future<void> _markLessonWatched(LessonModel lesson) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || lesson.id.isEmpty) return;
    if (_watchedLessonIds.contains(lesson.id)) return;
    _watchedLessonIds.add(lesson.id);
    try {
      await _repo.logLessonCompletion(
        userUuid: currentUser.id,
        lessonId: lesson.id,
        score: 0,
      );
    } catch (_) {
      _watchedLessonIds.remove(lesson.id);
    }
  }

  void _openComments(BuildContext context, LessonModel lesson) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CommentsSheet(repo: _repo, lesson: lesson);
      },
    );
  }

  Future<void> _toggleLike(LessonModel lesson) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like/comment')),
      );
      return;
    }

    final prevLiked = _isLikedByMe[lesson.id] ?? false;
    final prevCount = _likeCounts[lesson.id] ?? 0;
    setState(() {
      _isLikedByMe[lesson.id] = !prevLiked;
      _likeCounts[lesson.id] =
          prevLiked ? (prevCount - 1).clamp(0, 1 << 30) : prevCount + 1;
    });

    try {
      final serverLiked = await _repo.toggleLike(lessonId: lesson.id);
      if (!mounted) return;
      if (serverLiked != _isLikedByMe[lesson.id]) {
        setState(() {
          _isLikedByMe[lesson.id] = prevLiked;
          _likeCounts[lesson.id] = prevCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Couldn't update like, please try again")),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLikedByMe[lesson.id] = prevLiked;
        _likeCounts[lesson.id] = prevCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update like, please try again")),
      );
    }
  }

  Future<void> _toggleSave(LessonModel lesson) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save videos')),
      );
      return;
    }
    final isSaved = !(_saved[lesson.id] ?? false);
    setState(() {
      _saved[lesson.id] = isSaved;
    });
    try {
      if (isSaved) {
        await _savedVideosService.saveVideo(currentUser.id, lesson);
      } else {
        await _savedVideosService.removeVideo(currentUser.id, lesson.id);
      }
      ref.read(savedVideosRefreshProvider.notifier).state++;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saved[lesson.id] = !isSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update saved videos")),
      );
      return;
    }
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
    final parts =
        rawName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final initials = parts.take(2).map((e) => e.isNotEmpty ? e[0] : '').join();
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
            _scheduleMetaLoad(lessons);
            if (lessons.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || lessons.isEmpty) return;
                final activeIndex = _activeIndex.clamp(0, lessons.length - 1);
                _markLessonWatched(lessons[activeIndex]);
              });
            }

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
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    physics: const SnappyPagePhysics(),
                    scrollDirection: Axis.vertical,
                    itemCount: lessons.length,
                    onPageChanged: (index) {
                      setState(() {
                        _activeIndex = index;
                      });
                      _markLessonWatched(lessons[index]);
                    },
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final cardGradient = isDark
                          ? _cardGradients[index % _cardGradients.length]
                          : _cardGradientsLight[
                              index % _cardGradientsLight.length];

                      final effectiveIsActive = widget.isTabActive &&
                          _appIsResumed &&
                          index == _activeIndex;

                      return IgnorePointer(
                        child: _FeedVideoLayer(
                          key: ValueKey(lesson.id),
                          isActive: effectiveIsActive,
                          lesson: lesson,
                          cardGradient: cardGradient,
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final activeIndex =
                          _activeIndex.clamp(0, lessons.length - 1);
                      final lesson = lessons[activeIndex];
                      return _FeedOverlayLayer(
                        lesson: lesson,
                        isLiked: _isLikedByMe[lesson.id] ?? false,
                        isSaved: _saved[lesson.id] ?? false,
                        likeCount:
                            _formatLikeCount(_likeCounts[lesson.id] ?? 0),
                        commentCount: _commentCounts[lesson.id] ?? 0,
                        avatarUrl: user == null ? null : _avatarUrl(user),
                        initials: user == null ? 'U' : _initialsFromUser(user),
                        onLike: () => _toggleLike(lesson),
                        onSave: () => _toggleSave(lesson),
                        onShare: () => _shareLesson(lesson),
                        onComment: () => _openComments(context, lesson),
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

class _FeedVideoLayer extends StatefulWidget {
  final LessonModel lesson;
  final Gradient cardGradient;
  final bool isActive;

  const _FeedVideoLayer({
    super.key,
    required this.lesson,
    required this.cardGradient,
    required this.isActive,
  });

  @override
  State<_FeedVideoLayer> createState() => _FeedVideoLayerState();
}

class _FeedVideoLayerState extends State<_FeedVideoLayer> {
  static const double kFeedTopGap = 6.0;
  static const double kFeedBottomGap = 6.0;

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
  void didUpdateWidget(covariant _FeedVideoLayer oldWidget) {
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
      _videoError =
          'This video could not be loaded. It may have been moved or removed.';
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
                    Container(color: Colors.black),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: kFeedTopGap,
                        bottom: kFeedBottomGap,
                      ),
                      child: player,
                    ),
                  ],
                );
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: kFeedTopGap,
                      bottom: kFeedBottomGap,
                    ),
                    child: LayoutBuilder(
                      builder: (context, videoConstraints) {
                        final width = videoConstraints.maxWidth;
                        final height = videoConstraints.maxHeight;
                        return FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: width,
                            height: height,
                            child: ClipRect(child: player),
                          ),
                        );
                      },
                    ),
                  ),
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
                    Container(color: Colors.black),
                    if ((lesson.thumbnailUrl ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: kFeedTopGap,
                          bottom: kFeedBottomGap,
                        ),
                        child: Image.network(
                          lesson.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              decoration:
                                  BoxDecoration(gradient: widget.cardGradient)),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(
                          top: kFeedTopGap,
                          bottom: kFeedBottomGap,
                        ),
                        child: Container(
                          decoration:
                              BoxDecoration(gradient: widget.cardGradient),
                        ),
                      ),
                  ],
                );
              }
              if (_controller!.value.hasError) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Colors.black),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: kFeedTopGap,
                        bottom: kFeedBottomGap,
                      ),
                      child: Container(
                        decoration:
                            BoxDecoration(gradient: widget.cardGradient),
                      ),
                    ),
                    _buildUnavailableOverlay(),
                  ],
                );
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: kFeedTopGap,
                      bottom: kFeedBottomGap,
                    ),
                    child: SmartFitVideo(
                      videoWidth: _controller!.value.size.width,
                      videoHeight: _controller!.value.size.height,
                      fit: BoxFit.cover,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ],
              );
            },
          )
        else
          Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black),
              Padding(
                padding: const EdgeInsets.only(
                  top: kFeedTopGap,
                  bottom: kFeedBottomGap,
                ),
                child: Container(
                  decoration: BoxDecoration(gradient: widget.cardGradient),
                ),
              ),
            ],
          ),
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
}

class _FeedOverlayLayer extends StatelessWidget {
  final LessonModel lesson;
  final bool isLiked;
  final bool isSaved;
  final String likeCount;
  final int commentCount;
  final String? avatarUrl;
  final String initials;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback? onAvatarTap;
  final VoidCallback onSearch;

  const _FeedOverlayLayer({
    required this.lesson,
    required this.isLiked,
    required this.isSaved,
    required this.likeCount,
    required this.commentCount,
    required this.avatarUrl,
    required this.initials,
    required this.onLike,
    required this.onSave,
    required this.onShare,
    required this.onComment,
    required this.onAvatarTap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final navBarClearance =
        AppDimensions.navHeight + MediaQuery.of(context).padding.bottom;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
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
                    onTap: onAvatarTap,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
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
                  const IgnorePointer(
                    child: Text(
                      'For You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onSearch,
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
          bottom: navBarClearance + 16.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: likeCount,
                color: isLiked ? Colors.red : Colors.white,
                onTap: onLike,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.chat_bubble_rounded,
                label: commentCount > 0 ? 'Comment ($commentCount)' : 'Comment',
                onTap: onComment,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: onShare,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: 'Save',
                color: isSaved ? Colors.amber : Colors.white,
                onTap: onSave,
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 80,
          bottom: navBarClearance + 12.0,
          child: IgnorePointer(
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
                if (lesson.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    lesson.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.25,
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
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
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
            child: const Icon(Icons.play_circle_outline, color: Colors.white),
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

class _CommentsSheet extends StatefulWidget {
  final LearningRepository repo;
  final LessonModel lesson;

  const _CommentsSheet({required this.repo, required this.lesson});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  bool _sending = false;
  bool _isAdmin = false;
  List<LessonCommentModel> _comments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    final results = await Future.wait([
      widget.repo.fetchComments(lessonId: widget.lesson.id),
      widget.repo.isAdmin(user?.id ?? ''),
    ]);
    if (!mounted) return;
    setState(() {
      _comments = results[0] as List<LessonCommentModel>;
      _isAdmin = results[1] as bool;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like/comment')),
      );
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    final created = await widget.repo.addComment(
      lessonId: widget.lesson.id,
      content: text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Couldn't post comment, please try again")),
      );
      return;
    }

    setState(() {
      _comments = [created, ..._comments];
      _controller.clear();
    });
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _deleteComment(LessonCommentModel comment) async {
    final ok = await widget.repo.deleteComment(commentId: comment.id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't delete comment")),
      );
      return;
    }
    setState(() {
      _comments.removeWhere((c) => c.id == comment.id);
    });
  }

  String _timeAgo(DateTime? when) {
    if (when == null) return '';
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet. Be the first to comment!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: false,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final canDelete =
                              comment.userId == currentUser?.id || _isAdmin;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: comment.authorAvatarUrl !=
                                          null
                                      ? NetworkImage(comment.authorAvatarUrl!)
                                      : null,
                                  backgroundColor: Colors.white24,
                                  child: comment.authorAvatarUrl == null
                                      ? Text(
                                          (comment.authorName ?? 'U')
                                              .trim()
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                comment.authorName ?? 'User',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _timeAgo(comment.createdAt),
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (canDelete) ...[
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () =>
                                                    _deleteComment(comment),
                                                child: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: Colors.white54,
                                                  size: 18,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          comment.content,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
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
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class SmartFitVideo extends StatelessWidget {
  final double videoWidth;
  final double videoHeight;
  final BoxFit? fit;
  final Widget child;

  const SmartFitVideo({
    super.key,
    required this.videoWidth,
    required this.videoHeight,
    this.fit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;
        if (screenW <= 0 ||
            screenH <= 0 ||
            videoWidth <= 0 ||
            videoHeight <= 0) {
          return Container(color: Colors.black, child: child);
        }

        final videoAspect = videoWidth / videoHeight;
        final screenAspect = screenW / screenH;
        final aspectDiff = (videoAspect - screenAspect).abs() / screenAspect;
        final resolvedFit =
            fit ?? (aspectDiff <= 0.15 ? BoxFit.cover : BoxFit.contain);

        return Container(
          color: Colors.black,
          child: Center(
            child: FittedBox(
              fit: resolvedFit,
              child: SizedBox(
                width: videoWidth,
                height: videoHeight,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class SnappyPagePhysics extends PageScrollPhysics {
  const SnappyPagePhysics({super.parent});

  static const double _pageTurnThreshold = 0.08;

  @override
  SnappyPagePhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyPagePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.8,
        stiffness: 220.0,
        damping: 24.0,
      );

  @override
  double get minFlingVelocity => 180.0;

  @override
  double get minFlingDistance => 4.0;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position is! PageMetrics || position.viewportDimension <= 0) {
      return super.createBallisticSimulation(position, velocity);
    }

    final page = position.page ?? position.pixels / position.viewportDimension;
    final nearestPage = page.roundToDouble();
    var targetPage = nearestPage;

    if (velocity.abs() >= minFlingVelocity) {
      targetPage = velocity < 0 ? page.floorToDouble() : page.ceilToDouble();
    } else {
      final pageDelta = page - nearestPage;
      if (pageDelta.abs() >= _pageTurnThreshold) {
        targetPage = pageDelta > 0 ? nearestPage + 1 : nearestPage - 1;
      }
    }

    final targetPixels = (targetPage * position.viewportDimension).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if ((targetPixels - position.pixels).abs() <
        toleranceFor(position).distance) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: toleranceFor(position),
    );
  }
}
