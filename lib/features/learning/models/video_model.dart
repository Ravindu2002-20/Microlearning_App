/// Model for `public.videos` — YouTube-sourced video metadata.
class VideoModel {
  final String id;
  final String youtubeVideoId;
  final String title;
  final String? description;
  final String? thumbnail;
  final String? channelTitle;
  final int? durationSeconds;
  final String? topic;
  final DateTime? createdAt;

  const VideoModel({
    required this.id,
    required this.youtubeVideoId,
    required this.title,
    this.description,
    this.thumbnail,
    this.channelTitle,
    this.durationSeconds,
    this.topic,
    this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id']?.toString() ?? '',
      youtubeVideoId: json['youtube_video_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      channelTitle: json['channel_title']?.toString(),
      durationSeconds: json['duration_seconds'] as int?,
      topic: json['topic']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}