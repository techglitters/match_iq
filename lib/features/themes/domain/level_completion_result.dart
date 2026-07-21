class LevelCompletionResult {
  const LevelCompletionResult({
    required this.levelNumber,
    required this.earnedStars,
    required this.savedStars,
    required this.moves,
    required this.bestMoves,
    required this.unlockedLevel,
    required this.isThemeComplete,
  });

  final int levelNumber;
  final int earnedStars;
  final int savedStars;
  final int moves;
  final int bestMoves;
  final int unlockedLevel;
  final bool isThemeComplete;
}
