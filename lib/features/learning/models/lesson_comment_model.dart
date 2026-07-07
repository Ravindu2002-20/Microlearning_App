class LessonCommentModel {
  final String id;
  final String userId;
  final String lessonId;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? authorName;
  final String? authorAvatarUrl;

  const LessonCommentModel({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.content,
    this.createdAt,
    this.updatedAt,
    this.authorName,
    this.authorAvatarUrl,
  });

  factory LessonCommentModel.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    String? authorName;
    String? avatarUrl;

    if (profiles is Map<String, dynamic>) {
      final fullName = (profiles['full_name'] as String?)?.trim();
      final username = (profiles['username'] as String?)?.trim();
      final resolvedName = (fullName != null && fullName.isNotEmpty)
          ? fullName
          : (username != null && username.isNotEmpty
              ? (username.startsWith('@') ? username : '@$username')
              : null);
      authorName = resolvedName;
      avatarUrl = profiles['avatar_url']?.toString();
    }

    return LessonCommentModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      lessonId: json['lesson_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      authorName: authorName,
      authorAvatarUrl: avatarUrl,
    );
  }
}
