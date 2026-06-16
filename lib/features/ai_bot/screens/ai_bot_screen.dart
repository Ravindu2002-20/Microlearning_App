import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../../core/widgets/glass_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

enum MessageSender { user, nova }

class ChatMessageModel {
  final MessageSender sender;
  final String text;
  final DateTime timestamp;

  ChatMessageModel({
    required this.sender,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessageModel>>((ref) {
  return ChatNotifier();
});

final isNovaGeneratingProvider = StateProvider<bool>((ref) => false);

class ChatNotifier extends StateNotifier<List<ChatMessageModel>> {
  ChatNotifier() : super(_initialMessages);

  static final List<ChatMessageModel> _initialMessages = [
    ChatMessageModel(
      sender: MessageSender.nova,
      text:
          "Hi! I'm Nova, your AI learning assistant. I can help explain topics, create quizzes, summarize lessons, and make flashcards. What would you like to explore today?",
    ),
  ];

  void addMessage(String text) {
    if (text.trim().isEmpty) return;
    state = [
      ...state,
      ChatMessageModel(sender: MessageSender.user, text: text.trim())
    ];
  }

  void addNovaResponse(String text) {
    state = [
      ...state,
      ChatMessageModel(sender: MessageSender.nova, text: text)
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AiBotScreen — Nova AI Learning Assistant
// ─────────────────────────────────────────────────────────────────────────────

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
    if (text.trim().isEmpty) return;

    ref.read(chatMessagesProvider.notifier).addMessage(text);
    ref.read(isNovaGeneratingProvider.notifier).state = true;
    _textCtrl.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final lower = text.toLowerCase();
    String response;

    if (lower.contains('quiz') || lower.contains('test')) {
      response =
          "Great idea! Here's a quick quiz question:\n\nWhat does a neural network's activation function do?\n\n"
          "A) Stores training data\nB) Introduces non-linearity\nC) Reduces overfitting\nD) Normalizes inputs\n\n"
          "Try answering — I'll check it!";
    } else if (lower.contains('summarize') || lower.contains('summary')) {
      response =
          "Here's a quick summary structure:\n\n"
          "• **Main Idea**: Identify the core concept\n"
          "• **Key Points**: List 3-5 supporting details\n"
          "• **Example**: One concrete application\n"
          "• **Takeaway**: One sentence to remember\n\n"
          "Share a lesson and I'll summarize it for you!";
    } else if (lower.contains('flashcard') || lower.contains('card')) {
      response =
          "Flashcards are powerful! Here's a template:\n\n"
          "**Front**: What is gradient descent?\n"
          "**Back**: An optimization algorithm that minimizes the loss function by iteratively moving toward the steepest descent.\n\n"
          "I can generate a full set from any topic. Just say the word!";
    } else if (lower.contains('hello') || lower.contains('hi') ||
        lower.contains('hey')) {
      response =
          "Hey there! 👋 I'm ready to help you learn. Try asking me to explain a topic, or tap one of the suggestions below!";
    } else if (lower.contains('explain') || lower.contains('what is') ||
        lower.contains('how')) {
      response =
          "Let me break this down:\n\n"
          "**Core Concept**: This topic builds on foundational knowledge.\n\n"
          "**Key Components**:\n"
          "• First, understand the basic principles\n"
          "• Then, explore how components interact\n"
          "• Finally, apply it to real scenarios\n\n"
          "Would you like a deeper dive with examples?";
    } else if (lower.contains('network') || lower.contains('neural')) {
      response =
          "A neural network consists of:\n\n"
          "• **Input Layer** — Receives data features\n"
          "• **Hidden Layer(s)** — Processes through weighted connections\n"
          "• **Output Layer** — Produces the result\n\n"
          "Each connection has a weight that adjusts during training through backpropagation.";
    } else {
      response =
          "That's an interesting topic! Here's what I know:\n\n"
          "**Overview**: This area combines several key concepts worth exploring.\n\n"
          "**Quick Facts**:\n"
          "• Start with the fundamentals\n"
          "• Practice with examples\n"
          "• Review and reinforce daily\n\n"
          "Want me to create a quiz or flashcards to help you master it?";
    }

    ref.read(chatMessagesProvider.notifier).addNovaResponse(response);
    ref.read(isNovaGeneratingProvider.notifier).state = false;
    _scrollToBottom();
  }

  void _sendSuggestion(String text) {
    _textCtrl.text = text;
    _sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isGenerating = ref.watch(isNovaGeneratingProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _NovaHeader(isGenerating: isGenerating),
            const SizedBox(height: AppDimensions.spacingSm),
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingLg,
                  ),
                  itemCount: messages.length + (isGenerating ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (isGenerating && index == messages.length) {
                      return const _TypingIndicator();
                    }
                    final msg = messages[index];
                    return _ChatMessageWidget(message: msg);
                  },
                ),
              ),
            ),
            _SuggestionChips(onTap: _sendSuggestion),
            // Keep nav-like bottom inset handling consistent (avoid double padding).
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
}

// ═════════════════════════════════════════════════════════════════════════════
// Widgets
// ═════════════════════════════════════════════════════════════════════════════

// ── Nova Header ────────────────────────────────────────────────────────────

class _NovaHeader extends StatelessWidget {
  final bool isGenerating;
  const _NovaHeader({required this.isGenerating});

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
          _NovaAvatar(isGenerating: isGenerating),
          const SizedBox(width: AppDimensions.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nova',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
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
                      boxShadow: isGenerating
                          ? [
                              BoxShadow(
                                color: AppColors.accentAiSecondary
                                    .withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ]
                          : [],
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
          GlassButton(
            icon: Icons.more_horiz_rounded,
            onTap: () {},
            size: 38,
            iconColor: AppColors.textSecondaryDark,
          ),
        ],
      ),
    );
  }
}

