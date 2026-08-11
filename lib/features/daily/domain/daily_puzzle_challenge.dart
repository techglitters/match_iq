import '../../game/domain/models/game_level.dart';
import '../../themes/domain/game_theme.dart';

enum DailyPuzzleDifficulty { easy, medium, hard, challenge }

extension DailyPuzzleDifficultyLabel on DailyPuzzleDifficulty {
  String get label {
    return switch (this) {
      DailyPuzzleDifficulty.easy => 'Easy',
      DailyPuzzleDifficulty.medium => 'Medium',
      DailyPuzzleDifficulty.hard => 'Hard',
      DailyPuzzleDifficulty.challenge => 'Challenge',
    };
  }
}

enum DailyPuzzleModifier { steady, fewerMovesForStars, longRoute, noUndo }

extension DailyPuzzleModifierLabel on DailyPuzzleModifier {
  String get label {
    return switch (this) {
      DailyPuzzleModifier.steady => 'Classic',
      DailyPuzzleModifier.fewerMovesForStars => 'Precision Stars',
      DailyPuzzleModifier.longRoute => 'Long Route',
      DailyPuzzleModifier.noUndo => 'No Undo',
    };
  }

  String get description {
    return switch (this) {
      DailyPuzzleModifier.steady => 'A balanced daily board.',
      DailyPuzzleModifier.fewerMovesForStars =>
        'Earn top stars with cleaner moves.',
      DailyPuzzleModifier.longRoute => 'Pairs are pulled from a harder board.',
      DailyPuzzleModifier.noUndo => 'Solve cleanly without undo help.',
    };
  }
}

class DailyPuzzleChallenge {
  const DailyPuzzleChallenge({
    required this.dateKey,
    required this.theme,
    required this.level,
    required this.difficulty,
    required this.modifier,
  });

  final String dateKey;
  final GameTheme theme;
  final GameLevel level;
  final DailyPuzzleDifficulty difficulty;
  final DailyPuzzleModifier modifier;

  int get levelNumber => level.levelNumber;

  String get title => "Today's Daily Puzzle";

  String get subtitle {
    return '${theme.name} - ${difficulty.label} - ${modifier.label}';
  }
}
