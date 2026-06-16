import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppDimensions — Consistent sizing, spacing, and radius tokens
// ─────────────────────────────────────────────────────────────────────────────

class AppDimensions {
  AppDimensions._();

  // ── Border Radius ─────────────────────────────────────────────────────────

  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ── Card Radii ────────────────────────────────────────────────────────────

  static const double cardRadiusSm = 16;
  static const double cardRadiusMd = 20;
  static const double cardRadiusLg = 24;

  // ── Spacing ───────────────────────────────────────────────────────────────

  static const double spacingXxs = 4;
  static const double spacingXs = 6;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacingXxl = 24;
  static const double spacingXxxl = 32;
  static const double spacingBig = 48;

  // ── Icon Sizes ────────────────────────────────────────────────────────────

  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 28;
  static const double iconXl = 32;
  static const double iconXxl = 48;

  // ── Button Sizes ──────────────────────────────────────────────────────────

  static const double buttonHeightSm = 40;
  static const double buttonHeightMd = 48;
  static const double buttonHeightLg = 56;
  static const double buttonMinWidth = 120;

  // ── Avatar Sizes ──────────────────────────────────────────────────────────

  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double avatarLg = 56;
  static const double avatarXl = 80;

  // ── Bottom Navigation ─────────────────────────────────────────────────────

  static const double navHeight = 72;
  static const double navIconSize = 24;
  static const double centerButtonSize = 60;
  static const double centerButtonIconSize = 32;

  // ── Progress ──────────────────────────────────────────────────────────────

  static const double progressHeightSm = 4;
  static const double progressHeightMd = 6;
  static const double progressHeightLg = 10;

  // ── Chip / Tag ────────────────────────────────────────────────────────────

  static const double chipHeight = 34;
  static const double chipPaddingH = 12;
  static const double chipPaddingV = 8;

  // ── Shadows ───────────────────────────────────────────────────────────────

  static List<BoxShadow> shadowSm(Color? color) => [
        BoxShadow(
          color: (color ?? Colors.black).withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowMd(Color? color) => [
        BoxShadow(
          color: (color ?? Colors.black).withValues(alpha: 0.10),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> shadowLg(Color? color) => [
        BoxShadow(
          color: (color ?? Colors.black).withValues(alpha: 0.14),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> shadowXl(Color? color) => [
        BoxShadow(
          color: (color ?? Colors.black).withValues(alpha: 0.18),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> shadowGlow(Color color, {double blur = 20}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: blur,
          offset: const Offset(0, 10),
        ),
      ];

  // ── Padding Helpers ───────────────────────────────────────────────────────

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: spacingLg,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(spacingLg);

  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(spacingMd);
}