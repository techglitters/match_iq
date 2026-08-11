import '../../game/domain/models/game_level.dart';
import '../../themes/domain/game_theme.dart';
import '../domain/daily_puzzle_challenge.dart';

class DailyPuzzleCatalog {
  const DailyPuzzleCatalog._();

  static String dateKey([DateTime? date]) {
    final value = date ?? DateTime.now();
    final localDate = DateTime(value.year, value.month, value.day);
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '${localDate.year}-$month-$day';
  }

  static DateTime? parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  static int levelNumberForDate(DateTime date, int levelCount) {
    if (levelCount <= 1) {
      return 1;
    }

    final dayOffset = _dayOffset(date);
    return dayOffset % levelCount + 1;
  }

  static DailyPuzzleChallenge challengeForDate({
    required List<GameTheme> themes,
    DateTime? date,
  }) {
    final value = date ?? DateTime.now();
    final availableThemes = [
      for (final theme in themes)
        if (theme.isAvailable && theme.levels.isNotEmpty) theme,
    ];
    if (availableThemes.isEmpty) {
      throw ArgumentError.value(
        themes.length,
        'themes.length',
        'At least one available theme with levels is required.',
      );
    }

    final dayOffset = _dayOffset(value);
    final theme = availableThemes[dayOffset % availableThemes.length];
    final recipeIndex = dayOffset ~/ availableThemes.length;
    final difficulty = _difficultyForRecipe(recipeIndex);
    final modifier = _modifierForRecipe(recipeIndex);
    final levelNumber = _levelNumberForRecipe(
      theme: theme,
      difficulty: difficulty,
      modifier: modifier,
      recipeIndex: recipeIndex,
    );
    final baseLevel = theme.levels[levelNumber - 1];
    final key = dateKey(value);

    return DailyPuzzleChallenge(
      dateKey: key,
      theme: theme,
      level: _buildDailyLevel(
        baseLevel: baseLevel,
        dateKey: key,
        themeId: theme.id,
        modifier: modifier,
      ),
      difficulty: difficulty,
      modifier: modifier,
    );
  }

  static GameLevel levelForDate({required GameTheme theme, DateTime? date}) {
    return challengeForDate(themes: [theme], date: date).level;
  }

  static GameLevel _buildDailyLevel({
    required GameLevel baseLevel,
    required String dateKey,
    required String themeId,
    required DailyPuzzleModifier modifier,
  }) {
    final moveAdjustment = modifier == DailyPuzzleModifier.fewerMovesForStars
        ? 1
        : 0;
    final threeStarMoveTarget = _adjustMoveTarget(
      baseLevel.threeStarMoveTarget,
      moveAdjustment,
    );
    final twoStarMoveTarget = _adjustMoveTarget(
      baseLevel.twoStarMoveTarget,
      moveAdjustment,
    ).clamp(threeStarMoveTarget, 999).toInt();

    return GameLevel(
      id: 'daily_${themeId}_$dateKey',
      name: 'Daily Puzzle',
      levelNumber: baseLevel.levelNumber,
      rows: baseLevel.rows,
      columns: baseLevel.columns,
      pairs: baseLevel.pairs,
      threeStarMoveTarget: threeStarMoveTarget,
      twoStarMoveTarget: twoStarMoveTarget,
      solutions: baseLevel.solutions,
    );
  }

  static int _adjustMoveTarget(int target, int adjustment) {
    if (target <= 0) {
      return 0;
    }
    return (target - adjustment).clamp(1, 999).toInt();
  }

  static int _dayOffset(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    final epoch = DateTime(2026);
    return localDate.difference(epoch).inDays.abs();
  }

  static DailyPuzzleDifficulty _difficultyForRecipe(int recipeIndex) {
    const cycle = [
      DailyPuzzleDifficulty.easy,
      DailyPuzzleDifficulty.easy,
      DailyPuzzleDifficulty.medium,
      DailyPuzzleDifficulty.medium,
      DailyPuzzleDifficulty.hard,
      DailyPuzzleDifficulty.hard,
      DailyPuzzleDifficulty.challenge,
    ];
    return cycle[recipeIndex % cycle.length];
  }

  static DailyPuzzleModifier _modifierForRecipe(int recipeIndex) {
    const cycle = [
      DailyPuzzleModifier.steady,
      DailyPuzzleModifier.fewerMovesForStars,
      DailyPuzzleModifier.longRoute,
      DailyPuzzleModifier.noUndo,
      DailyPuzzleModifier.fewerMovesForStars,
      DailyPuzzleModifier.steady,
    ];
    return cycle[recipeIndex % cycle.length];
  }

  static int _levelNumberForRecipe({
    required GameTheme theme,
    required DailyPuzzleDifficulty difficulty,
    required DailyPuzzleModifier modifier,
    required int recipeIndex,
  }) {
    final band = _LevelBand.forDifficulty(difficulty, theme.levels.length);
    var levelNumber = band.start + recipeIndex % band.length;
    if (modifier == DailyPuzzleModifier.longRoute) {
      levelNumber = (levelNumber + 1).clamp(band.start, band.end).toInt();
    }
    return levelNumber;
  }
}

class _LevelBand {
  const _LevelBand({required this.start, required this.end});

  final int start;
  final int end;

  int get length => end - start + 1;

  static _LevelBand forDifficulty(
    DailyPuzzleDifficulty difficulty,
    int levelCount,
  ) {
    final firstMedium = (levelCount * 0.34).ceil().clamp(2, levelCount).toInt();
    final firstHard = (levelCount * 0.62).ceil().clamp(3, levelCount).toInt();
    final firstChallenge = (levelCount * 0.84)
        .ceil()
        .clamp(4, levelCount)
        .toInt();

    return switch (difficulty) {
      DailyPuzzleDifficulty.easy => _LevelBand(start: 1, end: firstMedium - 1),
      DailyPuzzleDifficulty.medium => _LevelBand(
        start: firstMedium,
        end: firstHard - 1,
      ),
      DailyPuzzleDifficulty.hard => _LevelBand(
        start: firstHard,
        end: firstChallenge - 1,
      ),
      DailyPuzzleDifficulty.challenge => _LevelBand(
        start: firstChallenge,
        end: levelCount,
      ),
    };
  }
}
