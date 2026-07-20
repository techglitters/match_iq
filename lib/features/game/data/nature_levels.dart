import 'dart:math' as math;

import '../../../core/constants/game_constants.dart';
import '../domain/models/board_position.dart';
import '../domain/models/game_level.dart';
import '../domain/models/game_path.dart';
import '../domain/models/level_pair_placement.dart';
import '../domain/models/learning_relationship.dart';
import 'learning_relationships.dart';

class GeneratedNatureLevel {
  const GeneratedNatureLevel({
    required this.level,
    required this.solutionPaths,
  });

  final GameLevel level;
  final Map<String, GamePath> solutionPaths;
}

List<GameLevel> createNatureLevels({math.Random? random}) {
  return List<GameLevel>.unmodifiable(
    createGeneratedNatureLevels(random: random).map((level) => level.level),
  );
}

List<GeneratedNatureLevel> createGeneratedNatureLevels({math.Random? random}) {
  final levelRandom = random ?? math.Random();
  final maxPairCount = _maxSupportedPairCount();

  return List<GeneratedNatureLevel>.unmodifiable([
    for (
      var pairCount = GameConstants.startingPairsPerLevel;
      pairCount <= maxPairCount;
      pairCount += 1
    )
      generateNatureLevel(
        levelNumber: pairCount - GameConstants.startingPairsPerLevel + 1,
        pairCount: pairCount,
        random: levelRandom,
      ),
  ]);
}

GeneratedNatureLevel generateNatureLevel({
  required int levelNumber,
  required int pairCount,
  math.Random? random,
}) {
  final levelRandom = random ?? math.Random();
  final cappedPairCount = pairCount.clamp(1, _maxSupportedPairCount()).toInt();
  final difficulty = _DifficultyProfile.forLevel(
    levelNumber: levelNumber,
    pairCount: cappedPairCount,
  );

  final relationships = List<LearningRelationship>.of(LearningRelationships.all)
    ..shuffle(levelRandom);
  final selectedRelationships = relationships.take(cappedPairCount).toList();
  var pathSegments = <List<BoardPosition>>[];
  var bestDifficultyScore = double.negativeInfinity;

  for (var attempt = 0; attempt < difficulty.searchAttempts; attempt += 1) {
    final boardTraversal = _randomBoardTraversal(levelRandom);
    final candidateSegments = _sliceTraversalIntoPaths(
      traversal: boardTraversal,
      pairCount: cappedPairCount,
      difficulty: difficulty,
      random: levelRandom,
    );

    if (!_hasValidEndpointSpacing(candidateSegments, difficulty)) {
      continue;
    }

    final difficultyScore = _difficultyScore(candidateSegments, difficulty);
    if (difficultyScore > bestDifficultyScore) {
      pathSegments = candidateSegments;
      bestDifficultyScore = difficultyScore;
    }

    if (_meetsTargetDifficulty(candidateSegments, difficulty) &&
        difficultyScore >= difficulty.acceptableScore) {
      break;
    }
  }

  if (pathSegments.isEmpty) {
    pathSegments = _fallbackPathSegments(cappedPairCount);
  }

  final placements = <LevelPairPlacement>[];
  final solutionPaths = <String, GamePath>{};

  for (var index = 0; index < selectedRelationships.length; index += 1) {
    final relationship = selectedRelationships[index];
    final cells = pathSegments[index];

    solutionPaths[relationship.id] = GamePath(
      relationshipId: relationship.id,
      cells: List<BoardPosition>.unmodifiable(cells),
      isComplete: true,
    );
    placements.add(
      LevelPairPlacement(
        relationship: relationship,
        sourcePosition: cells.first,
        targetPosition: cells.last,
      ),
    );
  }

  return GeneratedNatureLevel(
    level: GameLevel(
      id: 'nature_$levelNumber',
      name: 'Nature $levelNumber',
      rows: GameConstants.boardRows,
      columns: GameConstants.boardColumns,
      pairs: List<LevelPairPlacement>.unmodifiable(placements),
    ),
    solutionPaths: Map<String, GamePath>.unmodifiable(solutionPaths),
  );
}

