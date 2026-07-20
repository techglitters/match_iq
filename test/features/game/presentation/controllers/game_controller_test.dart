import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:match_iq/core/constants/game_constants.dart';
import 'package:match_iq/features/game/data/learning_relationships.dart';
import 'package:match_iq/features/game/data/nature_levels.dart';
import 'package:match_iq/features/game/domain/models/board_position.dart';
import 'package:match_iq/features/game/domain/models/game_level.dart';
import 'package:match_iq/features/game/domain/models/game_path.dart';
import 'package:match_iq/features/game/domain/models/level_pair_placement.dart';
import 'package:match_iq/features/game/presentation/controllers/game_controller.dart';

void main() {
  group('Nature level generation', () {
    test('creates random levels from 3 pairs to grid capacity', () {
      final generatedLevels = createGeneratedNatureLevels(
        random: math.Random(12),
      );

      expect(GameConstants.minimumLineSegmentsPerPath, 2);
      expect(GameConstants.maxPairsPerLevel, 8);
      expect(generatedLevels.map((level) => level.level.pairs.length), [
        3,
        4,
        5,
        6,
        7,
        8,
      ]);
      expect(generatedLevels.every(_isWithinPairCap), isTrue);
    });

    test('generated paths require at least two line segments', () {
      final generatedLevels = createGeneratedNatureLevels(
        random: math.Random(31),
      );

      for (final generatedLevel in generatedLevels) {
        for (final path in generatedLevel.solutionPaths.values) {
          expect(path.cells.length, greaterThanOrEqualTo(3));
          expect(
            _areAdjacent(path.cells.first, path.cells.last),
            isFalse,
            reason: '${generatedLevel.level.id} ${path.relationshipId}',
          );
        }
      }
    });

    test('generated layouts use more board space as levels increase', () {
      final generatedLevels = createGeneratedNatureLevels(
        random: math.Random(12),
      );

      expect(generatedLevels.map(_usedCellCount), [16, 20, 22, 24, 25, 25]);
    });

    test('generated pairs avoid obvious straight-line connections', () {
      final generatedLevels = createGeneratedNatureLevels(
        random: math.Random(41),
      );

      for (final generatedLevel in generatedLevels) {
        final endpointPositions = _endpointPositionsFor(generatedLevel);
        final minimumShortestPathCells = generatedLevel.level.pairs.length <= 6
            ? 4
            : 3;

        for (final path in generatedLevel.solutionPaths.values) {
          expect(
            _sharesStraightAxis(path.cells.first, path.cells.last),
            isFalse,
            reason: '${generatedLevel.level.id} ${path.relationshipId}',
          );
          expect(
            _turnCount(path.cells),
            greaterThanOrEqualTo(1),
            reason: '${generatedLevel.level.id} ${path.relationshipId}',
          );
          expect(
            _shortestAvailablePathCellCount(
              path.cells.first,
              path.cells.last,
              blockedEndpoints: endpointPositions,
            ),
            greaterThanOrEqualTo(minimumShortestPathCells),
            reason: '${generatedLevel.level.id} ${path.relationshipId}',
          );
        }
      }
    });

    test('different seeds create different endpoint layouts', () {
      final first = createGeneratedNatureLevels(random: math.Random(4));
      final second = createGeneratedNatureLevels(random: math.Random(99));

      expect(_levelSignature(first), isNot(_levelSignature(second)));
    });

    test('generated random solution paths complete every level', () {
      final generatedLevels = createGeneratedNatureLevels(
        random: math.Random(21),
      );

      for (final generatedLevel in generatedLevels) {
        final controller = GameController(initialLevel: generatedLevel.level);

        _completeGeneratedLevel(controller, generatedLevel);

        expect(
          controller.connectedPairCount,
          generatedLevel.level.pairs.length,
        );
        expect(controller.isLevelComplete, isTrue);
      }
    });
  });

  group('GameController', () {
    test('next level loads a harder random capped layout after completion', () {
      final generatedLevels = createGeneratedNatureLevels(
        random: math.Random(7),
      );
      final levels = generatedLevels.map((level) => level.level).toList();
      final controller = GameController(
        initialLevel: levels.first,
        levels: levels,
      );

      expect(controller.goToNextLevel(), isFalse);
      _completeGeneratedLevel(controller, generatedLevels.first);

      expect(controller.goToNextLevel(), isTrue);
      expect(controller.level.id, 'nature_2');
      expect(controller.totalPairCount, 4);
      expect(controller.moves, 0);
      expect(controller.connectedPairCount, 0);
      expect(controller.isLevelComplete, isFalse);
    });

    test('path cannot start from an empty cell', () {
      final generatedLevel = _generatedLevel();
      final controller = GameController(initialLevel: generatedLevel.level);
      final emptyPosition = _firstNonEndpoint(controller);

      expect(controller.startPath(emptyPosition), isFalse);
      expect(controller.isDragging, isFalse);
      expect(controller.activePath, isEmpty);
      expect(controller.finishPath(), isFalse);
      expect(controller.moves, 1);
    });

    test('path can start from a valid endpoint', () {
      final generatedLevel = _generatedLevel();
      final controller = GameController(initialLevel: generatedLevel.level);
      final path = generatedLevel.solutionPaths.values.first;

      expect(controller.startPath(path.cells.first), isTrue);
      expect(controller.isDragging, isTrue);
      expect(controller.activePath, [path.cells.first]);
    });

    test('diagonal movement is rejected', () {
      final generatedLevel = _generatedLevel();
      final controller = GameController(initialLevel: generatedLevel.level);
      final start = generatedLevel.level.pairs.first.sourcePosition;
      final diagonalPosition = _diagonalFrom(start, generatedLevel.level);

      controller.startPath(start);

      expect(controller.extendPath(diagonalPosition), isFalse);
      expect(controller.activePath.length, 1);
    });

    test('orthogonal movement is accepted', () {
      final generatedLevel = _generatedLevel();
      final controller = GameController(initialLevel: generatedLevel.level);
      final path = generatedLevel.solutionPaths.values.first;

      controller.startPath(path.cells.first);

      expect(controller.extendPath(path.cells[1]), isTrue);
      expect(controller.activePath.last, path.cells[1]);
    });

    test('backtracking removes the latest cell', () {
      final generatedLevel = _generatedLevel();
      final controller = GameController(initialLevel: generatedLevel.level);
      final path = generatedLevel.solutionPaths.values.first;

      controller
        ..startPath(path.cells.first)
        ..extendPath(path.cells[1]);

      expect(controller.extendPath(path.cells.first), isTrue);
      expect(controller.activePath, [path.cells.first]);
    });

    test('path cannot cross a completed path', () {
      final controller = GameController(initialLevel: _ruleLevel);

      _completePath(controller, const [
        BoardPosition(row: 0, column: 0),
        BoardPosition(row: 0, column: 1),
        BoardPosition(row: 0, column: 2),
      ]);

      controller.startPath(const BoardPosition(row: 1, column: 1));

      expect(
        controller.extendPath(const BoardPosition(row: 0, column: 1)),
        isFalse,
      );
    });

    test('wrong endpoint rejects the path', () {
      final controller = GameController(initialLevel: _ruleLevel);

      controller.startPath(const BoardPosition(row: 0, column: 0));

      expect(
        controller.extendPath(const BoardPosition(row: 1, column: 0)),
        isTrue,
      );
      expect(
        controller.extendPath(const BoardPosition(row: 1, column: 1)),
        isFalse,
      );
      expect(controller.finishPath(), isFalse);
      expect(controller.completedPaths, isEmpty);
    });

    test('wrong endpoint creates rejected path and clears active drag', () {
      final controller = GameController(initialLevel: _ruleLevel);

      controller.startPath(const BoardPosition(row: 0, column: 0));

      expect(
        controller.extendPath(const BoardPosition(row: 1, column: 0)),
        isTrue,
      );

      final rejectedPath = controller.rejectWrongEndpoint(
        const BoardPosition(row: 1, column: 1),
      );

      expect(rejectedPath, isNotNull);
      expect(rejectedPath!.cells, const [
        BoardPosition(row: 0, column: 0),
        BoardPosition(row: 1, column: 0),
        BoardPosition(row: 1, column: 1),
      ]);
      expect(controller.activePath, isEmpty);
      expect(controller.isDragging, isFalse);
      expect(controller.completedPaths, isEmpty);
      expect(controller.moves, 1);
    });

    test(
      'correct endpoint is rejected when path has fewer than two segments',
      () {
        final controller = GameController(initialLevel: _shortPathRuleLevel);

        controller.startPath(const BoardPosition(row: 0, column: 0));

        expect(
          controller.extendPath(const BoardPosition(row: 0, column: 1)),
          isTrue,
        );
        expect(controller.finishPath(), isFalse);
        expect(controller.completedPaths, isEmpty);
      },
    );

    test('correct endpoint saves the path', () {
      final generatedLevel = _generatedLevel();
      final controller = GameController(initialLevel: generatedLevel.level);
      final path = generatedLevel.solutionPaths.values.first;

      _completeGamePath(controller, path);

      expect(controller.completedPaths, contains(path.relationshipId));
      expect(controller.completedPathOrder, [path.relationshipId]);
      expect(controller.connectedPairCount, 1);
    });

    test('undo removes the latest completed path', () {
      final generatedLevel = _generatedLevel();
      final controller = GameController(initialLevel: generatedLevel.level);
      final paths = generatedLevel.solutionPaths.values.take(2).toList();

      _completeGamePath(controller, paths.first);
      _completeGamePath(controller, paths.last);

      expect(controller.undoLastPath(), isTrue);
      expect(
        controller.completedPaths,
        isNot(contains(paths.last.relationshipId)),
      );
      expect(controller.completedPathOrder, [paths.first.relationshipId]);
      expect(controller.isLevelComplete, isFalse);
    });

    test('restart resets the game', () {
      final generatedLevel = _generatedLevel();
      final controller = GameController(initialLevel: generatedLevel.level);

      _completeGamePath(controller, generatedLevel.solutionPaths.values.first);

      controller.restartLevel();

      expect(controller.completedPaths, isEmpty);
      expect(controller.completedPathOrder, isEmpty);
      expect(controller.activePath, isEmpty);
      expect(controller.moves, 0);
      expect(controller.isDragging, isFalse);
      expect(controller.isLevelComplete, isFalse);
    });

    test('level completes after all pairs are connected', () {
      final generatedLevel = _generatedLevel();
      final controller = GameController(initialLevel: generatedLevel.level);

      _completeGeneratedLevel(controller, generatedLevel);

      expect(controller.connectedPairCount, generatedLevel.level.pairs.length);
      expect(controller.isLevelComplete, isTrue);
    });
  });
}

