// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/lesson_model.dart';

class YoutubeVideosPage extends StatefulWidget {
  const YoutubeVideosPage({super.key});

  @override
  State<YoutubeVideosPage> createState() => _YoutubeVideosPageState();
}

class _YoutubeVideosPageState extends State<YoutubeVideosPage> {
  late final Future<List<LessonModel>> _lessonsFuture;
  late final FeedVideoManager _videoManager;
  final PageController _pageController = PageController();
  final ValueNotifier<int> _activeIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _videoManager = FeedVideoManager();
    _lessonsFuture = _loadLessons();
  }

  Future<List<LessonModel>> _loadLessons() async {
    final response = await Supabase.instance.client
        .from('lessons')
        .select('id, title, description, category, video_url, created_at')
        .order('created_at', ascending: false)
        .limit(100);

    final lessons = (response as List<dynamic>)
        .map((row) => LessonModel.fromJson(Map<String, dynamic>.from(row)))
        .where(_isVideoLesson)
        .toList();

    await _videoManager.setLessons(lessons);
    return lessons;
  }

  bool _isVideoLesson(LessonModel lesson) {
    final videoUrl = lesson.videoUrl?.trim() ?? '';
    return videoUrl.isNotEmpty &&
        (videoUrl.startsWith('yt:') ||
            videoUrl.startsWith('http') ||
            videoUrl.startsWith('https'));
  }

  @override
  void dispose() {
    _activeIndex.dispose();
    _pageController.dispose();
    _videoManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final text = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Lesson Videos'),
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
      ),
      body: FutureBuilder<List<LessonModel>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final lessons = snapshot.data ?? const <LessonModel>[];
          if (lessons.isEmpty) {
            return const Center(child: Text('No video lessons found.'));
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: _activeIndex,
                builder: (context, activeIndex, _) {
                  _videoManager.updateWindow(activeIndex);
                  return PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: lessons.length,
                    onPageChanged: (index) => _activeIndex.value = index,
                    itemBuilder: (context, index) {
                      return LessonVideoWidget(
                        key: ValueKey(lessons[index].id),
                        manager: _videoManager,
                        lesson: lessons[index],
                        isActive: index == activeIndex,
                      );
                    },
                  );
                },
              ),
              ValueListenableBuilder<int>(
                valueListenable: _activeIndex,
                builder: (context, activeIndex, _) {
                  final lesson =
                      lessons[activeIndex.clamp(0, lessons.length - 1)];
                  return LessonOverlayWidget(
                    lesson: lesson,
                    child: LessonCaptionWidget(lesson: lesson),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class FeedVideoManager extends ChangeNotifier {
  final Map<String, _ManagedVideoEntry> _entries = {};
  List<LessonModel> _lessons = const [];
  int _activeIndex = 0;
  bool _disposed = false;

  Future<void> setLessons(List<LessonModel> lessons) async {
    _lessons = List.unmodifiable(lessons);
    updateWindow(_activeIndex);
  }

  void updateWindow(int activeIndex) {
    if (_disposed || _lessons.isEmpty) return;
    _activeIndex = activeIndex.clamp(0, _lessons.length - 1);

    final keep = <String>{};
    for (final offset in const [-1, 0, 1, 2]) {
      final index = _activeIndex + offset;
      if (index < 0 || index >= _lessons.length) continue;
      keep.add(_lessons[index].id);
    }

    for (final lesson in _lessons) {
      final shouldKeep = keep.contains(lesson.id);
      if (shouldKeep) {
        _ensureEntry(lesson);
      } else {
        _disposeEntry(lesson.id);
      }
    }

    for (final lesson in _lessons) {
      final entry = _entries[lesson.id];
      if (entry == null) continue;
      if (lesson.id == _lessons[_activeIndex].id) {
        entry.play();
      } else {
        entry.pause();
      }
    }
    notifyListeners();
  }

  _ManagedVideoEntry? entryFor(String lessonId) => _entries[lessonId];

  Future<void> preload(LessonModel lesson) async {
    if (_disposed) return;
    await _ensureEntry(lesson);
  }

  Future<_ManagedVideoEntry?> _ensureEntry(LessonModel lesson) async {
    final existing = _entries[lesson.id];
    if (existing != null) return existing;

    final entry = _ManagedVideoEntry(lesson);
    _entries[lesson.id] = entry;
    await entry.initialize();
    return entry;
  }

  void _disposeEntry(String lessonId) {
    final entry = _entries.remove(lessonId);
    entry?.dispose();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final entry in _entries.values) {
      entry.dispose();
    }
    _entries.clear();
    super.dispose();
  }
}

class _ManagedVideoEntry {
  final LessonModel lesson;
  VideoPlayerController? videoController;
  YoutubePlayerController? youtubeController;
  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);
  bool _playing = false;

  _ManagedVideoEntry(this.lesson);

  Future<void> initialize() async {
    final videoUrl = lesson.videoUrl?.trim() ?? '';
    if (videoUrl.startsWith('yt:')) {
      final videoId = videoUrl.substring(3).trim();
      if (videoId.isEmpty) return;
      youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          loop: true,
        ),
      );
      ready.value = true;
      return;
    }

    final uri = Uri.tryParse(videoUrl);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    videoController = controller;
    await controller.initialize();
    await controller.setLooping(true);
    ready.value = true;
  }

  void play() {
    if (_playing) return;
    _playing = true;
    videoController?.play();
    youtubeController?.play();
  }

  void pause() {
    if (!_playing) {
      videoController?.pause();
      youtubeController?.pause();
      return;
    }
    _playing = false;
    videoController?.pause();
    youtubeController?.pause();
  }

  void dispose() {
    ready.dispose();
    videoController?.dispose();
    youtubeController?.dispose();
  }
}

class LessonVideoWidget extends StatefulWidget {
  final FeedVideoManager manager;
  final LessonModel lesson;
  final bool isActive;

  const LessonVideoWidget({
    super.key,
    required this.manager,
    required this.lesson,
    required this.isActive,
  });

  @override
  State<LessonVideoWidget> createState() => _LessonVideoWidgetState();
}

class _LessonVideoWidgetState extends State<LessonVideoWidget> {
  @override
  void initState() {
    super.initState();
    widget.manager.preload(widget.lesson);
  }

  @override
  void didUpdateWidget(covariant LessonVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson.id != widget.lesson.id) {
      widget.manager.preload(widget.lesson);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.manager.entryFor(widget.lesson.id);
    if (entry == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return AnimatedBuilder(
      animation: entry.ready,
      builder: (context, _) {
        if (!entry.ready.value) {
          return const ColoredBox(
            color: Colors.black,
            child:
                Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (entry.youtubeController != null) {
          return YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: entry.youtubeController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.redAccent,
            ),
            builder: (context, player) {
              return ColoredBox(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: player,
                  ),
                ),
              );
            },
          );
        }

        final controller = entry.videoController;
        if (controller != null && controller.value.isInitialized) {
          return ColoredBox(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          );
        }

        return const ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      },
    );
  }
}

class LessonOverlayWidget extends StatelessWidget {
  final LessonModel lesson;
  final Widget child;

  const LessonOverlayWidget({
    super.key,
    required this.lesson,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: child,
          ),
        ],
      ),
    );
  }
}

class LessonCaptionWidget extends StatelessWidget {
  final LessonModel lesson;

  const LessonCaptionWidget({
    super.key,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lesson.category,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lesson.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (lesson.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              lesson.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
