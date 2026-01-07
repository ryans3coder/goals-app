class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.nextLevel,
    required this.totalXp,
    required this.currentLevelXp,
    required this.nextLevelXp,
  });

  final int level;
  final int nextLevel;
  final int totalXp;
  final int currentLevelXp;
  final int nextLevelXp;

  int get xpIntoLevel => totalXp - currentLevelXp;

  int get xpToNextLevel => nextLevelXp - currentLevelXp;

  double get progress {
    final range = xpToNextLevel;
    if (range <= 0) {
      return 1;
    }
    return (xpIntoLevel / range).clamp(0, 1);
  }
}

class LevelPolicy {
  const LevelPolicy();

  static const List<int> _thresholds = [
    0,
    100,
    250,
    500,
    900,
    1400,
    2000,
  ];

  int levelForXp(int totalXp) {
    return _levelIndexForXp(totalXp) + 1;
  }

  LevelProgress progressForXp(int totalXp) {
    final levelIndex = _levelIndexForXp(totalXp);
    final currentLevelXp = _thresholds[levelIndex];
    final nextLevelIndex =
        levelIndex + 1 < _thresholds.length ? levelIndex + 1 : levelIndex;
    final nextLevelXp = _thresholds[nextLevelIndex];
    return LevelProgress(
      level: levelIndex + 1,
      nextLevel: nextLevelIndex + 1,
      totalXp: totalXp,
      currentLevelXp: currentLevelXp,
      nextLevelXp: nextLevelXp,
    );
  }

  int _levelIndexForXp(int totalXp) {
    for (var index = _thresholds.length - 1; index >= 0; index--) {
      if (totalXp >= _thresholds[index]) {
        return index;
      }
    }
    return 0;
  }
}
