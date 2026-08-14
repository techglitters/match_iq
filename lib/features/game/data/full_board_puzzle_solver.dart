import 'dart:math' as math;

import '../domain/models/board_position.dart';
import '../domain/models/generated_puzzle.dart';
import 'puzzle_generator.dart';

class FullBoardSolveResult {
  const FullBoardSolveResult({
    required this.solutionCount,
    required this.searchExhausted,
    required this.exploredStates,
  });

  final int solutionCount;
  final bool searchExhausted;
  final int exploredStates;

  bool get hasSolution => solutionCount > 0;
  bool get isProvenUnique => solutionCount == 1 && searchExhausted;
}

/// Bounded endpoint-only solver for full-coverage Flow-style puzzles.
///
/// The stored paths are used only to order equivalent neighbor choices so the
/// known witness is found quickly. Legality, connectivity, and completion are
/// evaluated solely from the board dimensions and endpoint pairs.
class FullBoardPuzzleSolver
    implements PuzzleUniquenessSolver, PuzzleCoverageSolver {
  const FullBoardPuzzleSolver({this.defaultMaxSearchStates = 50000});

  final int defaultMaxSearchStates;

  @override
  PuzzleCoverageAnalysis analyzeCoverage(
    GeneratedPuzzle puzzle, {
    int? maxSearchStates,
  }) {
    final stateLimit = maxSearchStates ?? defaultMaxSearchStates;
    final endpointOwner = <BoardPosition, int>{};
    for (final path in puzzle.paths) {
      endpointOwner[path.first] = path.id;
      endpointOwner[path.last] = path.id;
    }
    final totalCells = puzzle.rows * puzzle.columns;
    final knownCells = puzzle.paths.expand((path) => path.cells).toSet();
    final hasFullCoverageSolution = knownCells.length == totalCells;
    final orderedPairs = [...puzzle.endpoints]
      ..sort((first, second) {
        final distanceOrder = _distance(
          first.first,
          first.second,
        ).compareTo(_distance(second.first, second.second));
        return distanceOrder != 0
            ? distanceOrder
            : first.pathId.compareTo(second.pathId);
      });
    final occupied = <BoardPosition>{...endpointOwner.keys};
    final minimumPossibleCoverage = _minimumEndpointCompletionCoverage(
      orderedPairs,
      endpointOwner: endpointOwner,
      rows: puzzle.rows,
      columns: puzzle.columns,
    );
    if (hasFullCoverageSolution && minimumPossibleCoverage >= totalCells) {
      return PuzzleCoverageAnalysis(
        hasFullCoverageSolution: true,
        hasIncompleteCompletion: false,
        minimumCoveredCellCount: totalCells,
        exploredStates: 0,
        searchExhausted: true,
      );
    }
    var exploredStates = 0;
    var budgetExceeded = false;
    var hasIncompleteCompletion = false;
    var minimumCoveredCellCount = hasFullCoverageSolution
        ? totalCells
        : knownCells.length;

    bool spendState() {
      exploredStates += 1;
      if (exploredStates > stateLimit) {
        budgetExceeded = true;
        return false;
      }
      return true;
    }

    int remainingMinimumInternalCells(int nextPairIndex) {
      var minimum = 0;
      for (var index = nextPairIndex; index < orderedPairs.length; index += 1) {
        minimum += math.max(
          0,
          _distance(orderedPairs[index].first, orderedPairs[index].second) - 1,
        );
      }
      return minimum;
    }

    void connectPair(int pairIndex) {
      if (budgetExceeded || hasIncompleteCompletion || !spendState()) {
        return;
      }
      if (pairIndex == orderedPairs.length) {
        minimumCoveredCellCount = math.min(
          minimumCoveredCellCount,
          occupied.length,
        );
        if (occupied.length < totalCells) {
          hasIncompleteCompletion = true;
        }
        return;
      }

      final pair = orderedPairs[pairIndex];
      final route = <BoardPosition>[pair.first];
      final routeCells = <BoardPosition>{pair.first};

      void extend(BoardPosition current) {
        if (budgetExceeded || hasIncompleteCompletion || !spendState()) {
          return;
        }
        final routeInternalCellCount = route
            .where((cell) => !endpointOwner.containsKey(cell))
            .length;
        if (occupied.length +
                routeInternalCellCount +
                remainingMinimumInternalCells(pairIndex + 1) >=
            totalCells) {
          return;
        }

        if (current == pair.second) {
          final addedCells = <BoardPosition>[];
          for (final cell in route.skip(1).take(route.length - 2)) {
            if (occupied.add(cell)) {
              addedCells.add(cell);
            }
          }
          if (_remainingPairsAreReachable(
            orderedPairs,
            nextPairIndex: pairIndex + 1,
            occupied: occupied,
            endpointOwner: endpointOwner,
            rows: puzzle.rows,
            columns: puzzle.columns,
          )) {
            connectPair(pairIndex + 1);
          }
          occupied.removeAll(addedCells);
          return;
        }

        final candidates =
            _neighbors(
                current,
                rows: puzzle.rows,
                columns: puzzle.columns,
              ).where((next) {
                if (next == pair.second) {
                  return true;
                }
                return !occupied.contains(next) &&
                    !routeCells.contains(next) &&
                    !endpointOwner.containsKey(next);
              }).toList()
              ..sort((first, second) {
                final distanceOrder = _distance(
                  first,
                  pair.second,
                ).compareTo(_distance(second, pair.second));
                if (distanceOrder != 0) {
                  return distanceOrder;
                }
                final firstOptions = _availableNeighborCount(
                  first,
                  occupied: occupied,
                  routeCells: routeCells,
                  endpointOwner: endpointOwner,
                  ownPathId: pair.pathId,
                  rows: puzzle.rows,
                  columns: puzzle.columns,
                );
                final secondOptions = _availableNeighborCount(
                  second,
                  occupied: occupied,
                  routeCells: routeCells,
                  endpointOwner: endpointOwner,
                  ownPathId: pair.pathId,
                  rows: puzzle.rows,
                  columns: puzzle.columns,
                );
                return firstOptions.compareTo(secondOptions);
              });

        for (final next in candidates) {
          route.add(next);
          routeCells.add(next);
          if (_canReach(
            next,
            pair.second,
            occupied: occupied,
            routeCells: routeCells,
            endpointOwner: endpointOwner,
            ownPathId: pair.pathId,
            rows: puzzle.rows,
            columns: puzzle.columns,
          )) {
            extend(next);
          }
          routeCells.remove(next);
          route.removeLast();
          if (budgetExceeded || hasIncompleteCompletion) {
            return;
          }
        }
      }

      extend(pair.first);
    }

    if (hasFullCoverageSolution) {
      connectPair(0);
    }
    return PuzzleCoverageAnalysis(
      hasFullCoverageSolution: hasFullCoverageSolution,
      hasIncompleteCompletion: hasIncompleteCompletion,
      minimumCoveredCellCount: minimumCoveredCellCount,
      exploredStates: exploredStates,
      searchExhausted:
          hasFullCoverageSolution &&
          !budgetExceeded &&
          !hasIncompleteCompletion,
    );
  }

  FullBoardSolveResult solve(
    GeneratedPuzzle puzzle, {
    int solutionLimit = 1,
    int? maxSearchStates,
  }) {
    final stateLimit = maxSearchStates ?? defaultMaxSearchStates;
    final endpoints = puzzle.endpoints;
    final endpointOwner = <BoardPosition, int>{};
    final preferredNext = <int, Map<BoardPosition, BoardPosition>>{};
    for (final path in puzzle.paths) {
      for (final endpoint in [path.first, path.last]) {
        endpointOwner[endpoint] = path.id;
      }
      preferredNext[path.id] = {
        for (var index = 0; index + 1 < path.cells.length; index += 1)
          path.cells[index]: path.cells[index + 1],
      };
    }

    // A fixed most-constrained-first order avoids counting the same complete
    // solution once for every possible pair-solving order.
    final orderedPairs = [...endpoints]
      ..sort((first, second) {
        final firstDistance = _distance(first.first, first.second);
        final secondDistance = _distance(second.first, second.second);
        final distanceOrder = secondDistance.compareTo(firstDistance);
        return distanceOrder != 0
            ? distanceOrder
            : first.pathId.compareTo(second.pathId);
      });
    final occupied = <BoardPosition>{...endpointOwner.keys};
    var exploredStates = 0;
    var solutionCount = 0;
    var budgetExceeded = false;

    bool spendState() {
      exploredStates += 1;
      if (exploredStates > stateLimit) {
        budgetExceeded = true;
        return false;
      }
      return true;
    }

    void solvePair(int pairIndex) {
      if (budgetExceeded || solutionCount >= solutionLimit || !spendState()) {
        return;
      }
      if (pairIndex == orderedPairs.length) {
        if (occupied.length == puzzle.rows * puzzle.columns) {
          solutionCount += 1;
        }
        return;
      }

      final pair = orderedPairs[pairIndex];
      final route = <BoardPosition>[pair.first];
      final routeCells = <BoardPosition>{pair.first};

      void extend(BoardPosition current) {
        if (budgetExceeded || solutionCount >= solutionLimit || !spendState()) {
          return;
        }
        if (current == pair.second) {
          final addedCells = <BoardPosition>[];
          for (final cell in route.skip(1).take(route.length - 2)) {
            if (occupied.add(cell)) {
              addedCells.add(cell);
            }
          }
          if (_remainingPairsAreViable(
            orderedPairs,
            nextPairIndex: pairIndex + 1,
            occupied: occupied,
            endpointOwner: endpointOwner,
            rows: puzzle.rows,
            columns: puzzle.columns,
          )) {
            solvePair(pairIndex + 1);
          }
          occupied.removeAll(addedCells);
          return;
        }

        final candidates =
            _neighbors(
              current,
              rows: puzzle.rows,
              columns: puzzle.columns,
            ).where((next) {
              if (next == pair.second) {
                return true;
              }
              return !occupied.contains(next) &&
                  !routeCells.contains(next) &&
                  !endpointOwner.containsKey(next);
            }).toList();
        final preferred = preferredNext[pair.pathId]?[current];
        candidates.sort((first, second) {
          if (first == preferred) return -1;
          if (second == preferred) return 1;
          final firstDistance = _distance(first, pair.second);
          final secondDistance = _distance(second, pair.second);
          return firstDistance.compareTo(secondDistance);
        });

        for (final next in candidates) {
          route.add(next);
          routeCells.add(next);
          if (_canReach(
            next,
            pair.second,
            occupied: occupied,
            routeCells: routeCells,
            endpointOwner: endpointOwner,
            ownPathId: pair.pathId,
            rows: puzzle.rows,
            columns: puzzle.columns,
          )) {
            extend(next);
          }
          routeCells.remove(next);
          route.removeLast();
          if (budgetExceeded || solutionCount >= solutionLimit) {
            return;
          }
        }
      }

      extend(pair.first);
    }

    solvePair(0);
    return FullBoardSolveResult(
      solutionCount: solutionCount,
      searchExhausted: !budgetExceeded && solutionCount < solutionLimit,
      exploredStates: exploredStates,
    );
  }

  @override
  int countSolutions(GeneratedPuzzle puzzle, {int limit = 2}) {
    final result = solve(puzzle, solutionLimit: limit);
    if (!result.searchExhausted && result.solutionCount == 1 && limit > 1) {
      // Conservatively treat an unexhausted uniqueness search as non-unique.
      return 2;
    }
    return result.solutionCount;
  }

  bool _remainingPairsAreViable(
    List<GeneratedPuzzleEndpointPair> pairs, {
    required int nextPairIndex,
    required Set<BoardPosition> occupied,
    required Map<BoardPosition, int> endpointOwner,
    required int rows,
    required int columns,
  }) {
    for (var index = nextPairIndex; index < pairs.length; index += 1) {
      final pair = pairs[index];
      if (!_canReach(
        pair.first,
        pair.second,
        occupied: occupied,
        routeCells: const {},
        endpointOwner: endpointOwner,
        ownPathId: pair.pathId,
        rows: rows,
        columns: columns,
      )) {
        return false;
      }
    }

    final freeCells = <BoardPosition>{
      for (var row = 0; row < rows; row += 1)
        for (var column = 0; column < columns; column += 1)
          if (!occupied.contains(BoardPosition(row: row, column: column)) &&
              !endpointOwner.containsKey(
                BoardPosition(row: row, column: column),
              ))
            BoardPosition(row: row, column: column),
    };
    while (freeCells.isNotEmpty) {
      final component = <BoardPosition>{freeCells.first};
      final queue = <BoardPosition>[freeCells.first];
      freeCells.remove(freeCells.first);
      var cursor = 0;
      while (cursor < queue.length) {
        final current = queue[cursor++];
        for (final next in _neighbors(current, rows: rows, columns: columns)) {
          if (freeCells.remove(next)) {
            component.add(next);
            queue.add(next);
          }
        }
      }
      final touchesRemainingEndpoint = component.any((cell) {
        return _neighbors(cell, rows: rows, columns: columns).any((neighbor) {
          final owner = endpointOwner[neighbor];
          return owner != null &&
              pairs.skip(nextPairIndex).any((pair) => pair.pathId == owner);
        });
      });
      if (!touchesRemainingEndpoint) {
        return false;
      }
    }
    return true;
  }

  bool _remainingPairsAreReachable(
    List<GeneratedPuzzleEndpointPair> pairs, {
    required int nextPairIndex,
    required Set<BoardPosition> occupied,
    required Map<BoardPosition, int> endpointOwner,
    required int rows,
    required int columns,
  }) {
    for (var index = nextPairIndex; index < pairs.length; index += 1) {
      final pair = pairs[index];
      if (!_canReach(
        pair.first,
        pair.second,
        occupied: occupied,
        routeCells: const {},
        endpointOwner: endpointOwner,
        ownPathId: pair.pathId,
        rows: rows,
        columns: columns,
      )) {
        return false;
      }
    }
    return true;
  }

  int _minimumEndpointCompletionCoverage(
    List<GeneratedPuzzleEndpointPair> pairs, {
    required Map<BoardPosition, int> endpointOwner,
    required int rows,
    required int columns,
  }) {
    var total = 0;
    for (final pair in pairs) {
      final distance = _shortestDistance(
        pair.first,
        pair.second,
        endpointOwner: endpointOwner,
        ownPathId: pair.pathId,
        rows: rows,
        columns: columns,
      );
      if (distance == null) {
        return 0;
      }
      total += distance + 1;
    }
    return total;
  }

  int? _shortestDistance(
    BoardPosition start,
    BoardPosition target, {
    required Map<BoardPosition, int> endpointOwner,
    required int ownPathId,
    required int rows,
    required int columns,
  }) {
    final distances = <BoardPosition, int>{start: 0};
    final queue = <BoardPosition>[start];
    var cursor = 0;
    while (cursor < queue.length) {
      final current = queue[cursor++];
      if (current == target) {
        return distances[current];
      }
      for (final next in _neighbors(current, rows: rows, columns: columns)) {
        final endpointPathId = endpointOwner[next];
        if (distances.containsKey(next) ||
            (endpointPathId != null && endpointPathId != ownPathId)) {
          continue;
        }
        distances[next] = distances[current]! + 1;
        queue.add(next);
      }
    }
    return null;
  }

  int _availableNeighborCount(
    BoardPosition position, {
    required Set<BoardPosition> occupied,
    required Set<BoardPosition> routeCells,
    required Map<BoardPosition, int> endpointOwner,
    required int ownPathId,
    required int rows,
    required int columns,
  }) {
    return _neighbors(position, rows: rows, columns: columns).where((next) {
      final endpointPathId = endpointOwner[next];
      return !occupied.contains(next) &&
          !routeCells.contains(next) &&
          (endpointPathId == null || endpointPathId == ownPathId);
    }).length;
  }

  bool _canReach(
    BoardPosition start,
    BoardPosition target, {
    required Set<BoardPosition> occupied,
    required Set<BoardPosition> routeCells,
    required Map<BoardPosition, int> endpointOwner,
    required int ownPathId,
    required int rows,
    required int columns,
  }) {
    final visited = <BoardPosition>{start};
    final queue = <BoardPosition>[start];
    var cursor = 0;
    while (cursor < queue.length) {
      final current = queue[cursor++];
      if (current == target) {
        return true;
      }
      for (final next in _neighbors(current, rows: rows, columns: columns)) {
        final endpointPathId = endpointOwner[next];
        final blockedEndpoint =
            endpointPathId != null && endpointPathId != ownPathId;
        if (!visited.add(next) ||
            blockedEndpoint ||
            (occupied.contains(next) && next != target) ||
            (routeCells.contains(next) && next != start)) {
          continue;
        }
        queue.add(next);
      }
    }
    return false;
  }

  Iterable<BoardPosition> _neighbors(
    BoardPosition position, {
    required int rows,
    required int columns,
  }) sync* {
    const offsets = [(-1, 0), (0, 1), (1, 0), (0, -1)];
    for (final (rowOffset, columnOffset) in offsets) {
      final next = BoardPosition(
        row: position.row + rowOffset,
        column: position.column + columnOffset,
      );
      if (next.row >= 0 &&
          next.row < rows &&
          next.column >= 0 &&
          next.column < columns) {
        yield next;
      }
    }
  }

  int _distance(BoardPosition first, BoardPosition second) {
    return (first.row - second.row).abs() +
        (first.column - second.column).abs();
  }
}
