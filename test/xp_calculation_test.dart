import 'package:flutter_test/flutter_test.dart';

import 'package:microlearning_app/features/learning/repositories/xp_calculation.dart';

void main() {
  group('XP calculation', () {
    test('adds video watches, quiz answers, and streak bonus', () {
      final xp = XpCalculation.calculateTotalXp(
        watchedVideoCount: 3,
        correctAnswerCount: 5,
        streak: 7,
      );

      expect(xp, 3 * XpCalculation.videoWatchXp + 5 * XpCalculation.correctAnswerXp + XpCalculation.streakBonusXp);
    });

    test('keeps the level and next-level values consistent', () {
      final level = XpCalculation.calculateLevel(620);
      final nextLevelXp = XpCalculation.xpToNextLevel(620);

      expect(level, 3);
      expect(nextLevelXp, 280);
    });
  });
}
