import 'dart:math' as math;
import 'dart:ui';

import '../domain/models/board_position.dart';
import '../domain/models/game_level.dart';
import '../domain/models/game_path.dart';
import '../domain/models/learning_relationship.dart';
import '../domain/models/level_pair_placement.dart';
import '../domain/models/level_solution.dart';

class GeneratedThemeLevel {
  const GeneratedThemeLevel({required this.level, required this.solutionPaths});

  final GameLevel level;
  final Map<String, GamePath> solutionPaths;
}

class ThemeBoardProfile {
  const ThemeBoardProfile({
    required this.maxRows,
    required this.maxColumns,
    required this.maxPairs,
  });

  static const large = ThemeBoardProfile(
    maxRows: 14,
    maxColumns: 8,
    maxPairs: 10,
  );

  final int maxRows;
  final int maxColumns;
  final int maxPairs;

  factory ThemeBoardProfile.forSize(Size size) {
    final shortestSide = math.min(size.width, size.height);
    final longestSide = math.max(size.width, size.height);

    if (shortestSide < 390 || longestSide < 720) {
      return const ThemeBoardProfile(maxRows: 10, maxColumns: 6, maxPairs: 7);
    }

    if (shortestSide < 600) {
      return const ThemeBoardProfile(maxRows: 12, maxColumns: 7, maxPairs: 9);
    }

    return large;
  }
}

List<GameLevel> buildThemedLevels({
  required String idPrefix,
  required String namePrefix,
  required List<LearningRelationship> relationships,
  int totalLevelCount = 15,
  ThemeBoardProfile profile = ThemeBoardProfile.large,
}) {
  return List<GameLevel>.unmodifiable([
    for (var levelNumber = 1; levelNumber <= totalLevelCount; levelNumber += 1)
      buildThemedLevel(
        idPrefix: idPrefix,
        namePrefix: namePrefix,
        relationships: relationships,
        totalLevelCount: totalLevelCount,
        levelNumber: levelNumber,
        profile: profile,
      ),
  ]);
}

GameLevel buildThemedLevel({
  required String idPrefix,
  required String namePrefix,
  required List<LearningRelationship> relationships,
  required int totalLevelCount,
  required int levelNumber,
  ThemeBoardProfile profile = ThemeBoardProfile.large,
}) {
  final blueprint = _LevelBlueprint.forLevel(
    levelNumber: levelNumber.clamp(1, totalLevelCount).toInt(),
    totalLevelCount: totalLevelCount,
    relationshipCount: relationships.length,
    profile: profile,
  );
  final paths = _partitionTraversalIntoPaths(
    traversal: _challengingTraversal(blueprint.rows, blueprint.columns),
    pairCount: blueprint.pairCount,
  );
  final levelRelationships = [
    for (var index = 0; index < blueprint.pairCount; index += 1)
      relationships[(blueprint.levelNumber + index - 1) % relationships.length],
  ];
  final placements = <LevelPairPlacement>[];
  final solutions = <LevelSolution>[];

  for (var index = 0; index < blueprint.pairCount; index += 1) {
    final relationship = levelRelationships[index];
    final path = _orientedPath(paths[index], blueprint.levelNumber + index);
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
    id: '${idPrefix}_${blueprint.levelNumber}',
    name: '$namePrefix ${blueprint.levelNumber}',
    levelNumber: blueprint.levelNumber,
    rows: blueprint.rows,
    columns: blueprint.columns,
    pairs: List<LevelPairPlacement>.unmodifiable(placements),
    threeStarMoveTarget: blueprint.pairCount,
    twoStarMoveTarget: blueprint.pairCount + 2,
    solutions: List<LevelSolution>.unmodifiable(solutions),
  );
}

List<GeneratedThemeLevel> generatedThemedLevels({
  required List<GameLevel> levels,
}) {
  return [for (final level in levels) generatedThemeLevelFromGameLevel(level)];
}

