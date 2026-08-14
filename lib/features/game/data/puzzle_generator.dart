import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../domain/models/board_position.dart';
import '../domain/models/generated_puzzle.dart';
import 'puzzle_signature.dart';
import 'puzzle_solution_validator.dart';

/// Generates the hidden solved board first and derives endpoints afterward.
///
/// The previous themed generator also began with a full traversal, so it was
/// solvable by construction and stored its solution. However, its validation
/// accepted partial coverage, its seed was implicit, and Nature could bypass
/// the general generator through dimension-specific layouts. This reusable
/// generator makes exact coverage a validated invariant, stores its seed, and
/// supports arbitrary rectangular dimensions and configured pair counts.
class PuzzleGenerationConfig {
  const PuzzleGenerationConfig({
    required this.rows,
    required this.columns,
    required this.pairCount,
    this.seed,
    this.minPathLength = 3,
    this.maxGenerationAttempts = 8,
    this.maxBacktrackSteps = 5000,
    this.requireUniqueSolution = false,
    this.rejectIncompleteCompletions = false,
    this.rejectWhenCoverageSearchIsInconclusive = false,
    this.coverageSearchMaxStates = 50000,
    this.debugLogging = false,
  });

  final int rows;
  final int columns;
  final int pairCount;
  final int? seed;
  final int minPathLength;
  final int maxGenerationAttempts;
  final int maxBacktrackSteps;
  final bool requireUniqueSolution;
  final bool rejectIncompleteCompletions;
  final bool rejectWhenCoverageSearchIsInconclusive;
  final int coverageSearchMaxStates;
  final bool debugLogging;
}

class PuzzleCoverageAnalysis {
  const PuzzleCoverageAnalysis({
    required this.hasFullCoverageSolution,
    required this.hasIncompleteCompletion,
    required this.minimumCoveredCellCount,
    required this.exploredStates,
    required this.searchExhausted,
  });

  final bool hasFullCoverageSolution;

  /// Whether every endpoint pair can be connected legally while leaving at
  /// least one board cell unused.
  final bool hasIncompleteCompletion;
  final int minimumCoveredCellCount;
  final int exploredStates;

  /// True only when the bounded search explored the complete search space.
  /// A found counterexample is conclusive even though this remains false.
  final bool searchExhausted;

  bool get isInconclusive => !hasIncompleteCompletion && !searchExhausted;
}

abstract interface class PuzzleCoverageSolver {
  PuzzleCoverageAnalysis analyzeCoverage(
    GeneratedPuzzle puzzle, {
    int? maxSearchStates,
  });
}

abstract interface class PuzzleUniquenessSolver {
  /// Returns 0 for no solution, 1 for unique, and 2 once multiple solutions
  /// are found. Implementations may stop counting after the second solution.
  int countSolutions(GeneratedPuzzle puzzle, {int limit = 2});
}

class PuzzleGenerator {
  PuzzleGenerator({
    PuzzleSolutionValidator validator = const PuzzleSolutionValidator(),
    PuzzleSignatureGenerator signatureGenerator =
        const PuzzleSignatureGenerator(),
    this.signatureHistory,
    this.uniquenessSolver,
    this.coverageSolver,
  }) : _validator = validator,
       _signatureGenerator = signatureGenerator;

  final PuzzleSolutionValidator _validator;
  final PuzzleSignatureGenerator _signatureGenerator;
  final PuzzleSignatureHistory? signatureHistory;
  final PuzzleUniquenessSolver? uniquenessSolver;
  final PuzzleCoverageSolver? coverageSolver;

