class ProfileModel {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final int currentLevel;
  final int xp;

  ProfileModel({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    required this.currentLevel,
    required this.xp,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      currentLevel: json['current_level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
    );
  }
}

class LessonModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String category;
  final int difficultyLevel;
  final String format;
  final String minNetworkStrength;
  final bool safeForMotion;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
    required this.difficultyLevel,
    required this.format,
    required this.minNetworkStrength,
    required this.safeForMotion,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      difficultyLevel: json['difficulty_level'] as int? ?? 1,
      format: json['format'] as String? ?? 'text',
      minNetworkStrength: json['min_network_strength'] as String? ?? 'weak',
      safeForMotion: json['safe_for_motion'] as bool? ?? true,
    );
  }
}