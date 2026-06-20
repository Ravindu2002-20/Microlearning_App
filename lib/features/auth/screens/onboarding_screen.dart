import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/onboarding_persistence.dart';
import '../../../core/widgets/main_app_shell.dart';
import '../../../main.dart';





// ─────────────────────────────────────────────────────────────────────────────
// Provider to track onboarding completion (persistent via shared_preferences)
// ─────────────────────────────────────────────────────────────────────────────

final hasCompletedOnboardingProvider =
    StateNotifierProvider<HasCompletedOnboardingController, bool>((ref) {
  final persistence = ref.read(onboardingPersistenceProvider);
  return HasCompletedOnboardingController(persistence: persistence);
});



class HasCompletedOnboardingController extends StateNotifier<bool> {
  HasCompletedOnboardingController({required this.persistence}) : super(false) {
    _init();
  }

  final OnboardingPersistence persistence;

  Future<void> _init() async {
    state = await persistence.readCompleted();
    if (state != true) state = false;
  }





  Future<void> complete() async {
    await persistence.writeCompleted();
    state = true;
  }
}




// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen — Swipeable slides (first launch only)
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  final _slides = const [
    _SlideData(
      icon: Icons.timer_outlined,
      headline: 'Learn in 60 Seconds',
      subtitle:
          'Bite-sized lessons that fit into your busiest day. Master any topic in just one minute.',
    ),
    _SlideData(
      icon: Icons.sensors_outlined,
      headline: 'Adapts to Your World',
      subtitle:
          'Context-aware content that adjusts whether you\'re walking, sitting, or on the go.',
    ),
    _SlideData(
      icon: Icons.emoji_events_outlined,
      headline: 'Compete and Grow',
      subtitle:
          'Climb the leaderboard, earn XP, and unlock achievements as you learn.',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goToAuth();
    }
  }

  void _goToAuth() {
    ref.read(hasCompletedOnboardingProvider.notifier).complete();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondary) =>
            const AuthScreen(),

        transitionsBuilder: (context, animation, secondary, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingSm,
                AppDimensions.spacingLg,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < _slides.length - 1)
                    GestureDetector(
                      onTap: _goToAuth,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, index) =>
                    _SlideContent(slide: _slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingXxl,
                0,
                AppDimensions.spacingXxl,
                AppDimensions.spacingXxl,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: _currentPage == i
                              ? AppColors.aiGradient
                              : LinearGradient(colors: [
                                  AppColors.textSecondaryDark
                                      .withValues(alpha: 0.2),
                                  AppColors.textSecondaryDark
                                      .withValues(alpha: 0.2),
                                ]),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppDimensions.spacingXxl + 4),
                  GestureDetector(
                    onTap: _goToNext,
                    child: Container(
                      width: double.infinity,
                      height: AppDimensions.buttonHeightLg,
                      decoration: BoxDecoration(
                        gradient: AppColors.aiGradient,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark
                                .withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentPage < _slides.length - 1
                              ? 'Next'
                              : 'Get Started',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String headline;
  final String subtitle;

  const _SlideData({
    required this.icon,
    required this.headline,
    required this.subtitle,
  });
}


class _SlideContent extends StatelessWidget {
  final _SlideData slide;
  const _SlideContent({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.primaryDark.withValues(alpha: 0.2),
                Colors.transparent,
              ]),
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.aiGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(slide.icon, color: Colors.white, size: 48),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingBig),
          Text(
            slide.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
              height: 1.08,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondaryDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// AuthScreen — Login / Register with mesh background
// ═════════════════════════════════════════════════════════════════════════════

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  String? _errorMsg;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 6) score++;
    if (p.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) score++;
    return score.clamp(0, 5);
  }

  String get _passwordLabel {
    final s = _passwordStrength;
    if (s <= 1) return 'Weak';
    if (s <= 2) return 'Fair';
    if (s <= 3) return 'Good';
    if (s <= 4) return 'Strong';
    return 'Very Strong';
  }

  Color get _passwordColor {
    final s = _passwordStrength;
    if (s <= 1) return AppColors.error;
    if (s <= 2) return AppColors.warning;
    if (s <= 3) return AppColors.accentQuiz;
    return AppColors.secondaryDark;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isLogin && !_agreeToTerms) {
      setState(() => _errorMsg = 'Please agree to the terms and privacy policy.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final auth = ref.read(authRepositoryProvider);

    try {
      if (_isLogin) {
        await auth.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await auth.signUpWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _nameCtrl.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondary) => const MainAppShell(),
          transitionsBuilder: (context, animation, secondary, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MeshGradientPainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingXxl,
                vertical: AppDimensions.spacingXxl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: AppDimensions.spacingXxl),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.centerButtonGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    const Text(
                      'MicroLearn',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Learn smarter, anywhere',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXxl + 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLogin ? _buildLoginForm() : _buildRegisterForm(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form builders ──────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      children: [
        _buildField(controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined,
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
        const SizedBox(height: AppDimensions.spacingLg),
        _buildField(controller: _passwordCtrl, label: 'Password', icon: Icons.lock_outline, obscure: true,
            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null),
        const SizedBox(height: AppDimensions.spacingSm),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Text('Forgot Password?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark.withValues(alpha: 0.8))),
          ),
        ),
        if (_errorMsg != null) _buildError(),
        const SizedBox(height: AppDimensions.spacingLg),
        _buildSubmitButton(),
        const SizedBox(height: AppDimensions.spacingLg),
        _buildDivider(),
        const SizedBox(height: AppDimensions.spacingLg),
        _buildSocialButtons(),
        const SizedBox(height: AppDimensions.spacingXxl),
        GestureDetector(
          onTap: () => setState(() { _isLogin = false; _errorMsg = null; }),
          child: RichText(
            text: TextSpan(
              text: "Don't have an account? ",
              style: TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
              children: [TextSpan(text: 'Register', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark))],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXxl),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      children: [
        _buildField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null),
        const SizedBox(height: AppDimensions.spacingLg),
        _buildField(controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined,
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
        const SizedBox(height: AppDimensions.spacingLg),
        _buildField(controller: _passwordCtrl, label: 'Password', icon: Icons.lock_outline, obscure: true,
            onChanged: (_) => setState(() {}),
            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null),
        if (_passwordCtrl.text.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              minHeight: 4, value: _passwordStrength / 5,
              backgroundColor: AppColors.textSecondaryDark.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(_passwordColor),
            ),
          ),
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerRight,
              child: Text(_passwordLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _passwordColor))),
        ],
        const SizedBox(height: AppDimensions.spacingMd),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _agreeToTerms ? AppColors.primaryDark : AppColors.surfaceDark,
                  border: Border.all(
                    color: _agreeToTerms ? AppColors.primaryDark
                        : AppColors.textSecondaryDark.withValues(alpha: 0.2),
                  ),
                ),
                child: _agreeToTerms
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Text('I agree to the Terms of Service and Privacy Policy',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.3)),
            ),
          ],
        ),
        if (_errorMsg != null) _buildError(),
        const SizedBox(height: AppDimensions.spacingLg),
        _buildSubmitButton(),
        const SizedBox(height: AppDimensions.spacingXxl),
        GestureDetector(
          onTap: () => setState(() { _isLogin = true; _errorMsg = null; }),
          child: RichText(
            text: TextSpan(
              text: 'Already have an account? ',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
              children: [TextSpan(text: 'Sign In', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark))],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXxl),
      ],
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,

      style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: AppColors.textSecondaryDark, size: 20),
        filled: true, fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.textSecondaryDark.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.error)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg, vertical: AppDimensions.spacingMd + 4),
      ),
      validator: validator,
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(child: Text(_errorMsg!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
        ]),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _loading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity, height: AppDimensions.buttonHeightMd + 4,
        decoration: BoxDecoration(
          gradient: _loading
              ? LinearGradient(colors: [
                  AppColors.textSecondaryDark.withValues(alpha: 0.3),
                  AppColors.textSecondaryDark.withValues(alpha: 0.3),
                ])
              : AppColors.centerButtonGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: _loading ? null : [
            BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.35),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(_isLogin ? 'Sign In' : 'Create Account',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(children: [
      Expanded(child: Container(height: 1, color: AppColors.textSecondaryDark.withValues(alpha: 0.12))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('or continue with',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500)),
      ),
      Expanded(child: Container(height: 1, color: AppColors.textSecondaryDark.withValues(alpha: 0.12))),
    ]);
  }

  Widget _buildSocialButtons() {
    return Row(children: [
      Expanded(child: _socialButton(icon: Icons.g_mobiledata_rounded, label: 'Google')),
      const SizedBox(width: AppDimensions.spacingMd),
      Expanded(child: _socialButton(icon: Icons.apple_rounded, label: 'Apple')),
    ]);
  }

  Widget _socialButton({required IconData icon, required String label}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textSecondaryDark.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textSecondaryDark, size: 22),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark)),
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
// Mesh Gradient Background Painter
// ═════════════════════════════════════════════════════════════════════════════

class _MeshGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = AppColors.primaryDark.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.05), size.width * 0.5, paint);
    paint.color = AppColors.secondaryDark.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.9), size.width * 0.45, paint);
    paint.color = AppColors.accentQuiz.withValues(alpha: 0.04);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.35, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}