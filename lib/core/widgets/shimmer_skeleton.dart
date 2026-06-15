import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ShimmerSkeleton — Shimmer loading effect (replaces spinners)
// ─────────────────────────────────────────────────────────────────────────────

class ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 14,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final base = widget.baseColor ??
        (brightness == Brightness.dark
            ? const Color(0xFF1A2342)
            : const Color(0xFFE5E7EB));
    final highlight = widget.highlightColor ??
        (brightness == Brightness.dark
            ? const Color(0xFF28345E)
            : const Color(0xFFF3F4F6));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width.isFinite
              ? widget.width
              : MediaQuery.of(context).size.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, -0.2),
              end: Alignment(1 + _controller.value * 2, 0.2),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

// ── Convenience: Full-page feed skeleton ────────────────────────────────────

class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerSkeleton(width: 180, height: 20),
              SizedBox(height: 16),
              ShimmerSkeleton(
                width: double.infinity,
                height: 300,
                radius: 28,
              ),
              SizedBox(height: 16),
              ShimmerSkeleton(width: 260, height: 18),
              SizedBox(height: 12),
              ShimmerSkeleton(width: 320, height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Convenience: Lesson card skeleton ───────────────────────────────────────

class LessonCardSkeleton extends StatelessWidget {
  const LessonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const ShimmerSkeleton(
          width: double.infinity,
          height: 180,
          radius: 20,
        ),
      ),
    );
  }
}

// ── Convenience: Profile skeleton ───────────────────────────────────────────

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 20),
          ShimmerSkeleton(width: 80, height: 80, radius: 40),
          SizedBox(height: 16),
          ShimmerSkeleton(width: 160, height: 20),
          SizedBox(height: 8),
          ShimmerSkeleton(width: 120, height: 14),
          SizedBox(height: 24),
          ShimmerSkeleton(width: double.infinity, height: 100, radius: 16),
          SizedBox(height: 16),
          ShimmerSkeleton(width: double.infinity, height: 60, radius: 12),
        ],
      ),
    );
  }
}