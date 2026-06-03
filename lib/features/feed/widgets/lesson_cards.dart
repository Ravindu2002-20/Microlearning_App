import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../learning/models/lesson_model.dart';

class TextLessonCard extends StatelessWidget {
  final LessonModel lesson;

  const TextLessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[900],
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  lesson.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Difficulty ${lesson.difficultyLevel}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            lesson.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                lesson.content,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  height: 1.7,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // completion handled by parent FAB/gesture
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Mark Complete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizLessonCard extends StatefulWidget {
  final LessonModel lesson;

  const QuizLessonCard({super.key, required this.lesson});

  @override
  State<QuizLessonCard> createState() => _QuizLessonCardState();
}

class _QuizLessonCardState extends State<QuizLessonCard> {
  Map<String, dynamic>? _quiz;
  String? _errorText;

  int? _selectedIndex;
  bool _revealedAnswer = false;

  @override
  void initState() {
    super.initState();
    _parseQuiz();
  }

  void _parseQuiz() {
    try {
      final decoded = jsonDecode(widget.lesson.content);
      if (decoded is Map<String, dynamic>) {
        _quiz = decoded;
        return;
      }
      setState(() {
        _errorText = 'Malformed quiz content';
      });
    } catch (e) {
      setState(() {
        _errorText = 'Failed to parse quiz JSON.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorText != null || _quiz == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.deepPurple.shade900,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.lesson.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 12),
            Text(
              _errorText ?? 'Invalid quiz',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.lesson.content,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final question = (_quiz?['question'] as String?) ?? '';
    final optionsDynamic = _quiz?['options'];
    final options = optionsDynamic is List
        ? optionsDynamic.map((e) => e.toString()).toList()
        : <String>[];
    final answer = (_quiz?['answer'] as String?) ?? '';

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.deepPurple.shade900,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.lesson.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.lesson.category,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(options.length, (index) {
            final opt = options[index];
            final isSelected = _selectedIndex == index;


            Color? bg;
            if (_revealedAnswer && isSelected) {
              bg = opt == answer ? Colors.green : Colors.red;
            } else if (isSelected) {
              bg = Colors.white24;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bg ?? Colors.white10,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 80),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: _revealedAnswer
                      ? null
                      : () {
                          final correct = opt == answer;
                          setState(() {
                            _selectedIndex = index;
                            _revealedAnswer = true;
                          });

                          if (correct) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('✓ Correct!'),
                            ));
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('✗ Incorrect'),
                            ));
                          }
                        },
                  child: Text(
                    opt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            );
          }),

          if (_revealedAnswer) ...[
            const SizedBox(height: 12),
            Text(
              'Correct answer: $answer',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 18),
          ] else
            const SizedBox(height: 10),

          if (_revealedAnswer)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // completion handled by parent FAB/gesture
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Next Lesson →',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class VideoLessonCard extends StatelessWidget {
  final LessonModel lesson;

  const VideoLessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final isWeak = lesson.minNetworkStrength == 'weak';

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  lesson.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Video',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lesson.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (isWeak)
            const Text(
              'Video requires strong connection',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Mark Complete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AudioLessonCard extends StatefulWidget {
  final LessonModel lesson;

  const AudioLessonCard({super.key, required this.lesson});

  @override
  State<AudioLessonCard> createState() => _AudioLessonCardState();
}

class _AudioLessonCardState extends State<AudioLessonCard> {
  Timer? _timer;
  double _progress = 0.25;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      setState(() {
        _progress = (_progress + 0.07).clamp(0.0, 1.0);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.indigo.shade900,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.lesson.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.headphones, size: 36, color: Colors.white),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.lesson.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Listening Progress',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Mark Complete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