GeneratedThemeLevel generatedThemeLevelFromGameLevel(GameLevel level) {
  return GeneratedThemeLevel(
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

List<String> validateThemedLevelSolutions(GameLevel level) {
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

  final occupiedRatio =
      occupiedSolutionCells.length / (level.rows * level.columns);
  if (occupiedRatio < 0.92) {
    errors.add('${level.id}: known solutions should use most of the board');
  }

  return errors;
}

List<BoardPosition> _orientedPath(List<BoardPosition> path, int seed) {
  if (seed.isEven) {
    return List<BoardPosition>.unmodifiable(path.reversed);
  }
  return path;
}

List<List<BoardPosition>> _partitionTraversalIntoPaths({
  required List<BoardPosition> traversal,
  required int pairCount,
}) {
  final plannedLengths = _planPathLengths(
    traversal: traversal,
    pairCount: pairCount,
  );
  final paths = <List<BoardPosition>>[];
  var cursor = 0;

  for (final length in plannedLengths) {
    paths.add(
      List<BoardPosition>.unmodifiable(
        traversal.sublist(cursor, cursor + length),
      ),
    );
    cursor += length;
  }

  return paths;
}

List<int> _planPathLengths({
  required List<BoardPosition> traversal,
  required int pairCount,
}) {
  final planned = <int>[];
  if (_choosePathLengths(
    traversal: traversal,
    pairCount: pairCount,
    cursor: 0,
    planned: planned,
  )) {
    return planned;
  }

  final totalCells = traversal.length;
  final baseLength = totalCells ~/ pairCount;
  final remainder = totalCells % pairCount;
  return [
    for (var index = 0; index < pairCount; index += 1)
      baseLength + (index < remainder ? 1 : 0),
  ];
}

bool _choosePathLengths({
  required List<BoardPosition> traversal,
  required int pairCount,
  required int cursor,
  required List<int> planned,
}) {
  final pathIndex = planned.length;
  final remainingPaths = pairCount - pathIndex;
  final remainingCells = traversal.length - cursor;
  const minimumPathLength = 3;

  if (remainingPaths == 1) {
    if (_isInterestingSegment(traversal, cursor, remainingCells)) {
      planned.add(remainingCells);
      return true;
    }
    return false;
  }

  final targetLength = remainingCells ~/ remainingPaths;
  final maxLength = remainingCells - minimumPathLength * (remainingPaths - 1);
  final candidateLengths =
      [
        for (var length = minimumPathLength; length <= maxLength; length += 1)
          length,
      ]..sort((first, second) {
        final firstDistance = (first - targetLength).abs();
        final secondDistance = (second - targetLength).abs();
        if (firstDistance != secondDistance) {
          return firstDistance.compareTo(secondDistance);
        }
        return second.compareTo(first);
      });

  for (final length in candidateLengths) {
    if (!_isInterestingSegment(traversal, cursor, length)) {
      continue;
    }

    planned.add(length);
    if (_choosePathLengths(
      traversal: traversal,
      pairCount: pairCount,
      cursor: cursor + length,
      planned: planned,
    )) {
      return true;
    }
    planned.removeLast();
  }

  return false;
}

bool _isInterestingSegment(
  List<BoardPosition> traversal,
  int startIndex,
  int length,
) {
  if (length < 2 || startIndex + length > traversal.length) {
    return false;
  }

  final start = traversal[startIndex];
  final end = traversal[startIndex + length - 1];
  return start.row != end.row && start.column != end.column;
}

List<BoardPosition> _challengingTraversal(int rows, int columns) {
  final traversal = _spiralTraversal(rows, columns);
  if (rows < 7 && columns < 7) {
    return traversal;
  }

  final transformed = <BoardPosition>[];
  final seen = <BoardPosition>{};

  for (final position in traversal) {
    final shifted = position.row.isOdd
        ? BoardPosition(
            row: position.row,
            column: columns - 1 - position.column,
          )
        : position;

    if (seen.add(shifted)) {
      transformed.add(shifted);
    }
  }

  if (transformed.length == rows * columns &&
      _isContinuousTraversal(transformed)) {
    return List<BoardPosition>.unmodifiable(transformed);
  }

  return traversal;
}

List<BoardPosition> _spiralTraversal(int rows, int columns) {
  final traversal = <BoardPosition>[];
  var top = 0;
  var bottom = rows - 1;
  var left = 0;
  var right = columns - 1;

  while (top <= bottom && left <= right) {
    for (var column = left; column <= right; column += 1) {
      traversal.add(BoardPosition(row: top, column: column));
    }
    top += 1;

    for (var row = top; row <= bottom; row += 1) {
      traversal.add(BoardPosition(row: row, column: right));
    }
    right -= 1;

    if (top <= bottom) {
      for (var column = right; column >= left; column -= 1) {
        traversal.add(BoardPosition(row: bottom, column: column));
      }
      bottom -= 1;
    }

    if (left <= right) {
      for (var row = bottom; row >= top; row -= 1) {
        traversal.add(BoardPosition(row: row, column: left));
      }
      left += 1;
    }
  }

  return List<BoardPosition>.unmodifiable(traversal);
}

bool _isContinuousTraversal(List<BoardPosition> traversal) {
  for (var index = 1; index < traversal.length; index += 1) {
    if (!_areAdjacent(traversal[index - 1], traversal[index])) {
      return false;
    }
  }
  return true;
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

class _LevelBlueprint {
  const _LevelBlueprint({
    required this.levelNumber,
    required this.rows,
    required this.columns,
    required this.pairCount,
  });

  final int levelNumber;
  final int rows;
  final int columns;
  final int pairCount;

  factory _LevelBlueprint.forLevel({
    required int levelNumber,
    required int totalLevelCount,
    required int relationshipCount,
    required ThemeBoardProfile profile,
  }) {
    final progress = totalLevelCount <= 1
        ? 1.0
        : (levelNumber - 1) / (totalLevelCount - 1);
    final rows = _scaledValue(
      start: 5,
      end: profile.maxRows,
      progress: progress,
    );
    final columns = _scaledValue(
      start: 5,
      end: profile.maxColumns,
      progress: progress,
    );
    final pairCount = _scaledValue(
      start: 3,
      end: profile.maxPairs,
      progress: progress,
    ).clamp(3, relationshipCount);

    return _LevelBlueprint(
      levelNumber: levelNumber,
      rows: rows,
      columns: columns,
      pairCount: math.min(pairCount, rows * columns ~/ 6),
    );
  }

  static int _scaledValue({
    required int start,
    required int end,
    required double progress,
  }) {
    return (start + (end - start) * progress).round().clamp(start, end);
  }
}