// ── Nova Avatar with animated glow ─────────────────────────────────────────

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
  void didUpdateWidget(_NovaAvatar old) {
    super.didUpdateWidget(old);
    if (widget.isGenerating != old.isGenerating) {
      _controller.duration = Duration(
        milliseconds: widget.isGenerating ? 800 : 2000,
      );
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
        final glowOpacity = 0.2 + (_controller.value * 0.35);
        final blurRadius = 10.0 + (_controller.value * 14.0);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.aiGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentAiPrimary
                      .withValues(alpha: glowOpacity),
                  blurRadius: blurRadius,
                  spreadRadius: 1 + (_controller.value * 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Chat Message Bubble ────────────────────────────────────────────────────

class _ChatMessageWidget extends StatelessWidget {
  final ChatMessageModel message;
  const _ChatMessageWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width *
                (isUser ? 0.78 : 0.88),
          ),
          padding: const EdgeInsets.all(AppDimensions.spacingMd + 2),
          decoration: BoxDecoration(
            gradient: isUser ? AppColors.aiGradient : null,
            color: isUser ? null : AppColors.surfaceDark,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppDimensions.radiusLg),
              topRight: const Radius.circular(AppDimensions.radiusLg),
              bottomLeft: Radius.circular(
                isUser ? AppDimensions.radiusLg : AppDimensions.radiusXs,
              ),
              bottomRight: Radius.circular(
                isUser ? AppDimensions.radiusXs : AppDimensions.radiusLg,
              ),
            ),
            border: isUser
                ? null
                : Border.all(
                    color: AppColors.textSecondaryDark
                        .withValues(alpha: 0.1),
                  ),
          ),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              _RichMessageContent(text: message.text, isUser: isUser),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.textSecondaryDark
                          .withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Rich Message Content ───────────────────────────────────────────────────

class _RichMessageContent extends StatelessWidget {
  final String text;
  final bool isUser;
  const _RichMessageContent({
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final hasBullets = lines.any((l) =>
        l.trimLeft().startsWith('•') || l.trimLeft().startsWith('-'));

    if (hasBullets) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildBulletList(lines, isUser),
      );
    }
    if (text.contains('A)') && text.contains('B)')) {
      return _buildQuizContent(lines, isUser);
    }
    return _buildFormattedText(text, user: isUser);
  }

  List<Widget> _buildBulletList(List<String> lines, bool user) {
    final widgets = <Widget>[];
    for (final line in lines) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('•') || trimmed.startsWith('-')) {
        final bulletText =
            trimmed.replaceFirst(RegExp(r'^[•\-]\s*'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•  ',
                style: TextStyle(
                  color: user
                      ? Colors.white
                      : AppColors.accentAiSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Expanded(
                child: _buildFormattedText(
                  bulletText,
                  user: user,
                  defaultColor: user
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
        ));
      } else if (trimmed.startsWith('**') && trimmed.endsWith('**')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 4),
          child: Text(
            trimmed.replaceAll('**', ''),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color:
                  user ? Colors.white : AppColors.textPrimaryDark,
            ),
          ),
        ));
      } else if (trimmed.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildFormattedText(
            trimmed,
            user: user,
            defaultColor: user
                ? Colors.white.withValues(alpha: 0.9)
                : AppColors.textPrimaryDark,
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _buildQuizContent(List<String> lines, bool user) {
    final color =
        user ? Colors.white : AppColors.textPrimaryDark;
    final muted = user
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.textSecondaryDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return const SizedBox(height: 4);
        if (trimmed.startsWith('A)') ||
            trimmed.startsWith('B)') ||
            trimmed.startsWith('C)') ||
            trimmed.startsWith('D)')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 8),
            child: Text(
              trimmed,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            trimmed,
            style: TextStyle(
              fontSize: 14,
              color: trimmed.startsWith('**') ? color : muted,
              fontWeight: trimmed.startsWith('**')
                  ? FontWeight.w800
                  : FontWeight.w400,
              height: 1.4,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormattedText(
    String text, {
    required bool user,
    Color? defaultColor,
  }) {
    final color = defaultColor ??
        (user ? Colors.white : AppColors.textPrimaryDark);
    final regex = RegExp(r'\*\*(.*?)\*\*');
    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: color,
          height: 1.5,
        ),
      );
    }
    final spans = <InlineSpan>[];
    int lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style:
              TextStyle(fontSize: 15, color: color, height: 1.5),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontSize: 15,
          color: user
              ? Colors.white
              : AppColors.textPrimaryDark,
          fontWeight: FontWeight.w800,
          height: 1.5,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(fontSize: 15, color: color, height: 1.5),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}

// ── Typing Indicator ───────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusLg),
              topRight: Radius.circular(AppDimensions.radiusLg),
              bottomRight: Radius.circular(AppDimensions.radiusLg),
              bottomLeft: Radius.circular(AppDimensions.radiusXs),
            ),
            border: Border.all(
              color: AppColors.textSecondaryDark
                  .withValues(alpha: 0.1),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(0),
                  const SizedBox(width: 4),
                  _dot(1),
                  const SizedBox(width: 4),
                  _dot(2),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  Widget _dot(int index) {
    final opacity =
        ((_controller.value * 3 + index) % 1.0).clamp(0.3, 1.0);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentAiPrimary
            .withValues(alpha: opacity),
      ),
    );
  }
}