bool _hasValidEndpointSpacing(
  List<List<BoardPosition>> pathSegments,
  _DifficultyProfile difficulty,
) {
  final endpointPositions = _endpointPositionsFor(pathSegments);

  return pathSegments.every((path) {
    return path.length >= difficulty.minimumPathCells &&
        _distance(path.first, path.last) >=
            difficulty.minimumEndpointDistance &&
        !_sharesStraightAxis(path.first, path.last) &&
        _turnCount(path) >= difficulty.minimumTurnsPerPath &&
        _shortestAvailablePathCellCount(
              path.first,
              path.last,
              blockedEndpoints: endpointPositions,
            ) >=
            difficulty.minimumShortestPathCells;
  });
}

List<List<BoardPosition>> _sliceTraversalIntoPaths({
  required List<BoardPosition> traversal,
  required int pairCount,
  required _DifficultyProfile difficulty,
  required math.Random random,
}) {
  final pathLengths = _randomPathLengths(
    pairCount: pairCount,
    difficulty: difficulty,
    random: random,
  );
  final usedCellCount = pathLengths.fold<int>(
    0,
    (total, length) => total + length,
  );
  final gaps = _randomGapLengths(
    gapCellCount: _totalCellCount - usedCellCount,
    gapCount: pairCount + 1,
    random: random,
  );

  final paths = <List<BoardPosition>>[];
  var cursor = gaps.first;

  for (var index = 0; index < pairCount; index += 1) {
    final length = pathLengths[index];
    paths.add(
      List<BoardPosition>.unmodifiable(
        traversal.sublist(cursor, cursor + length),
      ),
    );
    cursor += length + gaps[index + 1];
  }

  return paths;
}

List<int> _randomPathLengths({
  required int pairCount,
  required _DifficultyProfile difficulty,
  required math.Random random,
}) {
  final targetUsedCells = math.min(
    _totalCellCount,
    math.max(pairCount * difficulty.minimumPathCells, difficulty.usedCellGoal),
  );
  final maxPathLength = _maxPathLength(pairCount);
  final basePathLength = math.min(difficulty.minimumPathCells, maxPathLength);
  final lengths = List<int>.filled(pairCount, basePathLength);
  var extraCells = targetUsedCells - pairCount * basePathLength;

  while (extraCells > 0) {
    final expandableIndexes = [
      for (var index = 0; index < lengths.length; index += 1)
        if (lengths[index] < maxPathLength) index,
    ];
    if (expandableIndexes.isEmpty) {
      break;
    }

    lengths[expandableIndexes[random.nextInt(expandableIndexes.length)]] += 1;
    extraCells -= 1;
  }

  lengths.shuffle(random);
  return lengths;
}

bool _meetsTargetDifficulty(
  List<List<BoardPosition>> pathSegments,
  _DifficultyProfile difficulty,
) {
  final endpointPositions = _endpointPositionsFor(pathSegments);
  final shortestPathLengths = [
    for (final path in pathSegments)
      _shortestAvailablePathCellCount(
        path.first,
        path.last,
        blockedEndpoints: endpointPositions,
      ),
  ];

  return _usedCellCount(pathSegments) >= difficulty.usedCellGoal &&
      _totalTurnCount(pathSegments) >= difficulty.preferredTotalTurns &&
      shortestPathLengths.every(
        (length) => length >= difficulty.minimumShortestPathCells,
      );
}

double _difficultyScore(
  List<List<BoardPosition>> pathSegments,
  _DifficultyProfile difficulty,
) {
  final endpointPositions = _endpointPositionsFor(pathSegments);
  final usedCells = _usedCellCount(pathSegments);
  final totalTurns = _totalTurnCount(pathSegments);
  final shortestPathPressure = pathSegments.fold<int>(0, (total, path) {
    final shortestPathCells = _shortestAvailablePathCellCount(
      path.first,
      path.last,
      blockedEndpoints: endpointPositions,
    );
    return total + math.min(shortestPathCells, difficulty.shortestPathScoreCap);
  });
  final shortcutPenalty = pathSegments.fold<int>(0, (total, path) {
    final shortestPathCells = _shortestAvailablePathCellCount(
      path.first,
      path.last,
      blockedEndpoints: endpointPositions,
    );
    return total +
        math.max(0, difficulty.minimumShortestPathCells - shortestPathCells);
  });

  return usedCells * 3.0 +
      totalTurns * 4.5 +
      shortestPathPressure * 2.0 +
      _overlappingRouteBoxScore(pathSegments) * 2.0 -
      shortcutPenalty * 8.0;
}

