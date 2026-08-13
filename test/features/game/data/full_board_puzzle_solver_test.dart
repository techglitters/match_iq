import 'package:flutter_test/flutter_test.dart';
import 'package:match_iq/features/game/data/full_board_puzzle_solver.dart';
import 'package:match_iq/features/game/data/puzzle_generator.dart';

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
  });
}