  GeneratedPuzzle generate(PuzzleGenerationConfig config) {
    _validateConfig(config);
    if (config.requireUniqueSolution && uniquenessSolver == null) {
      throw StateError(
        'requireUniqueSolution needs a PuzzleUniquenessSolver. The current '
        'app has no exact solver, so uniqueness is opt-in through this port.',
      );
    }
    if (config.rejectIncompleteCompletions && coverageSolver == null) {
      throw StateError(
        'rejectIncompleteCompletions needs a PuzzleCoverageSolver.',
      );
    }

    final seed = config.seed ?? _newSeed();
    var totalBacktracks = 0;
    for (var attempt = 0; attempt < config.maxGenerationAttempts; attempt++) {
      final attemptSeed = _mixSeed(seed, attempt);
      final random = math.Random(attemptSeed);
      final growth = _growHamiltonianTraversal(
        rows: config.rows,
        columns: config.columns,
        random: random,
        maxBacktrackSteps: config.maxBacktrackSteps,
      );
      totalBacktracks += growth.backtracks;
      if (growth.cells == null) {
        continue;
      }

      final paths = _partitionTraversal(
        growth.cells!,
        pairCount: config.pairCount,
        minPathLength: config.minPathLength,
        random: random,
      );
      final accepted = _acceptCandidate(
        config: config,
        seed: seed,
        paths: paths,
        generationAttempts: attempt + 1,
        backtracks: totalBacktracks,
        usedFallback: false,
      );
      if (accepted != null) {
        return accepted;
      }
    }

    // The fallback still starts from a complete solved board. It is varied by
    // seed, orientation, traversal family, cut lengths, and path ordering, but
    // is intentionally simpler than the randomized backtracking production
    // generator so generation always has a bounded completion path.
    for (var fallbackIndex = 0; fallbackIndex < 16; fallbackIndex++) {
      final random = math.Random(_mixSeed(seed, 1000 + fallbackIndex));
      final traversal = _fallbackTraversal(
        rows: config.rows,
        columns: config.columns,
        random: random,
      );
      final paths = _partitionTraversal(
        traversal,
        pairCount: config.pairCount,
        minPathLength: config.minPathLength,
        random: random,
      );
      final accepted = _acceptCandidate(
        config: config,
        seed: seed,
        paths: paths,
        generationAttempts: config.maxGenerationAttempts + fallbackIndex + 1,
        backtracks: totalBacktracks,
        usedFallback: true,
      );
      if (accepted != null) {
        return accepted;
      }
    }

    throw StateError(
      'Unable to generate a non-duplicate valid ${config.rows}x'
      '${config.columns} puzzle after bounded randomized and fallback attempts.',
    );
  }

  GeneratedPuzzle? _acceptCandidate({
    required PuzzleGenerationConfig config,
    required int seed,
    required List<GeneratedPuzzlePath> paths,
    required int generationAttempts,
    required int backtracks,
    required bool usedFallback,
  }) {
    final validation = _validator.validate(
      rows: config.rows,
      columns: config.columns,
      expectedPairCount: config.pairCount,
      paths: paths,
    );
    if (!validation.isValid) {
      return null;
    }
    final signature = _signatureGenerator.fromPaths(
      rows: config.rows,
      columns: config.columns,
      paths: paths,
    );
    if (signatureHistory?.contains(signature) ?? false) {
      return null;
    }

    var puzzle = GeneratedPuzzle(
      rows: config.rows,
      columns: config.columns,
      seed: seed,
      paths: List<GeneratedPuzzlePath>.unmodifiable(paths),
      signature: signature,
      metrics: _difficultyMetrics(paths),
      generationAttempts: generationAttempts,
      backtracks: backtracks,
      usedFallback: usedFallback,
    );
    PuzzleCoverageAnalysis? coverageAnalysis;
    if (config.rejectIncompleteCompletions) {
      coverageAnalysis = coverageSolver!.analyzeCoverage(
        puzzle,
        maxSearchStates: config.coverageSearchMaxStates,
      );
      final rejectionReason = !coverageAnalysis.hasFullCoverageSolution
          ? 'known solution does not cover the full board'
          : coverageAnalysis.hasIncompleteCompletion
          ? 'endpoint layout allows partial-board completion'
          : coverageAnalysis.isInconclusive &&
                config.rejectWhenCoverageSearchIsInconclusive
          ? 'coverage search was inconclusive'
          : null;
      if (rejectionReason != null) {
        if (config.debugLogging) {
          _debugLogRejection(
            config: config,
            seed: seed,
            paths: paths,
            generationAttempts: generationAttempts,
            backtracks: backtracks,
            analysis: coverageAnalysis,
            reason: rejectionReason,
          );
        }
        return null;
      }
    }
    final solver = uniquenessSolver;
    if (solver != null) {
      final solutionCount = solver.countSolutions(puzzle, limit: 2);
      final status = solutionCount == 0
          ? PuzzleUniquenessStatus.unsolvable
          : solutionCount == 1
          ? PuzzleUniquenessStatus.unique
          : PuzzleUniquenessStatus.multiple;
      puzzle = puzzle.copyWith(uniquenessStatus: status);
      if (solutionCount == 0 ||
          (config.requireUniqueSolution && solutionCount != 1)) {
        return null;
      }
    }

    signatureHistory?.add(signature);
    if (config.debugLogging) {
      _debugLog(puzzle, valid: true, coverageAnalysis: coverageAnalysis);
    }
    return puzzle;
  }