int _usedCellCount(List<List<BoardPosition>> pathSegments) {
  return pathSegments.fold<int>(0, (total, path) => total + path.length);
}

int _totalTurnCount(List<List<BoardPosition>> pathSegments) {
  return pathSegments.fold<int>(0, (total, path) => total + _turnCount(path));
}

Set<BoardPosition> _endpointPositionsFor(List<List<BoardPosition>> paths) {
  return {
    for (final path in paths) ...[path.first, path.last],
  };
}

int _shortestAvailablePathCellCount(
  BoardPosition start,
  BoardPosition target, {
  required Set<BoardPosition> blockedEndpoints,
}) {
  final blockedPositions = {
    for (final endpoint in blockedEndpoints)
      if (endpoint != start && endpoint != target) endpoint,
  };
  final visited = <BoardPosition>{start};
  final queue = <({BoardPosition position, int cells})>[
    (position: start, cells: 1),
  ];
  var cursor = 0;

  while (cursor < queue.length) {
    final current = queue[cursor];
    cursor += 1;

    for (final neighbor in _neighbors(current.position)) {
      if (blockedPositions.contains(neighbor) || !visited.add(neighbor)) {
        continue;
      }

      final cellCount = current.cells + 1;
      if (neighbor == target) {
        return cellCount;
      }

      queue.add((position: neighbor, cells: cellCount));
    }
  }

  return _totalCellCount + 1;
}

int _overlappingRouteBoxScore(List<List<BoardPosition>> pathSegments) {
  var score = 0;
  final routeBoxes = [
    for (final path in pathSegments) _routeBoxCells(path.first, path.last),
  ];

  for (var first = 0; first < routeBoxes.length; first += 1) {
    for (var second = first + 1; second < routeBoxes.length; second += 1) {
      score += math.min(
        6,
        routeBoxes[first].intersection(routeBoxes[second]).length,
      );
    }
  }

  return score;
}

Set<BoardPosition> _routeBoxCells(BoardPosition first, BoardPosition second) {
  final minRow = math.min(first.row, second.row);
  final maxRow = math.max(first.row, second.row);
  final minColumn = math.min(first.column, second.column);
  final maxColumn = math.max(first.column, second.column);

  return {
    for (var row = minRow; row <= maxRow; row += 1)
      for (var column = minColumn; column <= maxColumn; column += 1)
        BoardPosition(row: row, column: column),
  };
}

List<int> _randomGapLengths({
  required int gapCellCount,
  required int gapCount,
  required math.Random random,
}) {
  final gaps = List<int>.filled(gapCount, 0);

  for (var cell = 0; cell < gapCellCount; cell += 1) {
    gaps[random.nextInt(gaps.length)] += 1;
  }

  return gaps;
}

List<List<BoardPosition>> _fallbackPathSegments(int pairCount) {
  const pathA = [
    BoardPosition(row: 0, column: 0),
    BoardPosition(row: 1, column: 0),
    BoardPosition(row: 1, column: 1),
  ];
  const pathB = [
    BoardPosition(row: 0, column: 1),
    BoardPosition(row: 0, column: 2),
    BoardPosition(row: 1, column: 2),
  ];
  const pathC = [
    BoardPosition(row: 0, column: 3),
    BoardPosition(row: 0, column: 4),
    BoardPosition(row: 1, column: 4),
  ];
  const pathD = [
    BoardPosition(row: 2, column: 0),
    BoardPosition(row: 2, column: 1),
    BoardPosition(row: 3, column: 1),
  ];
  const pathE = [
    BoardPosition(row: 2, column: 2),
    BoardPosition(row: 3, column: 2),
    BoardPosition(row: 3, column: 3),
  ];
  const pathF = [
    BoardPosition(row: 1, column: 3),
    BoardPosition(row: 2, column: 3),
    BoardPosition(row: 2, column: 4),
  ];
  const pathG = [
    BoardPosition(row: 3, column: 0),
    BoardPosition(row: 4, column: 0),
    BoardPosition(row: 4, column: 1),
  ];
  const pathH = [
    BoardPosition(row: 4, column: 2),
    BoardPosition(row: 4, column: 3),
    BoardPosition(row: 4, column: 4),
    BoardPosition(row: 3, column: 4),
  ];

  final pathAB = [...pathA, ...pathB];
  final pathDG = [...pathD, ...pathG];
  final pathFH = [...pathF, ...pathH.reversed];
  final pathABE = [...pathAB, ...pathE];
  final pathCFH = [...pathC, ...pathFH];

  final paths = switch (pairCount) {
    <= 3 => [pathABE, pathCFH, pathDG],
    7 => [pathA, pathB, pathC, pathD, pathE, pathFH, pathG],
    _ => [pathA, pathB, pathC, pathD, pathE, pathF, pathG, pathH],
  };

  return List<List<BoardPosition>>.unmodifiable(paths.take(pairCount));
}

