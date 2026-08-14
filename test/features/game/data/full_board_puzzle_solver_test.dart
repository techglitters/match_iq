import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:match_iq/features/game/data/full_board_puzzle_solver.dart';
import 'package:match_iq/features/game/data/puzzle_generator.dart';
import 'package:match_iq/features/game/data/puzzle_signature.dart';
import 'package:match_iq/features/game/domain/models/board_position.dart';
import 'package:match_iq/features/game/domain/models/generated_puzzle.dart';

void main() {
  group('FullBoardPuzzleSolver', () {
    test('finds a complete solution using endpoints only', () {
      final puzzle = generatePuzzle(
        rows: 5,
        columns: 5,
        pairCount: 4,
        seed: 2741,
      );
      const solver = FullBoardPuzzleSolver(defaultMaxSearchStates: 50000);

      final result = solver.solve(puzzle, maxSearchStates: 50000);

      expect(result.hasSolution, isTrue);
      expect(result.exploredStates, lessThanOrEqualTo(50001));
    });

    test('does not claim uniqueness when its budget is exhausted', () {
      final puzzle = generatePuzzle(
        rows: 6,
        columns: 6,
        pairCount: 5,
        seed: 90210,
      );
      const solver = FullBoardPuzzleSolver(defaultMaxSearchStates: 1);

      final result = solver.solve(puzzle, solutionLimit: 2, maxSearchStates: 1);

      expect(result.isProvenUnique, isFalse);
      expect(result.searchExhausted, isFalse);
    });

    test('detects an endpoint-complete routing that leaves cells unused', () {
      final puzzle = _puzzleFromPaths(
        rows: 3,
        columns: 3,
        paths: const [
          GeneratedPuzzlePath(
            id: 0,
            cells: [
              BoardPosition(row: 0, column: 0),
              BoardPosition(row: 1, column: 0),
              BoardPosition(row: 2, column: 0),
              BoardPosition(row: 2, column: 1),
              BoardPosition(row: 2, column: 2),
            ],
          ),
          GeneratedPuzzlePath(
            id: 1,
            cells: [
              BoardPosition(row: 0, column: 1),
              BoardPosition(row: 1, column: 1),
              BoardPosition(row: 1, column: 2),
              BoardPosition(row: 0, column: 2),
            ],
          ),
        ],
      );
      const solver = FullBoardPuzzleSolver(defaultMaxSearchStates: 5000);

      final analysis = solver.analyzeCoverage(puzzle);

      expect(analysis.hasFullCoverageSolution, isTrue);
      expect(analysis.hasIncompleteCompletion, isTrue);
      expect(analysis.minimumCoveredCellCount, lessThan(9));
    });

    test('proves a fixture where every completion must fill the board', () {
      final puzzle = _puzzleFromPaths(
        rows: 2,
        columns: 2,
        paths: const [
          GeneratedPuzzlePath(
            id: 0,
            cells: [
              BoardPosition(row: 0, column: 0),
              BoardPosition(row: 0, column: 1),
            ],
          ),
          GeneratedPuzzlePath(
            id: 1,
            cells: [
              BoardPosition(row: 1, column: 0),
              BoardPosition(row: 1, column: 1),
            ],
          ),
        ],
      );
      const solver = FullBoardPuzzleSolver(defaultMaxSearchStates: 5000);

      final analysis = solver.analyzeCoverage(puzzle);

      expect(analysis.hasFullCoverageSolution, isTrue);
      expect(analysis.hasIncompleteCompletion, isFalse);
      expect(analysis.minimumCoveredCellCount, 4);
      expect(analysis.searchExhausted, isTrue);
    });

    test('reports an exhausted budget as inconclusive', () {
      final puzzle = generatePuzzle(
        rows: 5,
        columns: 5,
        pairCount: 3,
        seed: 77,
      );
      const solver = FullBoardPuzzleSolver(defaultMaxSearchStates: 1);

      final analysis = solver.analyzeCoverage(puzzle);

      expect(analysis.searchExhausted, isFalse);
      expect(analysis.isInconclusive, isTrue);
    });
  });
}

GeneratedPuzzle _puzzleFromPaths({
  required int rows,
  required int columns,
  required List<GeneratedPuzzlePath> paths,
}) {
  const signatures = PuzzleSignatureGenerator();
  return GeneratedPuzzle(
    rows: rows,
    columns: columns,
    seed: 1,
    paths: paths,
    signature: signatures.fromPaths(rows: rows, columns: columns, paths: paths),
    metrics: PuzzleDifficultyMetrics(
      pairCount: paths.length,
      averagePathLength:
          paths.fold<int>(0, (sum, path) => sum + path.cells.length) /
          paths.length,
      totalTurns: 0,
      averageTurnsPerPath: 0,
      longestPath: paths.map((path) => path.cells.length).reduce(math.max),
      shortestPath: paths.map((path) => path.cells.length).reduce(math.min),
    ),
    generationAttempts: 1,
    backtracks: 0,
    usedFallback: false,
  );
}
