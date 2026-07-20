import 'level_pair_placement.dart';

class GameLevel {
  const GameLevel({
    required this.id,
    required this.name,
    required this.rows,
    required this.columns,
    required this.pairs,
  });

  final String id;
  final String name;
  final int rows;
  final int columns;
  final List<LevelPairPlacement> pairs;
}