const _ruleLevel = GameLevel(
  id: 'rule_test',
  name: 'Rule Test',
  rows: GameConstants.boardRows,
  columns: GameConstants.boardColumns,
  pairs: [
    LevelPairPlacement(
      relationship: LearningRelationships.seedToFlower,
      sourcePosition: BoardPosition(row: 0, column: 0),
      targetPosition: BoardPosition(row: 0, column: 2),
    ),
    LevelPairPlacement(
      relationship: LearningRelationships.treeToFruit,
      sourcePosition: BoardPosition(row: 1, column: 1),
      targetPosition: BoardPosition(row: 2, column: 1),
    ),
  ],
);

const _shortPathRuleLevel = GameLevel(
  id: 'short_path_rule_test',
  name: 'Short Path Rule Test',
  rows: GameConstants.boardRows,
  columns: GameConstants.boardColumns,
  pairs: [
    LevelPairPlacement(
      relationship: LearningRelationships.seedToFlower,
      sourcePosition: BoardPosition(row: 0, column: 0),
      targetPosition: BoardPosition(row: 0, column: 1),
    ),
  ],
);

GeneratedNatureLevel _generatedLevel() {
  return generateNatureLevel(
    levelNumber: 1,
    pairCount: GameConstants.startingPairsPerLevel,
    random: math.Random(18),
  );
}

