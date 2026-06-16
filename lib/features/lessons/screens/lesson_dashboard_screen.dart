import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/constants.dart';
import '../../learning/models/lesson_item.dart';
import '../../learning/repositories/lesson_repository.dart';
import 'lesson_detail_screen.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final allLessonItemsProvider =
    FutureProvider.autoDispose<List<LessonItem>>((ref) async {
  final repo = LessonRepository(Supabase.instance.client);
  return repo.getAllLessonItems();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class LessonDashboardScreen extends ConsumerWidget {
  const LessonDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final asyncItems = ref.watch(allLessonItemsProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Lessons',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Could not load lessons right now.',
            style: TextStyle(color: textSecondary),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(allLessonItemsProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Text(
                        'No lessons yet.',
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allLessonItemsProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _LessonCard(
                  item: item,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _LessonCard extends StatelessWidget {
  final LessonItem item;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _LessonCard({
    required this.item,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  void _onTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    // Label + icon differ per source.
    final isYoutube = item is YoutubeVideo;
    final sourceLabel = isYoutube ? 'YouTube' : 'Video';
    final sourceIcon = isYoutube ? Icons.smart_display_rounded : Icons.videocam_rounded;
    final sourceColor = isYoutube ? const Color(0xFFFF0000) : AppColors.primaryDark;

    // Category / topic line
    final subLabel = switch (item) {
      StorageLesson(:final lesson) => lesson.category,
      YoutubeVideo(:final video)   => video.topic ?? video.channelTitle ?? 'Video',
    };

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──────────────────────────────────────────────────
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.cardRadiusMd),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail image or fallback
                    item.thumbnailUrl != null
                        ? Image.network(
                            item.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallback(),
                          )
                        : _fallback(),

                    // Play icon overlay
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 48,
                        color: Colors.white70,
                      ),
                    ),

                    // Source badge (top-right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(sourceIcon, size: 12, color: sourceColor),
                            const SizedBox(width: 4),
                            Text(
                              sourceLabel,
                              style: TextStyle(
                                color: sourceColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Info ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subLabel,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
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

  Widget _fallback() {
    return Container(
      color: AppColors.primaryDark.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          size: 56,
          color: Colors.white38,
        ),
      ),
    );
  }
}