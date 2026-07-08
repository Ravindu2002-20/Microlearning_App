import 'package:flutter/foundation.dart';

enum ChatSender { user, assistant }

@immutable
class ChatMessageModel {
  final String id;
  final String userId;
  final String conversationId;
  final ChatSender sender;
  final String message;
  final DateTime createdAt;
  final bool isPending;
  final bool isError;

  const ChatMessageModel({
    required this.id,
    required this.userId,
    required this.conversationId,
    required this.sender,
    required this.message,
    required this.createdAt,
    this.isPending = false,
    this.isError = false,
  });

  ChatMessageModel copyWith({
    String? id,
    String? userId,
    String? conversationId,
    ChatSender? sender,
    String? message,
    DateTime? createdAt,
    bool? isPending,
    bool? isError,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isPending: isPending ?? this.isPending,
      isError: isError ?? this.isError,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // DB may store the sender/role under different column names.
    // - toInsertJson() writes: role: user|assistant
    // - older/other code may read: sender
    final senderRaw =
        (json['sender'] ?? json['role'] ?? '').toString().toLowerCase();

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      sender: senderRaw == 'assistant' ? ChatSender.assistant : ChatSender.user,
      message: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'user_id': userId,
      'conversation_id': conversationId,
      'role': sender == ChatSender.assistant ? 'assistant' : 'user',
      'content': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
