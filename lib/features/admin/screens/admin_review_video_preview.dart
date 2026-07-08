import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';


import '../../../core/constants/constants.dart';
import '../../learning/models/lesson_model.dart';

class AdminVideoPreview extends StatefulWidget {
  final LessonModel lesson;

  const AdminVideoPreview({super.key, required this.lesson});

  @override
  State<AdminVideoPreview> createState() => _AdminVideoPreviewState();
}

class _AdminVideoPreviewState extends State<AdminVideoPreview> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = false;
  bool _error = false;

  Future<void> _startPlayback() async {
    final url = widget.lesson.videoUrl;
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      if (!mounted) return;
      setState(() => _error = true);
      return;
    }

    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      // If user taps twice quickly, dispose the previous instance.
      _chewieController?.dispose();
      _chewieController = null;
      _videoController?.dispose();
      _videoController = null;




      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryDark,
          handleColor: AppColors.primaryDark,
          bufferedColor: AppColors.primaryDark.withValues(alpha: 0.3),
          backgroundColor: Colors.white24,
        ),
      );

      setState(() {
        _videoController = controller;
        _chewieController = chewie;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Admin video preview error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: Chewie(controller: _chewieController!),
      );
    }

    return GestureDetector(
      onTap: _loading ? null : _startPlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if ((widget.lesson.thumbnailUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: Image.network(
                widget.lesson.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black12),
              ),
            )
          else
            Container(color: Colors.black12),
          Center(
            child: _loading
                ? const CircularProgressIndicator()
                : Icon(
                    _error
                        ? Icons.error_outline_rounded
                        : Icons.play_circle_fill_rounded,
                    size: 54,
                    color: _error ? AppColors.error : AppColors.warning,
                  ),
          ),
          if (_error)
            const Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                'Video unavailable — tap to retry',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

