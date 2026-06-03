import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/feed_providers.dart';
import '../../../core/services/context_engine_service.dart';

import '../widgets/context_status_banner.dart';
import '../widgets/lesson_cards.dart';
import '../../learning/models/lesson_model.dart';

class MainSwipeFeedScreen extends ConsumerStatefulWidget {
  const MainSwipeFeedScreen({super.key});

  @override
  ConsumerState<MainSwipeFeedScreen> createState() => _MainSwipeFeedScreenState();
}

class _MainSwipeFeedScreenState extends ConsumerState<MainSwipeFeedScreen> {
  final PageController _pageController = PageController();

  UserContextState? _currentContext;
  List<LessonModel> _lessons = const [];

  AppNetworkStrength? _prevNetwork;


  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      final currentPage = _pageController.page?.round() ?? 0;
      if (_currentContext == null) return;

      if (currentPage >= _lessons.length - 2) {
        ref.invalidate(adaptiveLessonFeedProvider(_currentContext!));
      }
    });

    // Network transition toast
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _currentContext;
      if (ctx == null) return;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Set up listener once
    ref.listen<AsyncValue<UserContextState>>(
      contextStateStreamProvider,
      (prev, next) async {
        if (!next.hasValue) return;
        final cur = next.value!;

        final previous = _prevNetwork;
        _prevNetwork = cur.networkStrength;

        if (previous == null) return;

        if (previous != cur.networkStrength) {
          final messenger = ScaffoldMessenger.of(context);
          if (cur.networkStrength == AppNetworkStrength.weak) {
            messenger.showSnackBar(const SnackBar(
              content: Text('⚠️ Weak signal detected — switching to offline-friendly content'),
            ));
          } else if (cur.networkStrength == AppNetworkStrength.strong &&
              previous != AppNetworkStrength.strong) {
            messenger.showSnackBar(const SnackBar(
              content: Text('✓ Strong connection restored — full content available'),
            ));
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeCurrentLesson(LessonModel lesson) async {
    final userUuid = Supabase.instance.client.auth.currentUser?.id;
    if (userUuid == null) return;

    try {
      await ref
          .read(learningRepositoryProvider)
          .logLessonCompletion(userUuid: userUuid, lessonId: int.parse(lesson.id), score: 100);
    } catch (_) {
      // ignore
    }

    if (_currentContext != null) {
      ref.invalidate(adaptiveLessonFeedProvider(_currentContext!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contextAsync = ref.watch(contextStateStreamProvider);

    return contextAsync.when(
      loading: () {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Initializing sensors...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        );
      },
      error: (err, st) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error: ${err.toString()}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
      data: (currentContext) {
        _currentContext ??= currentContext;
        _currentContext = currentContext;

        final feedAsync = ref.watch(adaptiveLessonFeedProvider(currentContext));

        return feedAsync.when(
          loading: () {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Fetching lessons for your context...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          },
          error: (err, st) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${err.toString()}',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(adaptiveLessonFeedProvider(currentContext));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          data: (lessons) {
            _lessons = lessons;

            if (lessons.isEmpty) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 60, color: Colors.greenAccent),
                      SizedBox(height: 14),
                      Text(
                        "You've completed all available lessons for this context! Check back later.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Scaffold(
              body: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    pageSnapping: true,
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      return Stack(
                        children: [
                          _buildLessonCard(lesson, ref),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 20,
                            child: SafeArea(
                              top: false,
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _completeCurrentLesson(lesson),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Complete (100 XP)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ContextStatusBanner(contextState: currentContext),
                  ),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Learn'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                ],
                currentIndex: 0,
                onTap: (i) {},
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLessonCard(LessonModel lesson, WidgetRef ref) {
    switch (lesson.format) {
      case 'text':
        return TextLessonCard(lesson: lesson);
      case 'quiz':
        return QuizLessonCard(lesson: lesson);
      case 'video':
        return VideoLessonCard(lesson: lesson);
      case 'audio':
        return AudioLessonCard(lesson: lesson);
      default:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black87,
          alignment: Alignment.center,
          child: Text(
            lesson.title,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        );
    }
  }
}

