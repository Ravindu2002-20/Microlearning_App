import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';
import '../../learning/models/lesson_item.dart';
import '../../learning/models/lesson_model.dart';
import '../../learning/models/video_model.dart';
import '../../learning/repositories/lesson_repository.dart';

// ─── Entry points ─────────────────────────────────────────────────────────────
//
// 1. From LessonDashboardScreen  → LessonDetailScreen(item: LessonItem)
// 2. From anywhere with a bare LessonModel → LessonDetailScreen.fromModel(lesson)
//
// Internally both collapse to a `_Source` union so the rest of the widget is
// identical regardless of where the navigation came from.

sealed class _Source {}
final class _SourceItem  extends _Source { final LessonItem item;    _SourceItem(this.item); }
final class _SourceModel extends _Source { final LessonModel lesson; _SourceModel(this.lesson); }

// ─────────────────────────────────────────────────────────────────────────────

class LessonDetailScreen extends StatefulWidget {
  final _Source _source;

  /// Navigate from the dashboard (preferred) — zero extra network calls for
  /// YouTube items.
  LessonDetailScreen({super.key, required LessonItem item})
      : _source = _SourceItem(item) as _Source; // workaround: see init

  // ignore: use_super_parameters
  LessonDetailScreen._raw({Key? key, required _Source source})
      : _source = source,
        super(key: key);

  /// Navigate with just a [LessonModel] (e.g. from the swipe feed).
  /// The screen will resolve the video URL / YouTube ID automatically.
  factory LessonDetailScreen.fromModel(LessonModel lesson, {Key? key}) =>
      LessonDetailScreen._raw(key: key, source: _SourceModel(lesson));

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  // ── Resolved display data ─────────────────────────────────────────────────
  String? _title;
  String? _description;
  String? _thumbnailUrl;
  LessonModel? _lesson;   // set when source is a Storage lesson
  VideoModel?  _video;    // set when source is a YouTube video

  bool _metaLoading = true;

  // ── Chewie (Supabase Storage) ─────────────────────────────────────────────
  VideoPlayerController? _videoController;
  ChewieController?      _chewieController;
  bool   _videoLoading = false;
  String? _videoError;