List<BoardPosition> _randomBoardTraversal(math.Random random) {
  for (var attempt = 0; attempt < 60; attempt += 1) {
    final starts = _allBoardCells().toList()..shuffle(random);
    for (final start in starts) {
      final path = <BoardPosition>[start];
      final seen = <BoardPosition>{start};
      var searchBudget = 9000;

      if (_extendTraversal(path, seen, random, () => searchBudget-- > 0)) {
        return List<BoardPosition>.unmodifiable(path);
      }
    }
  }

  return _randomizedSnakeTraversal(random);
}

bool _extendTraversal(
  List<BoardPosition> path,
  Set<BoardPosition> seen,
  math.Random random,
  bool Function() hasBudget,
) {
  if (path.length == _totalCellCount) {
    return true;
  }

  if (!hasBudget()) {
    return false;
  }

  final candidates = _neighbors(
    path.last,
  ).where((cell) => !seen.contains(cell)).toList()..shuffle(random);
  candidates.sort(
    (first, second) => _openNeighborCount(
      first,
      seen,
    ).compareTo(_openNeighborCount(second, seen)),
  );

  for (final candidate in candidates) {
    path.add(candidate);
    seen.add(candidate);

    if (_extendTraversal(path, seen, random, hasBudget)) {
      return true;
    }

    seen.remove(candidate);
    path.removeLast();
  }

  return false;
}

List<BoardPosition> _randomizedSnakeTraversal(math.Random random) {
  final traversal = <BoardPosition>[];

  for (var row = 0; row < GameConstants.boardRows; row += 1) {
    final columns = row.isEven
        ? [
            for (
              var column = 0;
              column < GameConstants.boardColumns;
              column += 1
            )
              column,
          ]
        : [
            for (
              var column = GameConstants.boardColumns - 1;
              column >= 0;
              column -= 1
            )
              column,
          ];

    for (final column in columns) {
      traversal.add(BoardPosition(row: row, column: column));
    }
  }

  final transform = random.nextInt(8);
  final transformedTraversal = [
    for (final position in traversal) _transformPosition(position, transform),
  ];

  if (random.nextBool()) {
    return List<BoardPosition>.unmodifiable(transformedTraversal.reversed);
  }

  return List<BoardPosition>.unmodifiable(transformedTraversal);
}

BoardPosition _transformPosition(BoardPosition position, int transform) {
  final maxRow = GameConstants.boardRows - 1;
  final maxColumn = GameConstants.boardColumns - 1;

  return switch (transform) {
    0 => position,
    1 => BoardPosition(row: position.column, column: maxRow - position.row),
    2 => BoardPosition(
      row: maxRow - position.row,
      column: maxColumn - position.column,
    ),
    3 => BoardPosition(row: maxColumn - position.column, column: position.row),
    4 => BoardPosition(row: position.row, column: maxColumn - position.column),
    5 => BoardPosition(row: maxRow - position.row, column: position.column),
    6 => BoardPosition(row: position.column, column: position.row),
    _ => BoardPosition(
      row: maxColumn - position.column,
      column: maxRow - position.row,
    ),
  };
}

int _openNeighborCount(BoardPosition position, Set<BoardPosition> seen) {
  return _neighbors(position).where((cell) => !seen.contains(cell)).length;
}

int _distance(BoardPosition first, BoardPosition second) {
  return (first.row - second.row).abs() + (first.column - second.column).abs();
}

