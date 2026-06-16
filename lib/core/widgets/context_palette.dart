import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../core/services/context_engine_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ContextPalette — Generates color palettes based on user context state
// ─────────────────────────────────────────────────────────────────────────────

class ContextPalette {
  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color background;
  final Color surface;
  final Color elevatedSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color motionAccent;
  final Gradient activeGradient;

  const ContextPalette({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.background,
    required this.surface,
    required this.elevatedSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.motionAccent,
    required this.activeGradient,
  });

  factory ContextPalette.fromState(UserContextState state) {
    final isMotion = state.isInMotion;
    final network = state.networkStrength;

    // Determine primary based on motion
    final primary = isMotion
        ? AppColors.accentMotion
        : AppColors.accentStationary;

    // Determine gradient based on network
    final gradient = switch (network) {
      AppNetworkStrength.weak => AppColors.streakGradient,
      AppNetworkStrength.medium => AppColors.indigoGradient,
      AppNetworkStrength.strong => AppColors.primaryGradientDark,
    };

    return ContextPalette(
      primary: primary,
      secondary: AppColors.secondaryDark,
      success: AppColors.success,
      warning: AppColors.warning,
      error: AppColors.error,
      background: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
      elevatedSurface: AppColors.elevatedSurfaceDark,
      textPrimary: AppColors.textPrimaryDark,
      textSecondary: AppColors.textSecondaryDark,
      motionAccent: primary,
      activeGradient: gradient,
    );
  }

  // Convenience gradient getters
  LinearGradient get quizGradient => const LinearGradient(
        colors: [Color(0xFF00C781), Color(0xFF62E5A6)],
      );

  LinearGradient get aiGradient => const LinearGradient(
        colors: [Color(0xFF7B61FF), Color(0xFF00E5FF)],
      );

  static ContextPalette dark() {
    return const ContextPalette(
      primary: Color(0xFF7B61FF),
      secondary: Color(0xFF00E5FF),
      success: Color(0xFF00C781),
      warning: Color(0xFFFFB547),
      error: Color(0xFFFF5C6C),
      background: Color(0xFF0B1020),
      surface: Color(0xFF131B33),
      elevatedSurface: Color(0xFF1A2342),
      textPrimary: Color(0xFFF9FAFB),
      textSecondary: Color(0xFFA8B0C0),
      motionAccent: Color(0xFF7B61FF),
      activeGradient: LinearGradient(
        colors: [Color(0xFF7B61FF), Color(0xFF00E5FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}