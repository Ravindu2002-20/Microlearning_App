class XpCalculation {
  static const int videoWatchXp = 5;
  static const int correctAnswerXp = 15;
  static const int streakBonusXp = 75;
  static const int xpPerLevel = 300;

  static int calculateTotalXp({
    required int watchedVideoCount,
    required int correctAnswerCount,
    required int streak,
  }) {
    final baseXp = (watchedVideoCount * videoWatchXp) +
        (correctAnswerCount * correctAnswerXp);
    final streakBonus = streak >= 7 ? streakBonusXp : 0;
    return baseXp + streakBonus;
  }

  static int calculateLevel(int totalXp) {
    if (totalXp <= 0) return 1;
    return (totalXp / xpPerLevel).floor() + 1;
  }

  static int xpToNextLevel(int totalXp) {
    final currentLevel = calculateLevel(totalXp);
    final nextLevelStart = (currentLevel * xpPerLevel);
    return nextLevelStart - totalXp;
  }

  static String formatXp(int xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(xp % 1000 == 0 ? 0 : 1)}k';
    }
    return xp.toString();
  }
}