bool _sharesStraightAxis(BoardPosition first, BoardPosition second) {
  return first.row == second.row || first.column == second.column;
}

int _turnCount(List<BoardPosition> path) {
  if (path.length < 3) {
    return 0;
  }

  var turns = 0;
  var previousRowDirection = path[1].row - path[0].row;
  var previousColumnDirection = path[1].column - path[0].column;

  for (var index = 2; index < path.length; index += 1) {
    final rowDirection = path[index].row - path[index - 1].row;
    final columnDirection = path[index].column - path[index - 1].column;
    if (rowDirection != previousRowDirection ||
        columnDirection != previousColumnDirection) {
      turns += 1;
    }
    previousRowDirection = rowDirection;
    previousColumnDirection = columnDirection;
  }

  return turns;
}

Iterable<BoardPosition> _allBoardCells() sync* {
  for (var row = 0; row < GameConstants.boardRows; row += 1) {
    for (var column = 0; column < GameConstants.boardColumns; column += 1) {
      yield BoardPosition(row: row, column: column);
    }
  }
}

Iterable<BoardPosition> _neighbors(BoardPosition position) sync* {
  const offsets = [
    (row: 1, column: 0),
    (row: -1, column: 0),
    (row: 0, column: 1),
    (row: 0, column: -1),
  ];

  for (final offset in offsets) {
    final row = position.row + offset.row;
    final column = position.column + offset.column;
    if (row >= 0 &&
        row < GameConstants.boardRows &&
        column >= 0 &&
        column < GameConstants.boardColumns) {
      yield BoardPosition(row: row, column: column);
    }
  }
}

int _maxPathLength(int pairCount) {
  if (pairCount <= 3) {
    return 8;
  }
  if (pairCount <= 5) {
    return 7;
  }
  if (pairCount <= 8) {
    return 5;
  }
  return 4;
}

int _maxSupportedPairCount() {
  return math.min(
    GameConstants.maxPairsPerLevel,
    LearningRelationships.all.length,
  );
}

int get _totalCellCount => GameConstants.boardRows * GameConstants.boardColumns;

class _DifficultyProfile {
  const _DifficultyProfile({
    required this.usedCellGoal,
    required this.minimumPathCells,
    required this.minimumEndpointDistance,
    required this.minimumTurnsPerPath,
    required this.preferredTotalTurns,
    required this.minimumShortestPathCells,
    required this.shortestPathScoreCap,
    required this.acceptableScore,
    required this.searchAttempts,
  });

  factory _DifficultyProfile.forLevel({
    required int levelNumber,
    required int pairCount,
  }) {
    final clampedLevel = levelNumber.clamp(1, 6).toInt();
    final usedCellGoal = switch (pairCount) {
      <= 3 => 16 + (clampedLevel > 1 ? 1 : 0),
      4 => 20,
      5 => 22,
      6 => 24,
      _ => _totalCellCount,
    };
    final minimumPathCells = pairCount <= 6
        ? 4
        : GameConstants.minimumCellsPerPath;
    final minimumEndpointDistance = pairCount <= 6 ? 3 : 2;
    final minimumShortestPathCells = pairCount <= 6 ? 4 : 3;
    final preferredTurnsPerPath = pairCount <= 4 ? 2 : 1;
    final preferredTotalTurns = math.max(
      pairCount,
      pairCount * preferredTurnsPerPath - (6 - clampedLevel).clamp(0, 3),
    );

    return _DifficultyProfile(
      usedCellGoal: usedCellGoal,
      minimumPathCells: minimumPathCells,
      minimumEndpointDistance: minimumEndpointDistance,
      minimumTurnsPerPath: 1,
      preferredTotalTurns: preferredTotalTurns,
      minimumShortestPathCells: minimumShortestPathCells,
      shortestPathScoreCap: 8 + clampedLevel,
      acceptableScore: 90 + clampedLevel * 18 + pairCount * 12,
      searchAttempts: 36 + clampedLevel * 6,
    );
  }

  final int usedCellGoal;
  final int minimumPathCells;
  final int minimumEndpointDistance;
  final int minimumTurnsPerPath;
  final int preferredTotalTurns;
  final int minimumShortestPathCells;
  final int shortestPathScoreCap;
  final double acceptableScore;
  final int searchAttempts;
}
