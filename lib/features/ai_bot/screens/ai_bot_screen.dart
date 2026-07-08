import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../controllers/ai_chat_controller.dart';
import '../models/chat_message_model.dart';

class AiBotScreen extends ConsumerStatefulWidget {
  const AiBotScreen({super.key});

  @override
  ConsumerState<AiBotScreen> createState() => _AiBotScreenState();
}

class _AiBotScreenState extends ConsumerState<AiBotScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiChatControllerProvider.notifier).startFreshSession();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _textCtrl.clear();
    ref.read(aiChatTypingProvider.notifier).state = true;
    await ref.read(aiChatControllerProvider.notifier).sendMessage(text: trimmed);
    ref.read(aiChatTypingProvider.notifier).state = false;
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final chatState = ref.watch(aiChatControllerProvider);
    final messages = chatState.valueOrNull ?? const <ChatMessageModel>[];
    final isGenerating = ref.watch(aiChatTypingProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      drawer: const _ChatHistoryDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (innerContext) {
                return _NovaHeader(
                  isGenerating: isGenerating,
                  onOpenMenu: () => Scaffold.of(innerContext).openDrawer(),
                );
              },
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                child: chatState.when(
                  loading: () => _buildConversationList(
                    messages: messages,
                    isGenerating: isGenerating,
                    showLoading: true,
                  ),
                  error: (err, st) {
                    return _buildConversationList(
                      messages: messages,
                      isGenerating: isGenerating,
                      errorText:
                          'Could not load chat history. Tap retry to try again.',
                      onRetry: () => ref
                          .read(aiChatControllerProvider.notifier)
                          .loadInitialConversation(),
                    );
                  },
                  data: (_) => _buildConversationList(
                    messages: messages,
                    isGenerating: isGenerating,
                  ),
                ),
              ),
            ),
            _SuggestionChips(onTap: _sendMessage),
            SafeArea(
              top: false,
              child: _NovaInputBar(
                controller: _textCtrl,
                focusNode: _focusNode,
                isGenerating: isGenerating,
                onSend: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList({
    required List<ChatMessageModel> messages,
    required bool isGenerating,
    bool showLoading = false,
    String? errorText,
    VoidCallback? onRetry,
  }) {
    final displayMessages = <ChatMessageModel>[
      _buildWelcomeMessage(),
      ...messages,
    ];

    return Column(
      children: [
        if (showLoading)
          const LinearProgressIndicator(minHeight: 2)
        else if (errorText != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingLg,
              vertical: AppDimensions.spacingXs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    errorText,
                    style: TextStyle(
                      color: AppColors.textSecondaryFor(
                        Theme.of(context).brightness,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingLg,
            ),
            itemCount: displayMessages.length + (isGenerating ? 1 : 0),
            itemBuilder: (context, index) {
              if (isGenerating && index == displayMessages.length) {
                return const _TypingIndicator();
              }
              return _ChatMessageWidget(message: displayMessages[index]);
            },
          ),
        ),
      ],
    );
  }

  ChatMessageModel _buildWelcomeMessage() {
    return ChatMessageModel(
      id: 'welcome-local',
      userId: Supabase.instance.client.auth.currentUser?.id ?? '',
      conversationId: ref.read(activeConversationIdProvider) ?? 'local',
      sender: ChatSender.assistant,
      message:
          "Hello! 👋\n\nI'm your AI Learning Assistant.\n\nI can help explain lessons, answer questions, create quizzes, explain code, and assist with your learning.\n\nHow can I help you today?",
      createdAt: DateTime.now(),
    );
  }
}

class _NovaHeader extends StatelessWidget {
  final bool isGenerating;
  final VoidCallback onOpenMenu;
  const _NovaHeader({required this.isGenerating, required this.onOpenMenu});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingSm,
        AppDimensions.spacingLg,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onOpenMenu,
            icon: const Icon(Icons.menu_rounded),
          ),
          _NovaAvatar(isGenerating: isGenerating),
          const SizedBox(width: AppDimensions.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nova',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryFor(Theme.of(context).brightness),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isGenerating
                          ? AppColors.accentAiSecondary
                          : AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isGenerating ? 'Thinking...' : 'Online',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isGenerating
                          ? AppColors.accentAiSecondary
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),

        ],
      ),
    );
  }
}

