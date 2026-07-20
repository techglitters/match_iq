import 'board_position.dart';

class GamePath {
  const GamePath({
    required this.relationshipId,
    required this.cells,
    required this.isComplete,
  });

  final String relationshipId;
  final List<BoardPosition> cells;
  final bool isComplete;
}
