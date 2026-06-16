import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/video_model.dart';
import '../models/lesson_model.dart';

import '../../../core/constants/app_colors.dart';


class YoutubeVideosPage extends StatefulWidget {

  const YoutubeVideosPage({super.key});

  @override
  State<YoutubeVideosPage> createState() => _YoutubeVideosPageState();
}

class _YoutubeVideosPageState extends State<YoutubeVideosPage> {
  final _supabase = Supabase.instance.client;

  Future<List<VideoModel>> _loadVideos() async {
    final res = await _supabase
        .from('videos')
        .select()
        .order('created_at', ascending: false)
        .limit(10);

    return (res as List).map((e) => VideoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final text = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Videos'),
        backgroundColor: bg,
        foregroundColor: text,
      ),
      body: FutureBuilder<List<VideoModel>>(
        future: _loadVideos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final videos = snapshot.data ?? [];
          if (videos.isEmpty) {
            return const Center(child: Text('No YouTube videos found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              final ytId = v.youtubeVideoId;

              // Reuse the same rendering approach as the rest of the app.
              // Convert to LessonModel so existing screen logic/fields remain compatible.
              final lesson = LessonModel(
                id: v.id,
                title: v.title,
                description: v.description ?? '',
                content: '',
                category: v.topic ?? v.channelTitle ?? 'YouTube',
                videoUrl: 'yt:$ytId',
                thumbnailUrl: v.thumbnail,
                durationSeconds: v.durationSeconds,
                difficultyLevel: 'beginner',
                format: 'video',
                minNetworkStrength: 'medium',
                safeForMotion: false,
                status: 'approved',
                isPublished: true,
                createdAt: v.createdAt,
              );

              return Card(
                elevation: 0,
                color: isDark ? Colors.grey.shade900 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 220,
                          child: YoutubePlayer(
                            controller: YoutubePlayerController(
                              initialVideoId: ytId,
                              flags: const YoutubePlayerFlags(
                                autoPlay: false,
                                mute: false,
                                enableCaption: true,
                                loop: false,
                              ),
                            ),
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.redAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        lesson.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((lesson.description).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          lesson.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: text.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