  // ── YouTube player ────────────────────────────────────────────────────────
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    switch (widget._source) {
      case _SourceItem(:final item):
        await _initFromItem(item);
      case _SourceModel(:final lesson):
        await _initFromModel(lesson);
    }
  }

  // ── Init from LessonItem (dashboard) ─────────────────────────────────────

  Future<void> _initFromItem(LessonItem item) async {
    switch (item) {
      case StorageLesson(:final lesson):
        _title       = lesson.title;
        _description = lesson.description;
        _thumbnailUrl = lesson.thumbnailUrl;
        _lesson      = lesson;
        if (mounted) setState(() => _metaLoading = false);
        await _resolveStorageVideo(lesson);

      case YoutubeVideo(:final video):
        _title        = video.title;
        _description  = video.description ?? '';
        _thumbnailUrl = video.thumbnail;
        _video        = video;
        if (mounted) setState(() => _metaLoading = false);
        _initYouTube(video.youtubeVideoId);
    }
  }

  // ── Init from LessonModel (feed / direct) ─────────────────────────────────

  Future<void> _initFromModel(LessonModel lesson) async {
    _title        = lesson.title;
    _description  = lesson.description;
    _thumbnailUrl = lesson.thumbnailUrl;

    final url = lesson.videoUrl ?? '';

    if (url.startsWith('yt:')) {
      // YouTube video embedded in a LessonModel by learning_repository.
      final ytId = url.substring(3);
      _lesson = null; // no storage metadata needed
      if (mounted) setState(() => _metaLoading = false);
      _initYouTube(ytId);
    } else {
      _lesson = lesson;
      if (mounted) setState(() => _metaLoading = false);
      await _resolveStorageVideo(lesson);
    }
  }

  // ── Storage video resolution ──────────────────────────────────────────────

  Future<void> _resolveStorageVideo(LessonModel lesson) async {
    // If video_url is already a full https URL, play it directly.
    final existing = lesson.videoUrl ?? '';
    if (existing.startsWith('http')) {
      await _initChewie(existing);
      return;
    }

    // Otherwise ask the repo to convert video_path → signed URL.
    if (!mounted) return;
    setState(() => _videoLoading = true);

    try {
      final repo   = LessonRepository(Supabase.instance.client);
      final resolved = await repo.getLessonById(lesson.id);
      if (!mounted) return;

      if (resolved?.videoUrl != null) {
        _lesson = resolved;
        _thumbnailUrl = resolved!.thumbnailUrl ?? _thumbnailUrl;
        await _initChewie(resolved.videoUrl!);
      } else {
        setState(() {
          _videoLoading = false;
          _videoError   = 'No video available.';
        });
      }
    } catch (e) {
      debugPrint('resolveStorageVideo error: $e');
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _videoError   = 'Could not load video.';
      });
    }
  }

  Future<void> _initChewie(String url) async {
    if (!mounted) return;
    setState(() => _videoLoading = true);

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: _thumbnailUrl != null
            ? Image.network(_thumbnailUrl!, fit: BoxFit.cover)
            : Container(color: Colors.black),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryDark,
          handleColor: AppColors.primaryDark,
          bufferedColor: AppColors.primaryDark.withValues(alpha: 0.3),
          backgroundColor: Colors.white24,
        ),
      );
      setState(() => _videoLoading = false);
    } catch (e) {
      debugPrint('Chewie init error: $e');
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _videoError   = 'Could not load video.';
      });
    }
  }

  // ── YouTube ───────────────────────────────────────────────────────────────

  void _initYouTube(String videoId) {
    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        loop: false,
      ),
    );
    if (mounted) setState(() {});
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _ytController?.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg           = isDark ? AppColors.backgroundDark  : AppColors.backgroundLight;
    final textPrimary  = isDark ? AppColors.textPrimaryDark  : AppColors.textPrimaryLight;
    final textSecondary= isDark ? AppColors.textSecondaryDark: AppColors.textSecondaryLight;
    final surface      = isDark ? AppColors.surfaceDark      : AppColors.surfaceLight;

    if (_metaLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg, elevation: 0,
            iconTheme: IconThemeData(color: textPrimary)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // YouTube needs YoutubePlayerBuilder to own the Scaffold for full-screen.
    if (_ytController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _ytController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primaryDark,
          progressColors: ProgressBarColors(
            playedColor:  AppColors.primaryDark,
            handleColor:  AppColors.primaryDark,
            bufferedColor: AppColors.primaryDark.withValues(alpha: 0.3),
            backgroundColor: Colors.white24,
          ),
        ),
        builder: (context, player) => Scaffold(
          backgroundColor: bg,
          body: CustomScrollView(slivers: [
            SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight: 240,
              pinned: true,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(background: player),
            ),
            _body(textPrimary: textPrimary, textSecondary: textSecondary, surface: surface),
          ]),
        ),
      );
    }

    // Storage / no-video layout.
    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: Colors.black,
          expandedHeight: 240,
          pinned: true,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(background: _videoArea()),
        ),
        _body(textPrimary: textPrimary, textSecondary: textSecondary, surface: surface),
      ]),
    );
  }

  // ── Video area widget (Storage only) ─────────────────────────────────────

  Widget _videoArea() {
    if (_chewieController != null) return Chewie(controller: _chewieController!);

    if (_videoLoading) {
      return Stack(fit: StackFit.expand, children: [
        _thumb(),
        const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
      ]);
    }

    if (_videoError != null) {
      return Stack(fit: StackFit.expand, children: [
        _thumb(),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
            child: const Text('Video unavailable',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ),
      ]);
    }

    return _thumb();
  }

  Widget _thumb() {
    if (_thumbnailUrl != null) {
      return Image.network(_thumbnailUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback());
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    color: Colors.black,
    child: const Center(
      child: Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white54),
    ),
  );

  // ── Shared body ───────────────────────────────────────────────────────────

  Widget _body({
    required Color textPrimary,
    required Color textSecondary,
    required Color surface,
  }) {
    final lesson = _lesson;
    final video  = _video;
    final isYt   = video != null || (_ytController != null && lesson == null);

    final chipLabel = isYt
        ? (video?.topic ?? 'YouTube')
        : (lesson?.category ?? '');
    final chipColor = isYt ? const Color(0xFFFF0000) : AppColors.primaryDark;
    final chipIcon  = isYt ? Icons.smart_display_rounded : Icons.videocam_rounded;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(chipIcon, size: 12, color: chipColor),
                const SizedBox(width: 5),
                Text(chipLabel,
                    style: TextStyle(color: chipColor, fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 12),

            // Title
            Text(_title ?? '',
                style: TextStyle(color: textPrimary, fontSize: 22,
                    fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 8),

            // Meta chips
            if (lesson != null)
              Row(children: [
                _MetaChip(icon: Icons.signal_cellular_alt_rounded,
                    label: lesson.difficultyLevel, color: textSecondary),
                const SizedBox(width: 12),
                _MetaChip(icon: Icons.wifi_rounded,
                    label: lesson.minNetworkStrength, color: textSecondary),
                if (lesson.safeForMotion) ...[
                  const SizedBox(width: 12),
                  _MetaChip(icon: Icons.directions_walk_rounded,
                      label: 'Motion safe', color: textSecondary),
                ],
              ]),

            if (video != null)
              Row(children: [
                if (video.channelTitle != null)
                  _MetaChip(icon: Icons.smart_display_rounded,
                      label: video.channelTitle!, color: textSecondary),
                if (video.durationSeconds != null) ...[
                  const SizedBox(width: 12),
                  _MetaChip(icon: Icons.timer_rounded,
                      label: _fmt(video.durationSeconds!), color: textSecondary),
                ],
              ]),

            const SizedBox(height: 20),
            Divider(color: textSecondary.withValues(alpha: 0.15)),
            const SizedBox(height: 16),

            Text('About this lesson',
                style: TextStyle(color: textPrimary, fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_description ?? '',
                style: TextStyle(color: textSecondary, fontSize: 14, height: 1.6)),

            if (lesson != null && lesson.content.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
                ),
                child: Text(lesson.content,
                    style: TextStyle(color: textPrimary, fontSize: 15, height: 1.6)),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ─── Meta chip ────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 12)),
    ]);
  }
}