bool _isWithinPairCap(GeneratedNatureLevel generatedLevel) {
  return generatedLevel.level.pairs.length <= GameConstants.maxPairsPerLevel;
}

int _usedCellCount(GeneratedNatureLevel generatedLevel) {
  return generatedLevel.solutionPaths.values.fold<int>(
    0,
    (total, path) => total + path.cells.length,
  );
}

Set<BoardPosition> _endpointPositionsFor(GeneratedNatureLevel generatedLevel) {
  return {
    for (final path in generatedLevel.solutionPaths.values) ...[
      path.cells.first,
      path.cells.last,
    ],
  };
}

String _levelSignature(List<GeneratedNatureLevel> generatedLevels) {
  return generatedLevels
      .expand((generatedLevel) => generatedLevel.level.pairs)
      .map(
        (pair) =>
            '${pair.relationship.id}:'
            '${pair.sourcePosition.row},${pair.sourcePosition.column}>'
            '${pair.targetPosition.row},${pair.targetPosition.column}',
      )
      .join('|');
}

void _completeGeneratedLevel(
  GameController controller,
  GeneratedNatureLevel generatedLevel,
) {
  for (final path in generatedLevel.solutionPaths.values) {
    _completeGamePath(controller, path);
  }
}

void _completeGamePath(GameController controller, GamePath path) {
  _completePath(controller, path.cells);
}

void _completePath(GameController controller, List<BoardPosition> cells) {
  expect(cells.length, greaterThanOrEqualTo(GameConstants.minimumCellsPerPath));
  expect(controller.startPath(cells.first), isTrue);
  for (final position in cells.skip(1)) {
    expect(controller.extendPath(position), isTrue);
  }
  expect(controller.finishPath(), isTrue);
}

bool _areAdjacent(BoardPosition first, BoardPosition second) {
  return (first.row - second.row).abs() +
          (first.column - second.column).abs() ==
      1;
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

  return GameConstants.boardRows * GameConstants.boardColumns + 1;
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

BoardPosition _firstNonEndpoint(GameController controller) {
  for (var row = 0; row < controller.level.rows; row += 1) {
    for (var column = 0; column < controller.level.columns; column += 1) {
      final position = BoardPosition(row: row, column: column);
      if (!controller.isEndpoint(position)) {
        return position;
      }
    }
  }
  throw StateError('Generated test level has no non-endpoint cells.');
}

BoardPosition _diagonalFrom(BoardPosition position, GameLevel level) {
  final candidates = [
    BoardPosition(row: position.row + 1, column: position.column + 1),
    BoardPosition(row: position.row + 1, column: position.column - 1),
    BoardPosition(row: position.row - 1, column: position.column + 1),
    BoardPosition(row: position.row - 1, column: position.column - 1),
  ];

  return candidates.firstWhere(
    (candidate) =>
        candidate.row >= 0 &&
        candidate.row < level.rows &&
        candidate.column >= 0 &&
        candidate.column < level.columns,
  );
}
