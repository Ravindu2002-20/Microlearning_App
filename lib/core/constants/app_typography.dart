import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppTypography — Text style definitions for the entire app
// ─────────────────────────────────────────────────────────────────────────────

class AppTypography {
  AppTypography._();

  // ── Font Family (uncomment if using custom fonts) ─────────────────────────
  // static const String _font = 'Inter';

  // ── Bold Page Titles ──────────────────────────────────────────────────────

  static TextStyle displayLarge(Brightness brightness) => TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.05,
        color: _textPrimary(brightness),
        letterSpacing: -0.5,
      );

  static TextStyle displayMedium(Brightness brightness) => TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.05,
        color: _textPrimary(brightness),
        letterSpacing: -0.3,
      );

  static TextStyle displaySmall(Brightness brightness) => TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.08,
        color: _textPrimary(brightness),
        letterSpacing: -0.2,
      );

  // ── Medium Section Headers ────────────────────────────────────────────────

  static TextStyle headlineLarge(Brightness brightness) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: _textPrimary(brightness),
      );

  static TextStyle headlineMedium(Brightness brightness) => TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: _textPrimary(brightness),
      );

  static TextStyle headlineSmall(Brightness brightness) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: _textPrimary(brightness),
      );

  // ── Light Body Text ───────────────────────────────────────────────────────

  static TextStyle bodyLarge(Brightness brightness) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _textPrimary(brightness),
      );

  static TextStyle bodyMedium(Brightness brightness) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _textSecondary(brightness),
      );

  static TextStyle bodySmall(Brightness brightness) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: _textSecondary(brightness),
      );

  // ── Label / Button / Caption ──────────────────────────────────────────────

  static TextStyle labelLarge(Brightness brightness) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: _textPrimary(brightness),
      );

  static TextStyle labelMedium(Brightness brightness) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: _textSecondary(brightness),
      );

  static TextStyle labelSmall(Brightness brightness) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: _textSecondary(brightness),
      );

  // ── Chip / Tag Labels ─────────────────────────────────────────────────────

  static TextStyle chipLabel(Color color) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      );

  // ── XP / Score ────────────────────────────────────────────────────────────

  static TextStyle xpReward = const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
    fontSize: 14,
  );

  // ── Quiz Answer ───────────────────────────────────────────────────────────

  static TextStyle quizAnswer = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: _textPrimary(Brightness.dark),
  );

  // ── Private Helpers ───────────────────────────────────────────────────────

  static Color _textPrimary(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);

  static Color _textSecondary(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFA8B0C0) : const Color(0xFF6B7280);
}