// ── Suggestion Chips ───────────────────────────────────────────────────────

class _SuggestionChips extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _SuggestionChips({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      _ChipData(Icons.explore_outlined, 'Explain this topic'),
      _ChipData(Icons.quiz_outlined, 'Give me a quiz'),
      _ChipData(Icons.summarize_outlined, 'Summarize lesson'),
      _ChipData(Icons.auto_stories_outlined, 'Create flashcards'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingSm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((chip) {
            return Padding(
              padding: const EdgeInsets.only(
                  right: AppDimensions.spacingSm),
              child: GestureDetector(
                onTap: () => onTap(chip.label),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMd + 2,
                    vertical: AppDimensions.spacingXs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull),
                    border: Border.all(
                      color: AppColors.textSecondaryDark
                          .withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        chip.icon,
                        size: 16,
                        color: AppColors.accentAiSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        chip.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ],
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

class _ChipData {
  final IconData icon;
  final String label;
  const _ChipData(this.icon, this.label);
}

// ── Input Bar ──────────────────────────────────────────────────────────────

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
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingMd,
        AppDimensions.spacingSm,
        AppDimensions.spacingMd,
        MediaQuery.of(context).padding.bottom + AppDimensions.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMd),
                border: Border.all(
                  color: AppColors.textSecondaryDark
                      .withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask Nova anything...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondaryDark
                        .withValues(alpha: 0.5),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingLg,
                    vertical: AppDimensions.spacingMd + 2,
                  ),
                ),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (v) {
                  if (!isGenerating && v.trim().isNotEmpty) onSend(v);
                },
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textSecondaryDark
                      .withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                Icons.mic_outlined,
                color: AppColors.textSecondaryDark,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          GestureDetector(
            onTap: () {
              if (!isGenerating &&
                  controller.text.trim().isNotEmpty) {
                onSend(controller.text);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isGenerating
                    ? LinearGradient(
                        colors: [
                          AppColors.textSecondaryDark
                              .withValues(alpha: 0.3),
                          AppColors.textSecondaryDark
                              .withValues(alpha: 0.3),
                        ],
                      )
                    : AppColors.aiGradient,
                shape: BoxShape.circle,
                boxShadow: isGenerating
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.accentAiPrimary
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                isGenerating
                    ? Icons.hourglass_empty_rounded
                    : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}