  _TraversalGrowth _growHamiltonianTraversal({
    required int rows,
    required int columns,
    required math.Random random,
    required int maxBacktrackSteps,
  }) {
    final totalCells = rows * columns;
    final start = BoardPosition(
      row: random.nextInt(rows),
      column: random.nextInt(columns),
    );
    final path = <BoardPosition>[start];
    final used = <BoardPosition>{start};
    var backtracks = 0;

    bool search() {
      if (path.length == totalCells) {
        return true;
      }
      if (backtracks >= maxBacktrackSteps) {
        return false;
      }

      final candidates =
          _neighbors(path.last, rows: rows, columns: columns)
              .where((candidate) => !used.contains(candidate))
              .map(
                (candidate) => (
                  cell: candidate,
                  onward: _neighbors(
                    candidate,
                    rows: rows,
                    columns: columns,
                  ).where((next) => !used.contains(next)).length,
                  tieBreaker: random.nextDouble(),
                ),
              )
              .toList()
            ..sort((first, second) {
              final degreeOrder = first.onward.compareTo(second.onward);
              return degreeOrder != 0
                  ? degreeOrder
                  : first.tieBreaker.compareTo(second.tieBreaker);
            });

      for (final candidate in candidates) {
        path.add(candidate.cell);
        used.add(candidate.cell);
        if (_remainingCellsAreViable(
              currentEnd: candidate.cell,
              used: used,
              rows: rows,
              columns: columns,
            ) &&
            search()) {
          return true;
        }
        used.remove(candidate.cell);
        path.removeLast();
        backtracks++;
        if (backtracks >= maxBacktrackSteps) {
          break;
        }
      }
      return false;
    }

    final solved = search();
    return _TraversalGrowth(
      cells: solved ? List<BoardPosition>.unmodifiable(path) : null,
      backtracks: backtracks,
    );
  }

  bool _remainingCellsAreViable({
    required BoardPosition currentEnd,
    required Set<BoardPosition> used,
    required int rows,
    required int columns,
  }) {
    final remaining = <BoardPosition>{
      for (var row = 0; row < rows; row++)
        for (var column = 0; column < columns; column++)
          if (!used.contains(BoardPosition(row: row, column: column)))
            BoardPosition(row: row, column: column),
    };
    if (remaining.isEmpty) {
      return true;
    }

    final entryCells = _neighbors(
      currentEnd,
      rows: rows,
      columns: columns,
    ).where(remaining.contains).toList();
    if (entryCells.isEmpty) {
      return false;
    }

    final visited = <BoardPosition>{entryCells.first};
    final queue = <BoardPosition>[entryCells.first];
    var cursor = 0;
    while (cursor < queue.length) {
      final current = queue[cursor++];
      for (final next in _neighbors(current, rows: rows, columns: columns)) {
        if (remaining.contains(next) && visited.add(next)) {
          queue.add(next);
        }
      }
    }
    if (visited.length != remaining.length) {
      return false;
    }

    if (remaining.length > 1) {
      for (final cell in remaining) {
        final remainingDegree = _neighbors(
          cell,
          rows: rows,
          columns: columns,
        ).where(remaining.contains).length;
        if (remainingDegree == 0) {
          return false;
        }
      }
    }
    return true;
  }

