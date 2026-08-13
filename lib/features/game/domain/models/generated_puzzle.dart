import 'board_position.dart';

enum PuzzleUniquenessStatus { notChecked, unique, multiple, unsolvable }

class GeneratedPuzzlePath {
  const GeneratedPuzzlePath({required this.id, required this.cells});

  final int id;
  final List<BoardPosition> cells;

  BoardPosition get first => cells.first;
  BoardPosition get last => cells.last;
}

class GeneratedPuzzleEndpointPair {
  const GeneratedPuzzleEndpointPair({
    required this.pathId,
    required this.first,
    required this.second,
  });

  final int pathId;
  final BoardPosition first;
  final BoardPosition second;
}

class PuzzleDifficultyMetrics {
  const PuzzleDifficultyMetrics({
    required this.pairCount,
    required this.averagePathLength,
    required this.totalTurns,
    required this.averageTurnsPerPath,
    required this.longestPath,
    required this.shortestPath,
  });

  final int pairCount;
  final double averagePathLength;
  final int totalTurns;
  final double averageTurnsPerPath;
  final int longestPath;
  final int shortestPath;
}

class GeneratedPuzzle {
  const GeneratedPuzzle({
    required this.rows,
    required this.columns,
    required this.seed,
    required this.paths,
    required this.signature,
    required this.metrics,
    required this.generationAttempts,
    required this.backtracks,
    required this.usedFallback,
    this.uniquenessStatus = PuzzleUniquenessStatus.notChecked,
  });

  final int rows;
  final int columns;
  final int seed;
  final List<GeneratedPuzzlePath> paths;
  final String signature;
  final PuzzleDifficultyMetrics metrics;
  final int generationAttempts;
  final int backtracks;
  final bool usedFallback;
  final PuzzleUniquenessStatus uniquenessStatus;

  List<GeneratedPuzzleEndpointPair> get endpoints =>
      List<GeneratedPuzzleEndpointPair>.unmodifiable([
        for (final path in paths)
          GeneratedPuzzleEndpointPair(
            pathId: path.id,
            first: path.first,
            second: path.last,
          ),
      ]);

  GeneratedPuzzle copyWith({PuzzleUniquenessStatus? uniquenessStatus}) {
    return GeneratedPuzzle(
      rows: rows,
      columns: columns,
      seed: seed,
      paths: paths,
      signature: signature,
      metrics: metrics,
      generationAttempts: generationAttempts,
      backtracks: backtracks,
      usedFallback: usedFallback,
      uniquenessStatus: uniquenessStatus ?? this.uniquenessStatus,
    );
  }
}
