import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'core/theme/app_theme.dart';
import 'core/constants/constants.dart';
import 'core/services/admin_service.dart';
import 'core/services/session_manager.dart';
import 'core/services/theme_service.dart';
import 'features/auth/repositaries/auth_repository.dart';
import 'features/auth/repositaries/user_preferences_repository.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/user_details_onboarding_screen.dart';
import 'core/widgets/main_app_shell.dart';
import 'core/widgets/admin_app_shell.dart';

// ─── Global Providers ───────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>((ref) {
  return UserPreferencesRepository(Supabase.instance.client);
});

// ─── Entry Point ────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(

    url: 'https://qjbcmjmaowvxlitvzrqh.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqYmNtam1hb3d2eGxpdHZ6cnFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwMzY0NzcsImV4cCI6MjA5NTYxMjQ3N30.uCC1_9uupE4GULc0_eAqxiQyMPnvU0m6KmDcHGfTma4',
  );

  runApp(const ProviderScope(child: MyApp()));
}

// ─── Root App ───────────────────────────────────────────────────────────────

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MicroLearn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeProvider),
      home: const _AppRouter(),
    );
  }
}

// ─── App Router — Manages splash → onboarding → auth → home flow ──────────

class _AppRouter extends ConsumerStatefulWidget {
  const _AppRouter();

  @override
  ConsumerState<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<_AppRouter> {
  bool _initialNavigationDone = false;

  Future<void> _navigateToAppropriateScreen({required User? user}) async {
    if (!mounted) return;
    final nav = Navigator.of(context);

    if (user == null) {
      // No session: onboarding once, then login.
      final completedOnboarding = ref.read(hasCompletedOnboardingProvider);
      if (!completedOnboarding) {
        nav.pushReplacement(_fadeRoute(const OnboardingScreen()));
        return;
      }

      nav.pushReplacement(_fadeRoute(const AuthScreen()));
      return;
    }

    // Session exists
    final prefsRepo = ref.read(userPreferencesRepositoryProvider);
    final hasUserDetails = await prefsRepo.isOnboardingComplete(user.id);

    if (!mounted) return;

    if (!hasUserDetails) {
      nav.pushReplacement(_fadeRoute(const UserDetailsOnboardingScreen()));
      return;
    }

    final isAdmin = await ref.read(isAdminProvider.future);
    if (!mounted) return;

    nav.pushReplacement(
        _fadeRoute(isAdmin ? const AdminAppShell() : const MainAppShell()));
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(sessionUserProvider);

    // Always listen for logout after initial navigation happened.
    ref.listen(sessionUserProvider, (previous, next) {
      if (!mounted) return;

      final prevUser = previous?.valueOrNull;
      final nextUser = next.valueOrNull;

      if (!_initialNavigationDone) return;

      // Logout flow
      if (prevUser != null && nextUser == null) {
        Navigator.of(context).pushAndRemoveUntil(
          _fadeRoute(const AuthScreen()),
          (_) => false,
        );
        return;
      }

      if (prevUser == null && nextUser != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _navigateToAppropriateScreen(user: nextUser);
        });
      }
    });

    // Perform initial navigation exactly once, when auth stream resolves.
    return authAsync.when(
      loading: () {
        return const Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        );
      },
      error: (err, st) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Auth error. Please restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      data: (user) {
        if (!_initialNavigationDone) {
          _initialNavigationDone = true;
          // Run navigation after current frame so Navigator has a context.
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final nav = Navigator.of(context);
            try {
              await _navigateToAppropriateScreen(user: user);
            } catch (_) {
              if (!mounted) return;
              // Fail safe: go to login.
              nav.pushAndRemoveUntil(
                _fadeRoute(const AuthScreen()),
                (_) => false,
              );
            }
          });
        }

        return const Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SplashLogo(),
                SizedBox(height: AppDimensions.spacingLg),
                Text(
                  'MicroLearn',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingXs),
                Text(
                  'Learn smarter, anywhere',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingXxl + 8),
              ],
            ),
          ),
        );
      },
    );
  }

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, _) => page,
      transitionsBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }
}

class _SplashLogo extends StatefulWidget {
  const _SplashLogo();

  @override
  State<_SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<_SplashLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.05),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.centerButtonGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.35),
                  blurRadius: 24 + (_controller.value * 12),
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
        );
      },
    );
  }
}
