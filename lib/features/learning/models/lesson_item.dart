import 'package:microlearning_app/features/learning/models/lesson_model.dart';
import 'package:microlearning_app/features/learning/models/video_model.dart';

sealed class LessonItem {
  String get id;
  String get title;
  String get description;
  String? get thumbnailUrl;
  DateTime? get createdAt;
}

/// Wraps a row from `public.lessons` (video stored in Supabase Storage).
final class StorageLesson extends LessonItem {
  final LessonModel lesson;

  StorageLesson(this.lesson);

  @override String get id          => lesson.id;
  @override String get title       => lesson.title;
  @override String get description => lesson.description;
  @override String? get thumbnailUrl => lesson.thumbnailUrl;
  @override DateTime? get createdAt  => lesson.createdAt;
}

/// Wraps a row from `public.videos` (YouTube-hosted video).
final class YoutubeVideo extends LessonItem {
  final VideoModel video;

  YoutubeVideo(this.video);

  @override String get id          => video.id;
  @override String get title       => video.title;
  @override String get description => video.description ?? '';
  @override String? get thumbnailUrl => video.thumbnail;
  @override DateTime? get createdAt  => video.createdAt;
}