class _ChatHistoryDrawer extends ConsumerWidget {
  const _ChatHistoryDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationListProvider);
    final activeConversationId = ref.watch(activeConversationIdProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: const Text('Chat history'),
              trailing: IconButton(
                onPressed: () async {
                  await ref
                      .read(aiChatControllerProvider.notifier)
                      .startNewConversation(initialTitle: 'New chat');
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ),
            Expanded(
              child: conversationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => const Center(
                  child: Text('Could not load conversations.'),
                ),
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return const Center(child: Text('No conversations yet.'));
                  }
                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final selected = conversation.id == activeConversationId;
                      return ListTile(
                        selected: selected,
                        title: Text(conversation.title),
                        subtitle: Text(
                          _fmt(conversation.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () async {
                          await ref
                              .read(aiChatControllerProvider.notifier)
                              .loadConversation(conversation.id);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final d = dt;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _NovaAvatar extends StatefulWidget {
  final bool isGenerating;
  const _NovaAvatar({required this.isGenerating});

  @override
  State<_NovaAvatar> createState() => _NovaAvatarState();
}

class _NovaAvatarState extends State<_NovaAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _NovaAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGenerating != oldWidget.isGenerating) {
      _controller.duration =
          Duration(milliseconds: widget.isGenerating ? 800 : 2000);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.06);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.aiGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        );
      },
    );
  }
}

class _ChatMessageWidget extends StatelessWidget {
  final ChatMessageModel message;
  const _ChatMessageWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isUser = message.sender == ChatSender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.of(context).size.width * (isUser ? 0.78 : 0.88),
          ),
          padding: const EdgeInsets.all(AppDimensions.spacingMd + 2),
          decoration: BoxDecoration(
            gradient: isUser ? AppColors.aiGradient : null,
            color: isUser ? null : AppColors.surfaceFor(brightness),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Text(
            message.message,
            style: TextStyle(
              color:
                  isUser ? Colors.white : AppColors.textPrimaryFor(brightness),
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(brightness),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: const Text('AI is typing...'),
        ),
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _SuggestionChips({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final suggestions = [
      'Explain this topic',
      'Give me a quiz',
      'Summarize lesson',
      'Create flashcards',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingSm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((label) {
            return Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spacingSm),
              child: GestureDetector(
                onTap: () => onTap(label),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMd + 2,
                    vertical: AppDimensions.spacingXs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceFor(brightness),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryFor(brightness),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NovaInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isGenerating;
  final ValueChanged<String> onSend;

  const _NovaInputBar({
    required this.controller,
    required this.focusNode,
    required this.isGenerating,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingMd,
        AppDimensions.spacingSm,
        AppDimensions.spacingMd,
        MediaQuery.of(context).padding.bottom + AppDimensions.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(brightness),
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(color: AppColors.textPrimaryFor(brightness)),
              decoration: InputDecoration(
                hintText: 'Ask Nova anything...',
                hintStyle: TextStyle(
                    color: AppColors.textSecondaryFor(brightness)
                        .withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceFor(brightness),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (v) {
                if (!isGenerating && v.trim().isNotEmpty) onSend(v);
              },
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          GestureDetector(
            onTap: () {
              if (!isGenerating && controller.text.trim().isNotEmpty) {
                onSend(controller.text);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isGenerating ? null : AppColors.aiGradient,
                color: isGenerating
                    ? AppColors.textSecondaryFor(brightness)
                        .withValues(alpha: 0.2)
                    : null,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

