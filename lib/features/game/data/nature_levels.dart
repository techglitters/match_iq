import 'dart:math' as math;

import '../domain/models/board_position.dart';
import '../domain/models/game_level.dart';
import '../domain/models/game_path.dart';
import '../domain/models/level_pair_placement.dart';
import '../domain/models/level_solution.dart';
import 'nature_relationships.dart';

class GeneratedNatureLevel {
  const GeneratedNatureLevel({
    required this.level,
    required this.solutionPaths,
  });

  final GameLevel level;
  final Map<String, GamePath> solutionPaths;
}

List<GameLevel> createNatureLevels({math.Random? random}) {
  return NatureLevels.all;
}

int get natureLevelCount => NatureLevels.all.length;

GameLevel createNatureLevel({required int levelNumber, math.Random? random}) {
  final index = levelNumber.clamp(1, NatureLevels.all.length).toInt() - 1;
  return NatureLevels.all[index];
}

List<GeneratedNatureLevel> createGeneratedNatureLevels({math.Random? random}) {
  return [
    for (final level in NatureLevels.all) _generatedLevelFromGameLevel(level),
  ];
}

GeneratedNatureLevel generateNatureLevel({
  required int levelNumber,
  required int pairCount,
  math.Random? random,
}) {
  return _generatedLevelFromGameLevel(
    createNatureLevel(levelNumber: levelNumber),
  );
}

class NatureLevels {
  const NatureLevels._();

  static final List<GameLevel> all = List<GameLevel>.unmodifiable([
    for (final spec in _levelSpecs) _buildLevel(spec),
  ]);

  static List<String> validateAll() {
    return [for (final level in all) ...validateLevelSolutions(level)];
  }
}

List<String> validateLevelSolutions(GameLevel level) {
  final errors = <String>[];
  final endpoints = <BoardPosition, String>{};
  final occupiedSolutionCells = <BoardPosition, String>{};
  final placementsByRelationship = {
    for (final placement in level.pairs) placement.relationship.id: placement,
  };

  for (final placement in level.pairs) {
    for (final endpoint in [
      placement.sourcePosition,
      placement.targetPosition,
    ]) {
      if (!_isInside(endpoint, level)) {
        errors.add('${level.id}: endpoint $endpoint is outside the board');
      }
      final previous = endpoints[endpoint];
      if (previous != null) {
        errors.add(
          '${level.id}: endpoint $endpoint is shared by $previous and '
          '${placement.relationship.id}',
        );
      }
      endpoints[endpoint] = placement.relationship.id;
    }
  }

  if (level.solutions.length != level.pairs.length) {
    errors.add('${level.id}: every pair must have one known solution');
  }

  for (final solution in level.solutions) {
    final placement = placementsByRelationship[solution.relationshipId];
    if (placement == null) {
      errors.add('${level.id}: unknown solution ${solution.relationshipId}');
      continue;
    }

    final cells = solution.cells;
    if (cells.length < 2) {
      errors.add(
        '${level.id}: ${solution.relationshipId} solution is too short',
      );
      continue;
    }

    final startsAtSource = cells.first == placement.sourcePosition;
    final startsAtTarget = cells.first == placement.targetPosition;
    final endsAtSource = cells.last == placement.sourcePosition;
    final endsAtTarget = cells.last == placement.targetPosition;
    if (!((startsAtSource && endsAtTarget) ||
        (startsAtTarget && endsAtSource))) {
      errors.add(
        '${level.id}: ${solution.relationshipId} must connect opposite endpoints',
      );
    }

    final seen = <BoardPosition>{};
    for (var index = 0; index < cells.length; index += 1) {
      final cell = cells[index];
      if (!_isInside(cell, level)) {
        errors.add(
          '${level.id}: ${solution.relationshipId} cell $cell outside',
        );
      }
      if (!seen.add(cell)) {
        errors.add('${level.id}: ${solution.relationshipId} repeats $cell');
      }
      if (index > 0 && !_areAdjacent(cells[index - 1], cell)) {
        errors.add(
          '${level.id}: ${solution.relationshipId} has non-adjacent step',
        );
      }

      final previousRelationship = occupiedSolutionCells[cell];
      if (previousRelationship != null &&
          previousRelationship != solution.relationshipId) {
        errors.add(
          '${level.id}: $cell overlaps $previousRelationship and '
          '${solution.relationshipId}',
        );
      }
      occupiedSolutionCells[cell] = solution.relationshipId;
    }
  }

  return errors;
}

GeneratedNatureLevel _generatedLevelFromGameLevel(GameLevel level) {
  return GeneratedNatureLevel(
    level: level,
    solutionPaths: {
      for (final solution in level.solutions)
        solution.relationshipId: GamePath(
          relationshipId: solution.relationshipId,
          cells: solution.cells,
          isComplete: true,
        ),
    },
  );
}

