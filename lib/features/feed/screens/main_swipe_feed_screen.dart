import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/constants.dart';
import '../../../core/services/context_engine_service.dart';
import '../../learning/models/lesson_model.dart';
import '../controllers/feed_providers.dart';

// ═════════════════════════════════════════════════════════════════════════════
// MainSwipeFeedScreen — TikTok-style vertical lesson feed with quiz variants
// ═════════════════════════════════════════════════════════════════════════════

class MainSwipeFeedScreen extends ConsumerStatefulWidget {
  const MainSwipeFeedScreen({super.key});

  @override
  ConsumerState<MainSwipeFeedScreen> createState() =>
      _MainSwipeFeedScreenState();
}

class _MainSwipeFeedScreenState extends ConsumerState<MainSwipeFeedScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _xpController;

  int _pageIndex = 0;
  int? _selectedAnswer;
  bool _revealed = false;
  bool _answerCorrect = false;
  OverlayEntry? _xpEntry;

  @override
  void initState() {
    super.initState();
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _xpEntry?.remove();
    _pageController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  void _resetQuiz() {
    _selectedAnswer = null;
    _revealed = false;
    _answerCorrect = false;
  }

  void _showXpReward(BuildContext context, String xp) {
    _xpEntry?.remove();
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).padding.top + 96,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Opacity(
                  opacity: (1 - value).clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, -24 * value),
                    child: Transform.scale(
                      scale: 0.92 + (0.12 * value),
                      child: child,
                    ),
                  ),
                );
              },
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.aiGradient,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    '$xp earned',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    _xpEntry = entry;
    Future.delayed(const Duration(milliseconds: 900), () {
      _xpEntry?.remove();
      _xpEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contextAsync = ref.watch(contextStateStreamProvider);

    return contextAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const _FeedSkeleton(),
      ),
      error: (err, st) => Scaffold(
        body: _ErrorState(
          message: 'We could not load the lessons feed.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(contextStateStreamProvider),
        ),
      ),
      data: (currentContext) {
        final lessonsAsync = ref.watch(
          adaptiveLessonFeedProvider(currentContext),
        );

        return lessonsAsync.when(
          loading: () => Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: const _FeedSkeleton(),
          ),
          error: (err, st) => Scaffold(
            body: _ErrorState(
              message: 'Failed to load lessons from the server.',
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(
                adaptiveLessonFeedProvider(currentContext),
              ),
            ),
          ),
          data: (lessons) {
            if (lessons.isEmpty) {
              return Scaffold(
                backgroundColor: AppColors.backgroundDark,
                body: _EmptyFeedPlaceholder(
                  contextState: currentContext,
                  onRefresh: () => ref.invalidate(
                    adaptiveLessonFeedProvider(currentContext),
                  ),
                ),
              );
            }

            final feedItems = lessons
                .map((l) => _FeedItemMapper.toFeedItem(l, lessons.indexOf(l)))
                .toList();

            // Inject quiz cards between lessons
            final displayItems = _injectQuizCards(feedItems);

            return Scaffold(
              backgroundColor: AppColors.backgroundDark,
              body: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (index) {
                      setState(() {
                        _pageIndex = index;
                        _resetQuiz();
                      });
                    },
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      if (item.kind == _LessonKind.quiz) {
                        return _QuizFeedPage(
                          item: item,
                          revealed: _revealed,
                          selectedAnswer: _selectedAnswer,
                          answerCorrect: _answerCorrect,
                          onSelect: (answerIndex) {
                            if (_revealed) return;
                            final correct =
                                answerIndex == item.correctAnswerIndex;
                            setState(() {
                              _selectedAnswer = answerIndex;
                              _revealed = true;
                              _answerCorrect = correct;
                            });
                            if (correct) {
                              _showXpReward(context, item.xpReward);
                            }
                          },
                        );
                      }

                      return _LessonFeedPage(
                        item: item,
                        contextState: currentContext,
                        onLike: () => _onLike(item),
                        onBookmark: () => _onBookmark(item),
                        onShare: () => _onShare(item),
                        onQuiz: () {
                          _pageController.animateToPage(
                            math.min(index + 1, displayItems.length - 1),
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      );
                    },
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: MediaQuery.of(context).padding.top + 10,
                    child: SafeArea(
                      bottom: false,
                      child: _ContextOverlays(contextState: currentContext),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).padding.bottom + 86,
                    child: _LessonScrubber(
                      activeIndex: _pageIndex,
                      count: displayItems.length,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onLike(_FeedItem item) {
    // TODO: persist like to Supabase
    debugPrint('Liked: ${item.title}');
  }

  void _onBookmark(_FeedItem item) {
    // TODO: persist bookmark to Supabase
    debugPrint('Bookmarked: ${item.title}');
  }

  void _onShare(_FeedItem item) {
    // TODO: open share sheet
    debugPrint('Share: ${item.title}');
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

List<_FeedItem> _injectQuizCards(List<_FeedItem> lessons) {
  final items = <_FeedItem>[];
  for (var i = 0; i < lessons.length; i++) {
    items.add(lessons[i]);
    // Insert a quiz card after every 2 lessons (if not the last)
    if ((i + 1) % 2 == 0 && i < lessons.length - 1) {
      final quizIndex = (i ~/ 2) % _quizBank.length;
      items.add(_quizBank[quizIndex]);
    }
  }
  return items;
}

// ── Feed Item Type ─────────────────────────────────────────────────────────

enum _LessonKind { lesson, quiz }

class _FeedItem {
  final _LessonKind kind;
  final String id;
  final String subject;
  final String title;
  final String description;
  final String instructor;
  final Gradient videoGradient;
  final LessonModel? sourceLesson;
  final String? question;
  final List<String> answers;
  final int correctAnswerIndex;
  final String xpReward;

  const _FeedItem({
    required this.kind,
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.instructor,
    required this.videoGradient,
    this.sourceLesson,
    this.question,
    this.answers = const [],
    this.correctAnswerIndex = 0,
    this.xpReward = '+50 XP',
  });
}

// ── Map LessonModel from DB → _FeedItem ────────────────────────────────────

class _FeedItemMapper {
  static _FeedItem toFeedItem(LessonModel lesson, int index) {
    final gradients = [
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5B5FFF), Color(0xFF00D4FF)],
      ),
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7B61FF), Color(0xFF00E5FF)],
      ),
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFB547), Color(0xFFFF7A45)],
      ),
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00C781), Color(0xFF62E5A6)],
      ),
    ];

    return _FeedItem(
      kind: _LessonKind.lesson,
      id: lesson.id,
      subject: lesson.category,
      title: lesson.title,
      description: lesson.description,
      instructor: 'Instructor', // DB should have instructor field; fallback
      videoGradient: gradients[index % gradients.length],
      sourceLesson: lesson,
    );
  }
}

