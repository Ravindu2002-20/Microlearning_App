import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../repositories/chat_repository.dart';
import '../services/gemini_service.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final activeConversationIdProvider = StateProvider<String?>((ref) => null);

final conversationListProvider = StateNotifierProvider<ConversationListNotifier,
    AsyncValue<List<ConversationModel>>>(
  (ref) {
    return ConversationListNotifier(ref.watch(chatRepositoryProvider));
  },
);

final aiChatControllerProvider =
    StateNotifierProvider<AiChatController, AsyncValue<List<ChatMessageModel>>>(
        (ref) {
  return AiChatController(
    chatRepository: ref.watch(chatRepositoryProvider),
    geminiService: ref.watch(geminiServiceProvider),
    conversationListNotifier: ref.read(conversationListProvider.notifier),
    activeConversationIdSetter: (conversationId) {
      ref.read(activeConversationIdProvider.notifier).state = conversationId;
    },
  );
});

final aiChatTypingProvider = StateProvider<bool>((ref) => false);

class ConversationListNotifier
    extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  ConversationListNotifier(this._chatRepository)
      : super(const AsyncValue.loading());

  final ChatRepository _chatRepository;

  Future<void> loadForUser(String userId) async {
    try {
      final conversations = await _chatRepository.fetchConversations(
        userId: userId,
      );
      state = AsyncValue.data(conversations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setConversations(List<ConversationModel> conversations) {
    state = AsyncValue.data(conversations);
  }
}

class AiChatController
    extends StateNotifier<AsyncValue<List<ChatMessageModel>>> {
  AiChatController({
    required ChatRepository chatRepository,
    required GeminiService geminiService,
    required ConversationListNotifier conversationListNotifier,
    required void Function(String?) activeConversationIdSetter,
  })  : _chatRepository = chatRepository,
        _geminiService = geminiService,
        _conversationListNotifier = conversationListNotifier,
        _setActiveConversationId = activeConversationIdSetter,
        super(const AsyncValue.loading());

  final ChatRepository _chatRepository;
  final GeminiService _geminiService;
  final ConversationListNotifier _conversationListNotifier;
  final void Function(String?) _setActiveConversationId;
  final _uuid = const Uuid();
  RealtimeChannel? _realtimeChannel;
  bool _loadingInitial = false;
  String? _currentConversationId;
  bool _renameInProgress = false;

  Future<void> loadInitialConversation() async {
    // Kept for backward compatibility, but UI now explicitly resets.
    if (_loadingInitial) return;
    _loadingInitial = true;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = const AsyncValue.data([]);
      _loadingInitial = false;
      return;
    }

    try {
      final conversations = await _chatRepository.fetchConversations(
        userId: user.id,
      );
      _conversationListNotifier.setConversations(conversations);

      if (conversations.isNotEmpty) {
        await loadConversation(conversations.first.id, userId: user.id);
      } else {
        await startNewConversation(initialTitle: 'New chat');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _loadingInitial = false;
    }
  }

  Future<void> resetToNewChat() async {
    // Always start with a brand-new conversation when entering the AI bot.
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    _currentConversationId = null;

    state = const AsyncValue.data([]);
    await startNewConversation(initialTitle: 'New chat');
  }

  Future<void> loadConversation(
    String conversationId, {
    String? userId,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    final resolvedUserId = userId ?? user?.id;
    if (resolvedUserId == null) return;

    _currentConversationId = conversationId;
    _setActiveConversationId(conversationId);

    try {
      final messages = await _chatRepository.loadRecentMessages(
        userId: resolvedUserId,
        conversationId: conversationId,
      );
      state = AsyncValue.data(messages);
      _attachRealtime(userId: resolvedUserId, conversationId: conversationId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startNewConversation({required String initialTitle}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final conversation = await _chatRepository.createConversation(
      userId: user.id,
      title: initialTitle,
    );
    final conversations = [
      conversation,
      ...(_conversationListNotifier.state.valueOrNull ??
          const <ConversationModel>[]),
    ];
    _conversationListNotifier.setConversations(conversations);
    await loadConversation(conversation.id, userId: user.id);
  }

  Future<void> renameActiveConversation(String title) async {
    if (_renameInProgress) return;
    final conversationId = _currentConversationId;
    if (conversationId == null) return;
    _renameInProgress = true;
    try {
      final renamed = await _chatRepository.renameConversation(
        conversationId: conversationId,
        title: title,
      );
      final existing = _conversationListNotifier.state.valueOrNull ??
          const <ConversationModel>[];
      final updated = existing
          .map((c) => c.id == conversationId ? renamed : c)
          .toList(growable: false);
      _conversationListNotifier.setConversations(updated);
    } finally {
      _renameInProgress = false;
    }
  }

  void _attachRealtime({
    required String userId,
    required String conversationId,
  }) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = Supabase.instance.client.channel(
      'chat_messages:$userId:$conversationId',
    );

    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        final record = payload.newRecord;
        final message = ChatMessageModel.fromJson(
          Map<String, dynamic>.from(record),
        );
        if (message.conversationId != conversationId) return;
        final current = state.valueOrNull ?? const <ChatMessageModel>[];
        if (current.any((m) => m.id == message.id)) return;

        final updated = [...current, message]
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state = AsyncValue.data(updated);
      },
    );

    _realtimeChannel!.subscribe();
  }

  Future<void> sendMessage({
    required String text,
    Map<String, dynamic>? lessonContext,
  }) async {
    debugPrint('Sending message to Gemini service.');

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    var conversationId = _currentConversationId;
    if (conversationId == null) {
      await startNewConversation(initialTitle: trimmed);
      // `startNewConversation()` calls `loadConversation()`, which sets
      // `_currentConversationId`. Re-read it so we don't drop the first
      // message.
      conversationId = _currentConversationId;
    }
    if (conversationId == null) return;


    final current = state.valueOrNull ?? const <ChatMessageModel>[];
    final userMessage = ChatMessageModel(
      id: _uuid.v4(),
      userId: user.id,
      conversationId: conversationId,
      sender: ChatSender.user,
      message: trimmed,
      createdAt: DateTime.now(),
    );

    state = AsyncValue<List<ChatMessageModel>>.data([...current, userMessage]);
    try {
      await _chatRepository.insertMessage(userMessage);
    } catch (e) {
      debugPrint(
        'Failed to save user message to DB (continuing to generate reply): $e',
      );
    }

    final history = current
        .where((m) =>
            m.sender == ChatSender.user || m.sender == ChatSender.assistant)
        .take(30)
        .map((m) => {
              'role': m.sender == ChatSender.user ? 'user' : 'model',
              'text': m.message,
            })
        .toList();

    final prompt = _buildPrompt(
      message: trimmed,
      lessonContext: lessonContext,
    );

    final placeholder = ChatMessageModel(
      id: _uuid.v4(),
      userId: user.id,
      conversationId: conversationId,
      sender: ChatSender.assistant,
      message: '',
      createdAt: DateTime.now(),
      isPending: true,
    );
    state = AsyncValue<List<ChatMessageModel>>.data(
      [...state.valueOrNull ?? const <ChatMessageModel>[], placeholder],
    );

    String? reply;
    String? errorDetail;
    try {
      reply = await _geminiService.generateReply(
        prompt: prompt,
        history: history,
      );
    } catch (e) {
      debugPrint('Gemini generation error: $e');
      errorDetail = e.toString();
    }

    if (reply == null || reply.trim().isEmpty) {
      final failed = placeholder.copyWith(
        message: kDebugMode
            ? 'Something went wrong generating a reply.\n\nDetails: ${errorDetail ?? "empty response"}'
            : 'I could not generate a response right now. Please try again.',
        isPending: false,
        isError: true,
      );
      final updated = [...(state.valueOrNull ?? const <ChatMessageModel>[])];
      updated.removeWhere((m) => m.id == placeholder.id);
      updated.add(failed);
      state = AsyncValue<List<ChatMessageModel>>.data(updated);
      return;
    }

    final assistantMessage = placeholder.copyWith(
      message: reply,
      isPending: false,
    );
    final updated = [...(state.valueOrNull ?? const <ChatMessageModel>[])];
    updated.removeWhere((m) => m.id == placeholder.id);
    updated.add(assistantMessage);
    state = AsyncValue<List<ChatMessageModel>>.data(updated);

    try {
      await _chatRepository.insertMessage(assistantMessage);
    } catch (e) {
      debugPrint(
        'Failed to save assistant message to DB (reply still shown to user): $e',
      );
    }

    if (current.where((m) => m.sender == ChatSender.user).length == 1) {
      await renameActiveConversation(trimmed);
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  String _buildPrompt({
    required String message,
    Map<String, dynamic>? lessonContext,
  }) {
    final lessonBlock = lessonContext == null
        ? ''
        : '''
Current lesson context:
- Title: ${lessonContext['title'] ?? ''}
- Description: ${lessonContext['description'] ?? ''}
- Category: ${lessonContext['category'] ?? ''}
- Difficulty: ${lessonContext['difficulty'] ?? ''}
''';

    return '''
You are Nova, an educational assistant focused on helping students understand lessons, programming, and computer science.
Be accurate, friendly, concise when appropriate, and supportive.
$lessonBlock
User message:
$message
''';
  }
}