GameLevel _buildLevel(_NatureLevelSpec spec) {
  final paths = _buildSolutionPaths(spec);
  final relationships = [
    for (var index = 0; index < spec.pairCount; index += 1)
      NatureRelationships.all[(spec.levelNumber + index - 1) %
          NatureRelationships.all.length],
  ];
  final placements = <LevelPairPlacement>[];
  final solutions = <LevelSolution>[];

  for (var index = 0; index < spec.pairCount; index += 1) {
    final relationship = relationships[index];
    final path = paths[index];
    placements.add(
      LevelPairPlacement(
        relationship: relationship,
        sourcePosition: path.first,
        targetPosition: path.last,
      ),
    );
    solutions.add(
      LevelSolution(
        relationshipId: relationship.id,
        cells: List<BoardPosition>.unmodifiable(path),
      ),
    );
  }

  return GameLevel(
    id: 'nature_${spec.levelNumber}',
    name: 'Nature ${spec.levelNumber}',
    levelNumber: spec.levelNumber,
    rows: spec.rows,
    columns: spec.columns,
    pairs: List<LevelPairPlacement>.unmodifiable(placements),
    threeStarMoveTarget: spec.pairCount,
    twoStarMoveTarget: spec.pairCount + 2,
    solutions: List<LevelSolution>.unmodifiable(solutions),
  );
}

List<List<BoardPosition>> _buildSolutionPaths(_NatureLevelSpec spec) {
  final traversal = _snakeTraversal(spec.rows, spec.columns);
  final paths = <List<BoardPosition>>[];
  var cursor = 0;

  for (final length in spec.pathLengths) {
    paths.add(
      List<BoardPosition>.unmodifiable(
        traversal.sublist(cursor, cursor + length),
      ),
    );
    cursor += length + 1;
  }

  return paths;
}

List<BoardPosition> _snakeTraversal(int rows, int columns) {
  return [
    for (var row = 0; row < rows; row += 1)
      if (row.isEven)
        for (var column = 0; column < columns; column += 1)
          BoardPosition(row: row, column: column)
      else
        for (var column = columns - 1; column >= 0; column -= 1)
          BoardPosition(row: row, column: column),
  ];
}

bool _isInside(BoardPosition position, GameLevel level) {
  return position.row >= 0 &&
      position.row < level.rows &&
      position.column >= 0 &&
      position.column < level.columns;
}

bool _areAdjacent(BoardPosition first, BoardPosition second) {
  return (first.row - second.row).abs() +
          (first.column - second.column).abs() ==
      1;
}

class _NatureLevelSpec {
  const _NatureLevelSpec({
    required this.levelNumber,
    required this.rows,
    required this.columns,
    required this.pairCount,
    required this.pathLengths,
  });

  final int levelNumber;
  final int rows;
  final int columns;
  final int pairCount;
  final List<int> pathLengths;
}

const _levelSpecs = [
  _NatureLevelSpec(
    levelNumber: 1,
    rows: 4,
    columns: 4,
    pairCount: 3,
    pathLengths: [3, 3, 3],
  ),
  _NatureLevelSpec(
    levelNumber: 2,
    rows: 5,
    columns: 4,
    pairCount: 3,
    pathLengths: [4, 3, 4],
  ),
  _NatureLevelSpec(
    levelNumber: 3,
    rows: 5,
    columns: 5,
    pairCount: 4,
    pathLengths: [4, 4, 3, 4],
  ),
  _NatureLevelSpec(
    levelNumber: 4,
    rows: 6,
    columns: 5,
    pairCount: 4,
    pathLengths: [5, 4, 5, 4],
  ),
  _NatureLevelSpec(
    levelNumber: 5,
    rows: 6,
    columns: 6,
    pairCount: 5,
    pathLengths: [4, 5, 4, 5, 4],
  ),
  _NatureLevelSpec(
    levelNumber: 6,
    rows: 7,
    columns: 6,
    pairCount: 5,
    pathLengths: [5, 5, 5, 4, 5],
  ),
  _NatureLevelSpec(
    levelNumber: 7,
    rows: 8,
    columns: 6,
    pairCount: 6,
    pathLengths: [5, 5, 4, 5, 5, 4],
  ),
  _NatureLevelSpec(
    levelNumber: 8,
    rows: 9,
    columns: 6,
    pairCount: 6,
    pathLengths: [6, 5, 5, 5, 6, 5],
  ),
  _NatureLevelSpec(
    levelNumber: 9,
    rows: 10,
    columns: 6,
    pairCount: 7,
    pathLengths: [5, 6, 5, 5, 6, 5, 5],
  ),
  _NatureLevelSpec(
    levelNumber: 10,
    rows: 10,
    columns: 7,
    pairCount: 7,
    pathLengths: [6, 6, 5, 6, 5, 6, 5],
  ),
  _NatureLevelSpec(
    levelNumber: 11,
    rows: 11,
    columns: 7,
    pairCount: 8,
    pathLengths: [6, 5, 6, 5, 6, 5, 6, 5],
  ),
  _NatureLevelSpec(
    levelNumber: 12,
    rows: 12,
    columns: 7,
    pairCount: 8,
    pathLengths: [7, 6, 6, 5, 7, 6, 6, 5],
  ),
  _NatureLevelSpec(
    levelNumber: 13,
    rows: 12,
    columns: 8,
    pairCount: 9,
    pathLengths: [6, 6, 7, 6, 6, 7, 6, 6, 7],
  ),
  _NatureLevelSpec(
    levelNumber: 14,
    rows: 13,
    columns: 8,
    pairCount: 9,
    pathLengths: [7, 7, 6, 7, 7, 6, 7, 7, 6],
  ),
  _NatureLevelSpec(
    levelNumber: 15,
    rows: 14,
    columns: 8,
    pairCount: 10,
    pathLengths: [7, 7, 7, 6, 7, 7, 7, 6, 7, 7],
  ),
];