// ── Quiz Bank ──────────────────────────────────────────────────────────────

const _quizBank = [
  _FeedItem(
    kind: _LessonKind.quiz,
    id: 'quiz_physics',
    subject: 'Quiz',
    title: 'Physics Challenge',
    description: '',
    instructor: '',
    videoGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF131B33), Color(0xFF1A2342)],
    ),
    question: 'Which force keeps planets in orbit around the Sun?',
    answers: [
      'Magnetic force',
      'Gravitational force',
      'Frictional force',
      'Nuclear force',
    ],
    correctAnswerIndex: 1,
    xpReward: '+50 XP',
  ),
  _FeedItem(
    kind: _LessonKind.quiz,
    id: 'quiz_science',
    subject: 'Quiz',
    title: 'Science Quick Quiz',
    description: '',
    instructor: '',
    videoGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF131B33), Color(0xFF1A2342)],
    ),
    question: 'What is the chemical symbol for water?',
    answers: ['H2O', 'CO2', 'NaCl', 'O2'],
    correctAnswerIndex: 0,
    xpReward: '+30 XP',
  ),
  _FeedItem(
    kind: _LessonKind.quiz,
    id: 'quiz_math',
    subject: 'Quiz',
    title: 'Math Quick Quiz',
    description: '',
    instructor: '',
    videoGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF131B33), Color(0xFF1A2342)],
    ),
    question: 'What is the value of Pi (π) to two decimal places?',
    answers: ['3.14', '3.16', '3.12', '3.18'],
    correctAnswerIndex: 0,
    xpReward: '+25 XP',
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
// Lesson Feed Page — Full-screen vertical lesson card
// ═════════════════════════════════════════════════════════════════════════════

class _LessonFeedPage extends StatelessWidget {
  final _FeedItem item;
  final UserContextState contextState;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onQuiz;

