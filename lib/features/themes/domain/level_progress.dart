class LevelProgress {
  const LevelProgress({
    required this.completed,
    required this.stars,
    this.bestMoves,
  });

  const LevelProgress.empty() : completed = false, stars = 0, bestMoves = null;

  final bool completed;
  final int stars;
  final int? bestMoves;

  LevelProgress complete({required int earnedStars, required int moves}) {
    return LevelProgress(
      completed: true,
      stars: earnedStars > stars ? earnedStars : stars,
      bestMoves: bestMoves == null || moves < bestMoves! ? moves : bestMoves,
    );
  }

  Map<String, Object?> toJson() {
    return {'completed': completed, 'stars': stars, 'bestMoves': bestMoves};
  }

  static LevelProgress fromJson(Map<String, Object?> json) {
    return LevelProgress(
      completed: json['completed'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      bestMoves: json['bestMoves'] as int?,
    );
  }
}
