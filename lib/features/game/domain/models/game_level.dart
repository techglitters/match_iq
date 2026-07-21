import 'level_pair_placement.dart';
import 'level_solution.dart';

class GameLevel {
  const GameLevel({
    required this.id,
    required this.name,
    required this.rows,
    required this.columns,
    required this.pairs,
    this.levelNumber = 1,
    this.threeStarMoveTarget = 0,
    this.twoStarMoveTarget = 0,
    this.solutions = const [],
  });

  final String id;
  final String name;
  final int levelNumber;
  final int rows;
  final int columns;
  final List<LevelPairPlacement> pairs;
  final int threeStarMoveTarget;
  final int twoStarMoveTarget;
  final List<LevelSolution> solutions;

  int starsForMoves(int moves) {
    if (threeStarMoveTarget > 0 && moves <= threeStarMoveTarget) {
      return 3;
    }
    if (twoStarMoveTarget > 0 && moves <= twoStarMoveTarget) {
      return 2;
    }
    return 1;
  }
}