  List<GeneratedPuzzlePath> _partitionTraversal(
    List<BoardPosition> traversal, {
    required int pairCount,
    required int minPathLength,
    required math.Random random,
  }) {
    final lengths = List<int>.filled(pairCount, minPathLength);
    var remaining = traversal.length - pairCount * minPathLength;
    while (remaining > 0) {
      // Giving a random path a random batch produces unequal path lengths and
      // avoids the recognizable equal slices of a basic snake partition.
      final pathIndex = random.nextInt(pairCount);
      final batch = 1 + random.nextInt(math.min(remaining, 4));
      lengths[pathIndex] += batch;
      remaining -= batch;
    }

    final paths = <GeneratedPuzzlePath>[];
    var cursor = 0;
    for (var id = 0; id < pairCount; id++) {
      final cells = traversal.sublist(cursor, cursor + lengths[id]);
      cursor += lengths[id];
      paths.add(
        GeneratedPuzzlePath(
          id: id,
          cells: List<BoardPosition>.unmodifiable(
            random.nextBool() ? cells : cells.reversed,
          ),
        ),
      );
    }
    paths.shuffle(random);
    return List<GeneratedPuzzlePath>.unmodifiable(paths);
  }

  List<BoardPosition> _fallbackTraversal({
    required int rows,
    required int columns,
    required math.Random random,
  }) {
    final useColumns = random.nextBool();
    var traversal = useColumns
        ? <BoardPosition>[
            for (var column = 0; column < columns; column++)
              if (column.isEven)
                for (var row = 0; row < rows; row++)
                  BoardPosition(row: row, column: column)
              else
                for (var row = rows - 1; row >= 0; row--)
                  BoardPosition(row: row, column: column),
          ]
        : <BoardPosition>[
            for (var row = 0; row < rows; row++)
              if (row.isEven)
                for (var column = 0; column < columns; column++)
                  BoardPosition(row: row, column: column)
              else
                for (var column = columns - 1; column >= 0; column--)
                  BoardPosition(row: row, column: column),
          ];

    final reflectRows = random.nextBool();
    final reflectColumns = random.nextBool();
    traversal = [
      for (final cell in traversal)
        BoardPosition(
          row: reflectRows ? rows - 1 - cell.row : cell.row,
          column: reflectColumns ? columns - 1 - cell.column : cell.column,
        ),
    ];
    if (random.nextBool()) {
      traversal = traversal.reversed.toList();
    }
    return List<BoardPosition>.unmodifiable(traversal);
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

  PuzzleDifficultyMetrics _difficultyMetrics(List<GeneratedPuzzlePath> paths) {
    final lengths = [for (final path in paths) path.cells.length];
    final turns = [for (final path in paths) _turnCount(path.cells)];
    final totalLength = lengths.reduce((first, second) => first + second);
    final totalTurns = turns.reduce((first, second) => first + second);
    return PuzzleDifficultyMetrics(
      pairCount: paths.length,
      averagePathLength: totalLength / paths.length,
      totalTurns: totalTurns,
      averageTurnsPerPath: totalTurns / paths.length,
      longestPath: lengths.reduce(math.max),
      shortestPath: lengths.reduce(math.min),
    );
  }

  int _turnCount(List<BoardPosition> cells) {
    var turns = 0;
    for (var index = 2; index < cells.length; index++) {
      final previousRow = cells[index - 1].row - cells[index - 2].row;
      final previousColumn = cells[index - 1].column - cells[index - 2].column;
      final row = cells[index].row - cells[index - 1].row;
      final column = cells[index].column - cells[index - 1].column;
      if (row != previousRow || column != previousColumn) {
        turns++;
      }
    }
    return turns;
  }

  void _validateConfig(PuzzleGenerationConfig config) {
    if (config.rows <= 0 || config.columns <= 0) {
      throw ArgumentError('Board dimensions must be positive.');
    }
    if (config.pairCount <= 0) {
      throw ArgumentError.value(config.pairCount, 'pairCount');
    }
    if (config.minPathLength < 2) {
      throw ArgumentError.value(config.minPathLength, 'minPathLength');
    }
    if (config.rows * config.columns <
        config.pairCount * config.minPathLength) {
      throw ArgumentError(
        'Board does not contain enough cells for ${config.pairCount} paths '
        'with minimum length ${config.minPathLength}.',
      );
    }
    if (config.maxGenerationAttempts <= 0 ||
        config.maxBacktrackSteps <= 0 ||
        config.coverageSearchMaxStates <= 0) {
      throw ArgumentError(
        'Generation and backtracking limits must be positive.',
      );
    }
  }

  int _newSeed() {
    final random = math.Random();
    return DateTime.now().microsecondsSinceEpoch ^ random.nextInt(0x7fffffff);
  }

  int _mixSeed(int seed, int attempt) {
    var value = seed & 0x7fffffff;
    value = (value * 1103515245 + 12345 + attempt * 7919) & 0x7fffffff;
    return value;
  }

  void _debugLog(
    GeneratedPuzzle puzzle, {
    required bool valid,
    PuzzleCoverageAnalysis? coverageAnalysis,
  }) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      'Generated puzzle\n'
      'Board: ${puzzle.rows}x${puzzle.columns}\n'
      'Seed: ${puzzle.seed}\n'
      'Pairs: ${puzzle.paths.length}\n'
      'Path lengths: ${puzzle.paths.map((path) => path.cells.length).toList()}\n'
      'Covered cells: ${puzzle.paths.fold<int>(0, (sum, path) => sum + path.cells.length)}/${puzzle.rows * puzzle.columns}\n'
      'Valid: $valid\n'
      'Unique solution: ${puzzle.uniquenessStatus.name}\n'
      'Generation attempts: ${puzzle.generationAttempts}\n'
      'Backtracks: ${puzzle.backtracks}\n'
      'Incomplete completion found: ${coverageAnalysis?.hasIncompleteCompletion ?? 'not checked'}\n'
      'Minimum completion coverage: ${coverageAnalysis?.minimumCoveredCellCount ?? 'not checked'}/${puzzle.rows * puzzle.columns}\n'
      'Coverage-search states: ${coverageAnalysis?.exploredStates ?? 0}\n'
      'Coverage-search exhausted: ${coverageAnalysis?.searchExhausted ?? false}\n'
      'Candidate accepted: yes',
    );
  }

  void _debugLogRejection({
    required PuzzleGenerationConfig config,
    required int seed,
    required List<GeneratedPuzzlePath> paths,
    required int generationAttempts,
    required int backtracks,
    required PuzzleCoverageAnalysis analysis,
    required String reason,
  }) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      'Generated puzzle candidate\n'
      'Board: ${config.rows}x${config.columns}\n'
      'Seed: $seed\n'
      'Pairs: ${paths.length}\n'
      'Path lengths: ${paths.map((path) => path.cells.length).toList()}\n'
      'Covered cells: ${paths.expand((path) => path.cells).toSet().length}/${config.rows * config.columns}\n'
      'Generation attempts: $generationAttempts\n'
      'Backtracks: $backtracks\n'
      'Incomplete completion found: ${analysis.hasIncompleteCompletion}\n'
      'Minimum completion coverage: ${analysis.minimumCoveredCellCount}/${config.rows * config.columns}\n'
      'Coverage-search states: ${analysis.exploredStates}\n'
      'Coverage-search exhausted: ${analysis.searchExhausted}\n'
      'Candidate accepted: no\n'
      'Rejected: $reason',
    );
  }
}

