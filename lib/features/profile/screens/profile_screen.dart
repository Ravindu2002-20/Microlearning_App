import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../feed/controllers/feed_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userUuid = Supabase.instance.client.auth.currentUser?.id;

    if (userUuid == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view your profile.')),
      );
    }

    final repo = ref.read(learningRepositoryProvider);

    return FutureBuilder<Map<String, dynamic>?>(
      future: repo.fetchUserProfile(userUuid: userUuid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data;
        final username = profile?['username'] as String? ?? 'User';
        final currentLevel = (profile?['current_level'] as int?) ?? 1;
        final xp = (profile?['xp'] as int?) ?? 0;
        final progress = ((xp % 1000) / 1000.0).clamp(0.0, 1.0);

        return FutureBuilder<int>(
          future: _fetchCompletedLessonCount(userUuid),
          builder: (context, countSnap) {
            final completedCount = countSnap.data ?? 0;

            return Scaffold(
              appBar: AppBar(title: const Text('Profile')),
              body: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      children: [
                        Chip(
                          label: Text('Level $currentLevel'),
                          backgroundColor:
                              Colors.deepPurple.withValues(alpha: 0.25),
                        ),
                        Chip(
                          label: Text('$completedCount lessons completed'),
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'XP: $xp',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.deepPurpleAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Next level in ${1000 - (xp % 1000)} XP',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        onPressed: () async {
                          await Supabase.instance.client.auth.signOut();

                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginRegistrationScreen(),
                            ),
                            (_) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<int> _fetchCompletedLessonCount(String userUuid) async {
    try {
      final res = await Supabase.instance.client
          .from('user_progress')
          .select('lesson_id')
          .eq('user_id', userUuid);

      return res.length;
    } catch (_) {
      return 0;
    }
  }
}

// Uses the placeholder in lib/main.dart; main.dart is not modified.
class LoginRegistrationScreen extends StatelessWidget {
  const LoginRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Login/Registration Screen')));
  }
}

