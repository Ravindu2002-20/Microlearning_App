import 'package:flutter/material.dart';
import '../constants/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GlassChip — Semi‑transparent chip with border glow
// ─────────────────────────────────────────────────────────────────────────────

class GlassChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double? opacity;

  const GlassChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgOpacity = opacity ?? (isDark ? 0.14 : 0.10);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.chipPaddingH,
        vertical: AppDimensions.chipPaddingV,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: bgOpacity),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.iconXs, color: color),
          const SizedBox(width: AppDimensions.spacingXs),
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

// ─────────────────────────────────────────────────────────────────────────────
// GlassCard — Elevated card with subtle glassmorphism
// ─────────────────────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final Color? tintColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.tintColor,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = (tintColor ?? Colors.white).withValues(
      alpha: isDark ? 0.08 : 0.12,
    );

    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius ?? AppDimensions.cardRadiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius ?? AppDimensions.cardRadiusMd),
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GlassButton — Small circular glass button (e.g. "more" actions)
// ─────────────────────────────────────────────────────────────────────────────

class GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? iconColor;

  const GlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 42,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: size * 0.52,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GradientedButton — Full-width gradient button for CTAs
// ─────────────────────────────────────────────────────────────────────────────

class GradientedButton extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  final double height;
  final IconData? icon;
  final bool isLoading;

  const GradientedButton({
    super.key,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.height = AppDimensions.buttonHeightLg,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}