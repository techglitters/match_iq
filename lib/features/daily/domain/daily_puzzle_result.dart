class DailyPuzzleResult {
  const DailyPuzzleResult({
    required this.dateKey,
    required this.themeId,
    required this.levelNumber,
    required this.completed,
    required this.stars,
    required this.moves,
    required this.bestMoves,
  });

  const DailyPuzzleResult.empty({
    required this.dateKey,
    required this.themeId,
    required this.levelNumber,
  }) : completed = false,
       stars = 0,
       moves = null,
       bestMoves = null;

  final String dateKey;
  final String themeId;
  final int levelNumber;
  final bool completed;
  final int stars;
  final int? moves;
  final int? bestMoves;

  DailyPuzzleResult complete({required int earnedStars, required int moves}) {
    return DailyPuzzleResult(
      dateKey: dateKey,
      themeId: themeId,
      levelNumber: levelNumber,
      completed: true,
      stars: earnedStars > stars ? earnedStars : stars,
      moves: moves,
      bestMoves: bestMoves == null || moves < bestMoves! ? moves : bestMoves,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'dateKey': dateKey,
      'themeId': themeId,
      'levelNumber': levelNumber,
      'completed': completed,
      'stars': stars,
      'moves': moves,
      'bestMoves': bestMoves,
    };
  }

  static DailyPuzzleResult fromJson(Map<String, Object?> json) {
    return DailyPuzzleResult(
      dateKey: json['dateKey'] as String? ?? '',
      themeId: json['themeId'] as String? ?? 'nature',
      levelNumber: json['levelNumber'] as int? ?? 1,
      completed: json['completed'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      moves: json['moves'] as int?,
      bestMoves: json['bestMoves'] as int?,
    );
  }
}
