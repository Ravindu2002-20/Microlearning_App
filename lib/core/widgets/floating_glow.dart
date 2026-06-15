import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FloatingGlow — Soft radial gradient circle used as ambient background glow
// ─────────────────────────────────────────────────────────────────────────────

class FloatingGlow extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const FloatingGlow({
    super.key,
    required this.color,
    this.size = 180,
    this.opacity = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AvatarGlow — Circular glow ring around an avatar
// ─────────────────────────────────────────────────────────────────────────────

class AvatarGlow extends StatefulWidget {
  final double radius;
  final Color glowColor;
  final Widget child;

  const AvatarGlow({
    super.key,
    this.radius = 40,
    required this.glowColor,
    required this.child,
  });

  @override
  State<AvatarGlow> createState() => _AvatarGlowState();
}

class _AvatarGlowState extends State<AvatarGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
        return Container(
          padding: EdgeInsets.all(4 + _controller.value * 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(
                    alpha: 0.2 + _controller.value * 0.3),
                blurRadius: 12 + _controller.value * 8,
                spreadRadius: 1 + _controller.value * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}