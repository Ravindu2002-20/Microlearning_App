import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  Future<List<ChatMessageModel>> loadRecentMessages({
    required String userId,
    required String conversationId,
    int limit = 30,
  }) async {
    final rows = await _client
        .from('chat_messages')
        .select()
        .eq('user_id', userId)
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(limit);

    return (rows as List<dynamic>)
        .map((e) => ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ChatMessageModel> insertMessage(ChatMessageModel message) async {
    final row = await _client
        .from('chat_messages')
        .insert(message.toInsertJson())
        .select()
        .single();
    return ChatMessageModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<ConversationModel>> fetchConversations({
    required String userId,
  }) async {
    final rows = await _client
        .from('conversations')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .order('created_at', ascending: false);


    return (rows as List<dynamic>)
        .map((e) => ConversationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ConversationModel> createConversation({
    required String userId,
    required String title,
  }) async {
    final row = await _client
        .from('conversations')
        .insert({
          'user_id': userId,
          'title': title,
        })
        .select()
        .single();

    return ConversationModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<ConversationModel> renameConversation({
    required String conversationId,
    required String title,
  }) async {
    final row = await _client
        .from('conversations')
        .update({
          'title': title,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId)
        .select()
        .single();

    return ConversationModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteConversation({
    required String conversationId,
  }) async {
    await _client.from('conversations').delete().eq('id', conversationId);

    await _client
        .from('chat_messages')
        .delete()
        .eq('conversation_id', conversationId);
  }
}