  const _LessonFeedPage({
    required this.item,
    required this.contextState,
    required this.onLike,
    required this.onBookmark,
    required this.onShare,
    required this.onQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final motionAccent =
        contextState.isInMotion ? AppColors.secondaryDark : AppColors.primaryDark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video background gradient
        Container(
          decoration: BoxDecoration(gradient: item.videoGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.16,
                  child: CustomPaint(
                    painter: _VideoTexturePainter(),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                top: -30,
                child: _FloatingGlow(color: motionAccent.withValues(alpha: 0.45)),
              ),
              Positioned(
                right: -20,
                bottom: 100,
                child: _FloatingGlow(
                    color: AppColors.secondaryDark.withValues(alpha: 0.35)),
              ),
              // Play button indication (simulated video)
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.24)),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 48),
                ),
              ),
            ],
          ),
        ),
        // Gradient overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.18),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.20),
                Colors.black.withValues(alpha: 0.72),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              children: [
                // Top chips
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _GlassChip(
                            label: item.subject,
                            icon: Icons.school_outlined,
                            color: Colors.white,
                          ),
                          _GlassChip(
                            label: _networkLabel(contextState.networkStrength),
                            icon: _networkIcon(contextState.networkStrength),
                            color: _contextTint(contextState.networkStrength),
                          ),
                          _GlassChip(
                            label: contextState.isInMotion
                                ? 'Walking'
                                : 'Stationary',
                            icon: contextState.isInMotion
                                ? Icons.directions_walk_outlined
                                : Icons.self_improvement_outlined,
                            color: contextState.isInMotion
                                ? AppColors.secondaryDark
                                : AppColors.primaryDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _MiniGlassButton(icon: Icons.more_horiz_rounded, onTap: () {}),
                  ],
                ),
                const Spacer(),
                // Bottom content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.02,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 14,
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'By ${item.instructor}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.74),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action buttons
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          icon: Icons.favorite_border_rounded,
                          label: 'Like',
                          onTap: onLike,
                        ),
                        const SizedBox(height: 12),
                        _ActionButton(
                          icon: Icons.bookmark_border_rounded,
                          label: 'Save',
                          onTap: onBookmark,
                        ),
                        const SizedBox(height: 12),
                        _ActionButton(
                          icon: Icons.ios_share_rounded,
                          label: 'Share',
                          onTap: onShare,
                        ),
                        const SizedBox(height: 12),
                        _ActionButton(
                          icon: Icons.quiz_outlined,
                          label: 'Quiz',
                          onTap: onQuiz,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Quiz Feed Page — Full-screen interactive quiz
// ═════════════════════════════════════════════════════════════════════════════

class _QuizFeedPage extends StatelessWidget {
  final _FeedItem item;
  final bool revealed;
  final int? selectedAnswer;
  final bool answerCorrect;
  final ValueChanged<int> onSelect;

  const _QuizFeedPage({
    required this.item,
    required this.revealed,
    required this.selectedAnswer,
    required this.answerCorrect,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surface =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bg,
                surface,
                AppColors.quizGradient.colors.last.withValues(alpha: 0.12),
              ],
            ),
          ),
        ),
        Positioned(
          left: -24,
          top: 88,
          child: _FloatingGlow(
              color: AppColors.primaryDark.withValues(alpha: 0.12)),
        ),
        Positioned(
          right: -20,
          bottom: 120,
          child: _FloatingGlow(
              color: AppColors.success.withValues(alpha: 0.12)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassChip(
                  label: 'Quiz Mode',
                  icon: Icons.auto_awesome_outlined,
                  color: AppColors.success,
                ),
                const Spacer(),
                AnimatedScale(
                  scale: revealed ? 1.0 : 0.98,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  child: Text(
                    item.question ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ...List.generate(item.answers.length, (index) {
                  final selected = selectedAnswer == index;
                  final isCorrect = index == item.correctAnswerIndex;
                  Color background = surface;
                  Color foreground = textPrimary;

                  if (revealed) {
                    if (isCorrect) {
                      background = AppColors.success;
                      foreground = Colors.white;
                    } else if (selected) {
                      background = AppColors.error;
                      foreground = Colors.white;
                    }
                  } else if (selected) {
                    background = AppColors.primaryDark.withValues(alpha: 0.12);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: revealed && isCorrect
                              ? AppColors.success
                              : selected
                                  ? AppColors.primaryDark
                                      .withValues(alpha: 0.45)
                                  : Colors.black.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: revealed ? null : () => onSelect(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 18),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: revealed && isCorrect
                                        ? Colors.white.withValues(alpha: 0.22)
                                        : AppColors.primaryDark
                                            .withValues(alpha: 0.10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index),
                                      style: TextStyle(
                                        color: foreground,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item.answers[index],
                                    style: TextStyle(
                                      color: foreground,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: revealed ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    answerCorrect
                        ? 'Correct answer unlocked.'
                        : 'Try again next time.',
                    style: TextStyle(
                      color: answerCorrect ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppColors.aiGradient,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.xpReward,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Context Overlays — Top chips for network & motion state
// ═════════════════════════════════════════════════════════════════════════════

class _ContextOverlays extends StatelessWidget {
  final UserContextState contextState;

  const _ContextOverlays({required this.contextState});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _GlassChip(
          label: switch (contextState.networkStrength) {
            AppNetworkStrength.weak => 'Weak Network',
            AppNetworkStrength.medium => 'Strong Network',
            AppNetworkStrength.strong => 'Strong Network',
          },
          icon: switch (contextState.networkStrength) {
            AppNetworkStrength.weak => Icons.wifi_off_outlined,
            AppNetworkStrength.medium => Icons.network_wifi_1_bar_outlined,
            AppNetworkStrength.strong => Icons.wifi_outlined,
          },
          color: switch (contextState.networkStrength) {
            AppNetworkStrength.weak => AppColors.warning,
            AppNetworkStrength.medium => AppColors.primaryDark,
            AppNetworkStrength.strong => AppColors.primaryDark,
          },
        ),
        _GlassChip(
          label: contextState.isInMotion ? 'Walking' : 'Stationary',
          icon: contextState.isInMotion
              ? Icons.directions_walk_outlined
              : Icons.self_improvement_outlined,
          color: contextState.isInMotion
              ? AppColors.secondaryDark
              : AppColors.primaryDark,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Lesson Scrubber — Bottom progress bar
// ═════════════════════════════════════════════════════════════════════════════

class _LessonScrubber extends StatelessWidget {
  final int activeIndex;
  final int count;

  const _LessonScrubber({
    required this.activeIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (activeIndex + 1) / count;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          minHeight: 4,
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.16),
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.secondaryDark),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Reusable Widgets
// ═════════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MiniGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniGlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _GlassChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingGlow extends StatelessWidget {
  final Color color;

  const _FloatingGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Helper utilities
// ═════════════════════════════════════════════════════════════════════════════

class _VideoTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      paint.color = Colors.white.withValues(alpha: 0.06 + (i * 0.02));
      paint.strokeWidth = 1;
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5),
        80 + (i * 28),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Empty State (when no lessons returned from DB) ──────────────────────────

class _EmptyFeedPlaceholder extends StatelessWidget {
  final UserContextState contextState;
  final VoidCallback onRefresh;

  const _EmptyFeedPlaceholder({
    required this.contextState,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.aiGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.school_outlined,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'No lessons available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'re adapting content to your current context.\nCheck back shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading / Error States ─────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _ErrorState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 58, color: AppColors.secondaryDark),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _FeedSkeleton extends StatefulWidget {
  const _FeedSkeleton();

  @override
  State<_FeedSkeleton> createState() => _FeedSkeletonState();
}

class _FeedSkeletonState extends State<_FeedSkeleton>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, -0.2),
              end: Alignment(1 + _controller.value * 2, 0.2),
              colors: const [
                Color(0xFF131B33),
                Color(0xFF1A2342),
                Color(0xFF131B33),
              ],
            ),
          ),
          child: child,
        );
      },
      child: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ShimmerLine(width: 180, height: 20),
                SizedBox(height: 16),
                _ShimmerLine(width: double.infinity, height: 300, radius: 28),
                SizedBox(height: 16),
                _ShimmerLine(width: 260, height: 18),
                SizedBox(height: 12),
                _ShimmerLine(width: 320, height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerLine({
    required this.width,
    required this.height,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.isFinite ? width : MediaQuery.of(context).size.width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A2342),
            Color(0xFF28345E),
            Color(0xFF1A2342),
          ],
        ),
      ),
    );
  }
}

// ── Network helpers ────────────────────────────────────────────────────────

String _networkLabel(AppNetworkStrength strength) {
  return switch (strength) {
    AppNetworkStrength.weak => 'Weak Network',
    AppNetworkStrength.medium => 'Stable Network',
    AppNetworkStrength.strong => 'Strong Network',
  };
}

IconData _networkIcon(AppNetworkStrength strength) {
  return switch (strength) {
    AppNetworkStrength.weak => Icons.wifi_off_outlined,
    AppNetworkStrength.medium => Icons.network_wifi_1_bar_outlined,
    AppNetworkStrength.strong => Icons.wifi_outlined,
  };
}

Color _contextTint(AppNetworkStrength strength) {
  return switch (strength) {
    AppNetworkStrength.weak => AppColors.warning,
    AppNetworkStrength.medium => AppColors.primaryDark,
    AppNetworkStrength.strong => AppColors.secondaryDark,
  };
}