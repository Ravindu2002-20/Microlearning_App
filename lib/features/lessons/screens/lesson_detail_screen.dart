import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../learning/models/lesson_model.dart';
import '../../learning/repositories/lesson_repository.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final _repo = LessonRepository(Supabase.instance.client);
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  LessonModel? _lesson;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lesson = await _repo.getLessonById(widget.lessonId);
      if (!mounted) return;
      if (lesson == null) {
        setState(() => _error = 'Lesson not found.');
        return;
      }
      if ((lesson.videoPath ?? '').isEmpty) {
        setState(() => _error = 'This lesson has no video attached yet.');
        return;
      }

      final url = await _repo.getVideoUrl(lesson.videoPath!);
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _initializeFuture = _controller!.initialize().then((_) {
        _controller?.play();
        setState(() {});
      }).catchError((_) {
        if (mounted) {
          setState(() => _error = 'Unable to play this video.');
        }
      });
      setState(() => _lesson = lesson);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load this lesson.');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _error != null
          ? Center(
              child: Text(
                _error!,
                style: TextStyle(color: textColor),
                textAlign: TextAlign.center,
              ),
            )
          : _lesson == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _controller == null
                          ? const Center(child: CircularProgressIndicator())
                          : FutureBuilder<void>(
                              future: _initializeFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState !=
                                    ConnectionState.done) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (_controller!.value.hasError) {
                                  return const Center(
                                    child: Text('Video playback failed'),
                                  );
                                }
                                return VideoPlayer(_controller!);
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lesson!.title,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _lesson!.description,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
