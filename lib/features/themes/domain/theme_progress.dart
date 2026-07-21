import 'level_progress.dart';

class ThemeProgress {
  const ThemeProgress({
    required this.highestUnlockedLevel,
    required this.levels,
  });

  const ThemeProgress.initial() : highestUnlockedLevel = 1, levels = const {};

  final int highestUnlockedLevel;
  final Map<int, LevelProgress> levels;

  int get completedLevelCount {
    return levels.values.where((level) => level.completed).length;
  }

  int get totalStars {
    return levels.values.fold<int>(0, (total, level) => total + level.stars);
  }

  LevelProgress levelProgress(int levelNumber) {
    return levels[levelNumber] ?? const LevelProgress.empty();
  }

  bool isUnlocked(int levelNumber) {
    return levelNumber <= highestUnlockedLevel;
  }

  ThemeProgress completeLevel({
    required int levelNumber,
    required int earnedStars,
    required int moves,
    required int maxLevel,
  }) {
    final updatedLevels = Map<int, LevelProgress>.of(levels);
    updatedLevels[levelNumber] = levelProgress(
      levelNumber,
    ).complete(earnedStars: earnedStars, moves: moves);

    final nextUnlocked = levelNumber >= maxLevel ? maxLevel : levelNumber + 1;

    return ThemeProgress(
      highestUnlockedLevel: nextUnlocked > highestUnlockedLevel
          ? nextUnlocked
          : highestUnlockedLevel,
      levels: Map<int, LevelProgress>.unmodifiable(updatedLevels),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'highestUnlockedLevel': highestUnlockedLevel,
      'levels': {
        for (final entry in levels.entries)
          '${entry.key}': entry.value.toJson(),
      },
    };
  }

  static ThemeProgress fromJson(Map<String, Object?> json) {
    final rawLevels = json['levels'];
    final levels = <int, LevelProgress>{};

    if (rawLevels is Map) {
      for (final entry in rawLevels.entries) {
        final key = int.tryParse('${entry.key}');
        final value = entry.value;
        if (key != null && value is Map) {
          levels[key] = LevelProgress.fromJson(
            Map<String, Object?>.from(value),
          );
        }
      }
    }

    return ThemeProgress(
      highestUnlockedLevel: json['highestUnlockedLevel'] as int? ?? 1,
      levels: Map<int, LevelProgress>.unmodifiable(levels),
    );
  }
}
