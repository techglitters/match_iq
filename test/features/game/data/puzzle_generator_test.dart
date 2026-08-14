import 'package:flutter_test/flutter_test.dart';
import 'package:match_iq/features/game/data/puzzle_generator.dart';
import 'package:match_iq/features/game/data/puzzle_signature.dart';
import 'package:match_iq/features/game/data/puzzle_solution_validator.dart';
import 'package:match_iq/features/game/domain/models/board_position.dart';
import 'package:match_iq/features/game/domain/models/generated_puzzle.dart';

void main() {
  group('PuzzleGenerator', () {
    const configurations = [
      (rows: 4, columns: 4, pairs: 3),
      (rows: 5, columns: 5, pairs: 4),
      (rows: 6, columns: 6, pairs: 4),
      (rows: 7, columns: 7, pairs: 5),
      (rows: 8, columns: 8, pairs: 6),
      (rows: 9, columns: 9, pairs: 7),
      (rows: 5, columns: 6, pairs: 4),
      (rows: 6, columns: 8, pairs: 5),
      (rows: 8, columns: 10, pairs: 7),
    ];

    test('generates strict solved-board partitions across supported sizes', () {
      const validator = PuzzleSolutionValidator();

      for (final config in configurations) {
        for (var seed = 0; seed < 12; seed++) {
          final puzzle = generatePuzzle(
            rows: config.rows,
            columns: config.columns,
            pairCount: config.pairs,
            seed: seed,
          );
          final result = validator.validate(
            rows: config.rows,
            columns: config.columns,
            expectedPairCount: config.pairs,
            paths: puzzle.paths,
          );

          expect(result.errors, isEmpty, reason: '$config seed $seed');
          expect(
            puzzle.paths.expand((path) => path.cells).toSet(),
            hasLength(config.rows * config.columns),
          );
          expect(puzzle.endpoints, hasLength(config.pairs));
          expect(puzzle.paths.every((path) => path.cells.length >= 3), isTrue);
        }
      }
    });

    test('same configuration and seed reproduce exactly', () {
      final first = generatePuzzle(
        rows: 6,
        columns: 6,
        pairCount: 4,
        seed: 18273423,
      );
      final second = generatePuzzle(
        rows: 6,
        columns: 6,
        pairCount: 4,
        seed: 18273423,
      );

      expect(second.signature, first.signature);
      expect(
        second.paths.map((path) => path.cells).toList(),
        first.paths.map((path) => path.cells).toList(),
      );
    });

    test('different seeds usually produce different endpoint geometry', () {
      final signatures = {
        for (var seed = 0; seed < 30; seed++)
          generatePuzzle(
            rows: 6,
            columns: 6,
            pairCount: 4,
            seed: seed,
          ).signature,
      };

      expect(signatures.length, greaterThanOrEqualTo(24));
    });

    test('signature ignores path IDs and endpoint direction', () {
      const signatureGenerator = PuzzleSignatureGenerator();
      const first = GeneratedPuzzlePath(
        id: 4,
        cells: [
          BoardPosition(row: 0, column: 0),
          BoardPosition(row: 0, column: 1),
        ],
      );
      const second = GeneratedPuzzlePath(
        id: 9,
        cells: [
          BoardPosition(row: 1, column: 1),
          BoardPosition(row: 1, column: 0),
        ],
      );

      final normal = signatureGenerator.fromPaths(
        rows: 2,
        columns: 2,
        paths: const [first, second],
      );
      final reordered = signatureGenerator.fromPaths(
        rows: 2,
        columns: 2,
        paths: const [
          GeneratedPuzzlePath(
            id: 1,
            cells: [
              BoardPosition(row: 1, column: 0),
              BoardPosition(row: 1, column: 1),
            ],
          ),
          GeneratedPuzzlePath(
            id: 0,
            cells: [
              BoardPosition(row: 0, column: 1),
              BoardPosition(row: 0, column: 0),
            ],
          ),
        ],
      );

      expect(reordered, normal);
    });

    test('recent signature history rejects a duplicate and regenerates', () {
      final history = PuzzleSignatureHistory(capacity: 20);
      final generator = PuzzleGenerator(signatureHistory: history);
      final first = generator.generate(
        const PuzzleGenerationConfig(
          rows: 6,
          columns: 6,
          pairCount: 4,
          seed: 42,
        ),
      );
      final second = generator.generate(
        const PuzzleGenerationConfig(
          rows: 6,
          columns: 6,
          pairCount: 4,
          seed: 42,
        ),
      );

      expect(second.signature, isNot(first.signature));
      expect(history.values, containsAll([first.signature, second.signature]));
    });

    test(
      'strict validator rejects overlap, gaps, and non-orthogonal steps',
      () {
        const validator = PuzzleSolutionValidator();
        const malformed = [
          GeneratedPuzzlePath(
            id: 0,
            cells: [
              BoardPosition(row: 0, column: 0),
              BoardPosition(row: 1, column: 1),
            ],
          ),
          GeneratedPuzzlePath(
            id: 1,
            cells: [
              BoardPosition(row: 1, column: 1),
              BoardPosition(row: 1, column: 0),
            ],
          ),
        ];

        final result = validator.validate(
          rows: 2,
          columns: 2,
          expectedPairCount: 2,
          paths: malformed,
        );

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
      },
    );

    test('strict validator accepts 25/25 cells and rejects 24/25', () {
      const validator = PuzzleSolutionValidator();
      final complete = generatePuzzle(
        rows: 5,
        columns: 5,
        pairCount: 3,
        seed: 145,
      );
      final incompletePaths = [
        ...complete.paths.take(complete.paths.length - 1),
        GeneratedPuzzlePath(
          id: complete.paths.last.id,
          cells: complete.paths.last.cells.sublist(
            0,
            complete.paths.last.cells.length - 1,
          ),
        ),
      ];

      expect(
        validator
            .validate(
              rows: 5,
              columns: 5,
              expectedPairCount: 3,
              paths: complete.paths,
            )
            .isValid,
        isTrue,
      );
      expect(
        validator
            .validate(
              rows: 5,
              columns: 5,
              expectedPairCount: 3,
              paths: incompletePaths,
            )
            .isValid,
        isFalse,
      );
    });

    test('coverage rejection policy is configurable', () {
      final generator = PuzzleGenerator(
        coverageSolver: const _FixedCoverageSolver(
          PuzzleCoverageAnalysis(
            hasFullCoverageSolution: true,
            hasIncompleteCompletion: false,
            minimumCoveredCellCount: 25,
            exploredStates: 10,
            searchExhausted: false,
          ),
        ),
      );

      expect(
        () => generator.generate(
          const PuzzleGenerationConfig(
            rows: 5,
            columns: 5,
            pairCount: 3,
            seed: 7,
            rejectIncompleteCompletions: true,
            rejectWhenCoverageSearchIsInconclusive: true,
          ),
        ),
        throwsStateError,
      );
      expect(
        generator.generate(
          const PuzzleGenerationConfig(
            rows: 5,
            columns: 5,
            pairCount: 3,
            seed: 7,
            rejectIncompleteCompletions: true,
          ),
        ),
        isA<GeneratedPuzzle>(),
      );
    });

    test(
      'uniqueness is optional and uses the injected bounded solver port',
      () {
        final generator = PuzzleGenerator(
          uniquenessSolver: const _FixedSolutionCountSolver(1),
        );
        final puzzle = generator.generate(
          const PuzzleGenerationConfig(
            rows: 5,
            columns: 5,
            pairCount: 4,
            seed: 7,
            requireUniqueSolution: true,
          ),
        );

        expect(puzzle.uniquenessStatus, PuzzleUniquenessStatus.unique);
      },
    );

    test('requiring uniqueness without a solver fails clearly', () {
      expect(
        () => generatePuzzle(
          rows: 5,
          columns: 5,
          pairCount: 4,
          seed: 7,
          requireUniqueSolution: true,
        ),
        throwsStateError,
      );
    });
  });
}

class _FixedSolutionCountSolver implements PuzzleUniquenessSolver {
  const _FixedSolutionCountSolver(this.count);

  final int count;

  @override
  int countSolutions(GeneratedPuzzle puzzle, {int limit = 2}) => count;
}

class _FixedCoverageSolver implements PuzzleCoverageSolver {
  const _FixedCoverageSolver(this.analysis);

  final PuzzleCoverageAnalysis analysis;

  @override
  PuzzleCoverageAnalysis analyzeCoverage(
    GeneratedPuzzle puzzle, {
    int? maxSearchStates,
  }) => analysis;
}
