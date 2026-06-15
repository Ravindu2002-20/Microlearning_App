import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppColors — Complete Design System Color Palette
// Light Mode / Dark Mode / Context‑Aware Accents / Gradients
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Core Palette ──────────────────────────────────────────────────────────

  static const Color primaryLight = Color(0xFF5B5FFF);
  static const Color secondaryLight = Color(0xFF00D4FF);
  static const Color primaryDark = Color(0xFF7B61FF);
  static const Color secondaryDark = Color(0xFF00E5FF);

  static const Color success = Color(0xFF00C781);
  static const Color warning = Color(0xFFFFB547);
  static const Color error = Color(0xFFFF5C6C);

  // ── Light Mode ────────────────────────────────────────────────────────────

  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7F8FC);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // ── Dark Mode ─────────────────────────────────────────────────────────────

  static const Color backgroundDark = Color(0xFF0B1020);
  static const Color surfaceDark = Color(0xFF131B33);
  static const Color elevatedSurfaceDark = Color(0xFF1A2342);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFA8B0C0);

  // ── Context‑Aware Accents ─────────────────────────────────────────────────

  static const Color accentMotion = Color(0xFF00D4FF); // Cyan – walking/motion
  static const Color accentStationary = Color(0xFF7B61FF); // Purple – stationary
  static const Color accentStrongNetwork = Color(0xFF5B5FFF); // Indigo
  static const Color accentWeakNetwork = Color(0xFFFFB547); // Amber
  static const Color accentQuiz = Color(0xFF00C781); // Emerald
  static const Color accentAiPrimary = Color(0xFF7B61FF); // Purple
  static const Color accentAiSecondary = Color(0xFF00E5FF); // Cyan
  static const Color accentStreak = Color(0xFFFF7A45); // Orange
  static const Color accentStreakEnd = Color(0xFFFFB547); // Amber

  // ── Glass / Overlay ───────────────────────────────────────────────────────

  static Color whiteWithOpacity(double opacity) =>
      Colors.white.withValues(alpha: opacity);
  static Color blackWithOpacity(double opacity) =>
      Colors.black.withValues(alpha: opacity);

  // ── Gradients ─────────────────────────────────────────────────────────────

  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5B5FFF), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient primaryGradientDark = LinearGradient(
    colors: [Color(0xFF7B61FF), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient aiGradient = LinearGradient(
    colors: [Color(0xFF7B61FF), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient streakGradient = LinearGradient(
    colors: [Color(0xFFFF7A45), Color(0xFFFFB547)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient quizGradient = LinearGradient(
    colors: [Color(0xFF00C781), Color(0xFF62E5A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient indigoGradient = LinearGradient(
    colors: [Color(0xFF5B5FFF), Color(0xFF7B61FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient centerButtonGradient = LinearGradient(
    colors: [Color(0xFF7B61FF), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Helper – Get palette for a Brightness ─────────────────────────────────

  static Color primaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? primaryDark : primaryLight;

  static Color secondaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? secondaryDark : secondaryLight;

  static Color backgroundFor(Brightness brightness) =>
      brightness == Brightness.dark ? backgroundDark : backgroundLight;

  static Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color textPrimaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;
}