GeneratedPuzzle generatePuzzle({
  required int rows,
  required int columns,
  required int pairCount,
  int? seed,
  int minPathLength = 3,
  bool requireUniqueSolution = false,
  bool rejectIncompleteCompletions = false,
  bool rejectWhenCoverageSearchIsInconclusive = false,
  int coverageSearchMaxStates = 50000,
  bool debugLogging = false,
  PuzzleUniquenessSolver? uniquenessSolver,
  PuzzleCoverageSolver? coverageSolver,
  PuzzleSignatureHistory? signatureHistory,
}) {
  return PuzzleGenerator(
    uniquenessSolver: uniquenessSolver,
    coverageSolver: coverageSolver,
    signatureHistory:
        signatureHistory ?? (seed == null ? _defaultSignatureHistory : null),
  ).generate(
    PuzzleGenerationConfig(
      rows: rows,
      columns: columns,
      pairCount: pairCount,
      seed: seed,
      minPathLength: minPathLength,
      requireUniqueSolution: requireUniqueSolution,
      rejectIncompleteCompletions: rejectIncompleteCompletions,
      rejectWhenCoverageSearchIsInconclusive:
          rejectWhenCoverageSearchIsInconclusive,
      coverageSearchMaxStates: coverageSearchMaxStates,
      debugLogging: debugLogging,
    ),
  );
}

final PuzzleSignatureHistory _defaultSignatureHistory = PuzzleSignatureHistory(
  capacity: 50,
);

class _TraversalGrowth {
  const _TraversalGrowth({required this.cells, required this.backtracks});

  final List<BoardPosition>? cells;
  final int backtracks;
}
