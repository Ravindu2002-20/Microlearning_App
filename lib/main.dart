import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/constants.dart';
import 'core/services/admin_service.dart';
import 'core/services/session_manager.dart';
import 'core/services/theme_service.dart';
import 'features/auth/repositaries/auth_repository.dart';
import 'features/auth/repositaries/user_preferences_repository.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_registration_screen.dart';
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
  @override
  void initState() {
    super.initState();

    // Only one navigation source of truth: listen to auth state.
    // Keep splash visible briefly, but don't route until auth stream has data.
    Future.delayed(const Duration(milliseconds: 1200), () {
      // Trigger rebuild so Riverpod listener can start producing events.
      if (mounted) setState(() {});
    });
  }



  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondary) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionUserProvider, (previous, next) async {
      // Only navigation source of truth.
      // The router is driven by the auth stream events.
      if (!mounted) return;

      // Re-route on logout -> auth
      final prevUser = previous?.valueOrNull;
      final nextUser = next.valueOrNull;

      // (If needed, previous/next can be null during loading.)




      if (prevUser != null && nextUser == null) {
        Navigator.of(context).pushAndRemoveUntil(
          _fadeRoute(const LoginRegistrationScreen()),
          (_) => false,
        );
        return;
      }

      // Re-route on login (null -> user) so admin vs user dashboard swaps
      if (prevUser == null && nextUser != null) {
        final completedOnboarding = ref.read(hasCompletedOnboardingProvider);
        if (!completedOnboarding) {
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushReplacement(
            _fadeRoute(const OnboardingScreen()),
          );
          return;
        }

        final prefsRepo = ref.read(userPreferencesRepositoryProvider);
        final hasUserDetails = await prefsRepo.isOnboardingComplete(nextUser.id);

        if (!mounted) return;
        if (!hasUserDetails) {
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushReplacement(
            _fadeRoute(const UserDetailsOnboardingScreen()),
          );
          return;
        }

        // Check admin before routing
        final isAdmin = await ref.read(isAdminProvider.future);

        if (!mounted) return;
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          _fadeRoute(isAdmin ? const AdminAppShell() : const MainAppShell()),
        );
      }



    });

    // Branded splash screen
    return const Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with glow
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
  }
}

class _SplashLogo extends StatefulWidget {
  const _SplashLogo({super.key});




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
