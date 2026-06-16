class LessonModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String category;

  // New URL fields (Supabase columns: video_url, thumbnail_url)
  final String? videoUrl;
  final String? thumbnailUrl;

  final int? durationSeconds;
  final String difficultyLevel;
  final String format;
  final String minNetworkStrength;
  final bool safeForMotion;

  final String status;

  final String? uploadedBy;
  final String? adminNotes;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final bool isPublished;

  const LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
    this.videoUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    required this.difficultyLevel,
    required this.format,
    required this.minNetworkStrength,
    required this.safeForMotion,
    this.status = 'approved',
    this.uploadedBy,
    this.adminNotes,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
    this.isPublished = true,
  });

  String? get rejectionReason => adminNotes;
  DateTime? get reviewedAt => approvedAt;

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final videoUrl = json['video_url']?.toString() ??
        json['video_path']?.toString();

    return LessonModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      videoUrl: videoUrl,
      thumbnailUrl: json['thumbnail_url']?.toString(),
      durationSeconds: json['duration_seconds'] as int?,
      difficultyLevel: json['difficulty_level']?.toString() ?? 'beginner',
      format: json['format'] as String? ?? 'text',
      minNetworkStrength:
          json['min_network_strength'] as String? ?? 'weak',
      safeForMotion: json['safe_for_motion'] as bool? ?? true,
      status: json['status']?.toString() ?? 'approved',
      uploadedBy: json['uploaded_by']?.toString(),
      adminNotes: json['admin_notes']?.toString(),
      approvedBy: json['approved_by']?.toString(),
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      isPublished: json['is_published'] as bool? ?? true,
    );
  }

  LessonModel copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? category,
    String? videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    String? difficultyLevel,
    String? format,
    String? minNetworkStrength,
    bool? safeForMotion,
    String? status,
    String? uploadedBy,
    String? adminNotes,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      category: category ?? this.category,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      format: format ?? this.format,
      minNetworkStrength: minNetworkStrength ?? this.minNetworkStrength,
      safeForMotion: safeForMotion ?? this.safeForMotion,
      status: status ?? this.status,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      adminNotes: adminNotes ?? this.adminNotes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'category': category,
      'video_url': videoUrl,
      'video_path': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'difficulty_level': difficultyLevel,
      'format': format,
      'min_network_strength': minNetworkStrength,
      'safe_for_motion': safeForMotion,
      'status': status,
      'uploaded_by': uploadedBy,
      'admin_notes': adminNotes,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_published': isPublished,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'category': category,
      'video_url': videoUrl,
      'video_path': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'difficulty_level': difficultyLevel,
      'format': format,
      'min_network_strength': minNetworkStrength,
      'safe_for_motion': safeForMotion,
      'status': 'pending',
      'uploaded_by': uploadedBy,
      'admin_notes': adminNotes,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_published': isPublished,
    };
  }
}

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
