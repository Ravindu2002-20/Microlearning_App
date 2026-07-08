import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../learning/models/lesson_model.dart';
import '../../learning/repositories/learning_repository.dart';

class QuizLessonPickerSheet extends ConsumerWidget {
  final void Function(LessonModel) onPicked;

  const QuizLessonPickerSheet({super.key, required this.onPicked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = LearningRepository(Supabase.instance.client);

    return FutureBuilder<List<LessonModel>>(
      future: repo.getApprovedLessons(),
      builder: (context, snapshot) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final text = isDark ? Colors.white : Colors.black;

        if (snapshot.connectionState != ConnectionState.done) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(height: 10),
                  Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          );
        }

        final lessons = snapshot.data ?? [];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose a lesson',
                  style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lessons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        onPicked(lesson);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              style: TextStyle(color: text, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lesson.category,
                              style: TextStyle(color: text.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

