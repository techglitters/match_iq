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

  final relationships = List<LearningRelationship>.of(LearningRelationships.all)
    ..shuffle(levelRandom);
  final selectedRelationships = relationships.take(cappedPairCount).toList();
  final boardTraversal = _randomBoardTraversal(levelRandom);
  final pathSegments = _sliceTraversalIntoPaths(
    traversal: boardTraversal,
    pairCount: cappedPairCount,
    random: levelRandom,
  );

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

List<List<BoardPosition>> _sliceTraversalIntoPaths({
  required List<BoardPosition> traversal,
  required int pairCount,
  required math.Random random,
}) {
  final pathLengths = _randomPathLengths(pairCount: pairCount, random: random);
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
  required math.Random random,
}) {
  final targetUsedCells = math.min(
    _totalCellCount,
    math.max(
      pairCount * 2,
      GameConstants.boardRows + GameConstants.boardColumns + pairCount + 4,
    ),
  );
  final maxPathLength = _maxPathLength(pairCount);
  final lengths = List<int>.filled(pairCount, 2);
  var extraCells = targetUsedCells - pairCount * 2;

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
