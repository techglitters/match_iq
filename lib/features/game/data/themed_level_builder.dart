import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../domain/models/generated_puzzle.dart';
import '../domain/models/board_position.dart';
import '../domain/models/game_level.dart';
import '../domain/models/game_path.dart';
import '../domain/models/learning_relationship.dart';
import '../domain/models/level_pair_placement.dart';
import '../domain/models/level_solution.dart';
import 'full_board_puzzle_solver.dart';

class GeneratedThemeLevel {
  const GeneratedThemeLevel({required this.level, required this.solutionPaths});

  final GameLevel level;
  final Map<String, GamePath> solutionPaths;
}

enum ThemedLevelProgression { linear, chaptered }

class ThemedLevelDifficulty {
  const ThemedLevelDifficulty({
    required this.score,
    required this.interiorEndpointRatio,
    required this.cornerEndpointRatio,
    required this.alignedPairRatio,
    required this.distanceRatio,
    required this.routeConflictRatio,
    required this.detourRatio,
    required this.turnRatio,
    required this.greedyFailureRatio,
    required this.greedyCoverageRatio,
    required this.endpointCongestionRatio,
    required this.chokePointRatio,
    required this.boardDistributionRatio,
    required this.naturalCoverageRatio,
    required this.endpointDemandRatio,
    required this.shortcutTrapRatio,
    required this.kShortestRouteConflictRatio,
    required this.misleadingRouteRatio,
    required this.alternativeRouteDiversity,
    required this.easyJointCompletionFound,
  });

  final double score;
  final double interiorEndpointRatio;
  final double cornerEndpointRatio;
  final double alignedPairRatio;
  final double distanceRatio;
  final double routeConflictRatio;
  final double detourRatio;
  final double turnRatio;
  final double greedyFailureRatio;
  final double greedyCoverageRatio;
  final double endpointCongestionRatio;
  final double chokePointRatio;
  final double boardDistributionRatio;
  final double naturalCoverageRatio;
  final double endpointDemandRatio;
  final double shortcutTrapRatio;
  final double kShortestRouteConflictRatio;
  final double misleadingRouteRatio;
  final double alternativeRouteDiversity;
  final bool easyJointCompletionFound;
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
    maxPairs: 7,
  );

  final int maxRows;
  final int maxColumns;
  final int maxPairs;

  factory ThemeBoardProfile.forSize(Size size) {
    final shortestSide = math.min(size.width, size.height);
    final longestSide = math.max(size.width, size.height);

    if (shortestSide < 390 || longestSide < 720) {
      return const ThemeBoardProfile(maxRows: 10, maxColumns: 6, maxPairs: 6);
    }

    if (shortestSide < 600) {
      return const ThemeBoardProfile(maxRows: 12, maxColumns: 7, maxPairs: 7);
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
  ThemedLevelProgression progression = ThemedLevelProgression.linear,
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
        progression: progression,
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
  ThemedLevelProgression progression = ThemedLevelProgression.linear,
}) {
  final blueprint = _LevelBlueprint.forLevel(
    levelNumber: levelNumber.clamp(1, totalLevelCount).toInt(),
    totalLevelCount: totalLevelCount,
    relationshipCount: relationships.length,
    profile: profile,
    progression: progression,
  );
  final paths = _generateProgressivePaths(
    layoutKey: idPrefix,
    levelNumber: blueprint.levelNumber,
    totalLevelCount: totalLevelCount,
    rows: blueprint.rows,
    columns: blueprint.columns,
    pairCount: blueprint.pairCount,
    progression: progression,
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

  final expectedCellCount = level.rows * level.columns;
  if (occupiedSolutionCells.length != expectedCellCount) {
    errors.add(
      '${level.id}: known solution covers '
      '${occupiedSolutionCells.length}/$expectedCellCount cells; '
      '100% board coverage is required.',
    );
  }

  return errors;
}

double scoreThemedLevelDifficulty(GameLevel level) {
  return analyzeThemedLevelDifficulty(level).score;
}

ThemedLevelDifficulty analyzeThemedLevelDifficulty(GameLevel level) {
  return _analyzePathLayout(
    paths: [for (final solution in level.solutions) solution.cells],
    rows: level.rows,
    columns: level.columns,
  );
}

List<BoardPosition> _orientedPath(List<BoardPosition> path, int seed) {
  if (seed.isEven) {
    return List<BoardPosition>.unmodifiable(path.reversed);
  }
  return path;
}

void _addPathLayoutCandidate(
  List<_PathLayoutCandidate> candidates, {
  required List<List<BoardPosition>> paths,
  required int rows,
  required int columns,
  bool isStructuralChoke = false,
}) {
  if (!_isValidFullCoveragePathPartition(paths, rows: rows, columns: columns)) {
    return;
  }
  final difficulty = _analyzePathLayout(
    paths: paths,
    rows: rows,
    columns: columns,
  );
  if (isStructuralChoke &&
      (difficulty.endpointDemandRatio < 0.75 ||
          difficulty.naturalCoverageRatio < 0.62 ||
          difficulty.alignedPairRatio > 0.50 ||
          !_hasInternalShortestRouteChoke(
            paths,
            rows: rows,
            columns: columns,
          ) ||
          difficulty.boardDistributionRatio < 0.60)) {
    return;
  }
  candidates.add(
    _PathLayoutCandidate(
      paths: paths,
      difficulty: difficulty,
      isStructuralChoke: isStructuralChoke,
    ),
  );
}

List<List<BoardPosition>> _generateProgressivePaths({
  required String layoutKey,
  required int levelNumber,
  required int totalLevelCount,
  required int rows,
  required int columns,
  required int pairCount,
  required ThemedLevelProgression progression,
}) {
  final progress = _difficultyProgress(
    levelNumber: levelNumber,
    totalLevelCount: totalLevelCount,
    progression: progression,
  );
  final isBossLevel =
      progression == ThemedLevelProgression.chaptered && levelNumber % 10 == 0;
  final baseSeed = _stableSeed('$layoutKey:$levelNumber:$rows:$columns');
  final candidates = <_PathLayoutCandidate>[];
  final candidateCount =
      48 +
      (progress * progress * 160).round() +
      (pairCount * progress * 8).round() +
      (isBossLevel ? 48 : 0);

  if (rows == 5 && columns == 5 && pairCount == 3) {
    final openingRandom = math.Random(baseSeed);
    final rotation = openingRandom.nextInt(4);
    final reflect = openingRandom.nextBool();
    final openingPaths = _randomlyOrientAndOrderPaths([
      for (final path in _forcedFiveByFiveThreePairPaths())
        [
          for (final cell in path)
            _transformSquareCell(
              cell,
              size: 5,
              rotation: rotation,
              reflect: reflect,
            ),
        ],
    ], openingRandom);
    _addPathLayoutCandidate(
      candidates,
      paths: openingPaths,
      rows: rows,
      columns: columns,
    );
  }

  for (final paths in _fullCoverageChokePathOptions(
    rows: rows,
    columns: columns,
    pairCount: pairCount,
    seed: baseSeed,
    progress: progress,
    isBossLevel: isBossLevel,
  )) {
    _addPathLayoutCandidate(
      candidates,
      paths: paths,
      rows: rows,
      columns: columns,
      isStructuralChoke: true,
    );
  }

  for (
    var candidateIndex = 0;
    candidateIndex < candidateCount;
    candidateIndex += 1
  ) {
    final random = math.Random(baseSeed + candidateIndex * 7919);
    var traversal = _baseTraversalForCandidate(
      rows: rows,
      columns: columns,
      candidateIndex: candidateIndex,
    );
    traversal = _transformTraversal(
      traversal,
      rows: rows,
      columns: columns,
      random: random,
    );
    final baseMutationCount =
        2 +
        (progress * 12).round() +
        (progress * progress * 16).round() +
        (isBossLevel ? 6 : 0);
    final isCleanStructureCandidate =
        candidateIndex % 4 == 2 || candidateIndex % 7 == 0;
    traversal = _mutateTraversal(
      traversal,
      random: random,
      mutationCount: isCleanStructureCandidate
          ? (progress * 4).round() + random.nextInt(2)
          : baseMutationCount + random.nextInt(5),
    );
    if (progress >= 0.55 &&
        candidateIndex.isOdd &&
        !isCleanStructureCandidate) {
      traversal = _mutateTraversal(
        traversal,
        random: random,
        mutationCount: 3 + (progress * 8).round(),
      );
    }

    if (_areAdjacent(traversal.first, traversal.last)) {
      final offset = random.nextInt(traversal.length);
      traversal = List<BoardPosition>.unmodifiable([
        ...traversal.skip(offset),
        ...traversal.take(offset),
      ]);
    }

    if (!_isContinuousTraversal(traversal)) {
      continue;
    }

    final paths = _partitionTraversalIntoPaths(
      traversal: traversal,
      pairCount: pairCount,
      random: random,
      variation: 0.15 + progress * 0.85,
    );
    _addPathLayoutCandidate(
      candidates,
      paths: paths,
      rows: rows,
      columns: columns,
    );
  }

  if (candidates.isEmpty) {
    return _partitionTraversalIntoPaths(
      traversal: _spiralTraversal(rows, columns),
      pairCount: pairCount,
    );
  }

  candidates.sort(
    (first, second) =>
        first.difficulty.score.compareTo(second.difficulty.score),
  );
  final areaDifficulty = ((rows * columns - 25) / 75 * 4).clamp(0, 4);
  final targetDifficulty =
      30 + progress * 36 + areaDifficulty + (isBossLevel ? 2 : 0);
  final minimumGreedyFailure = progress >= 0.75
      ? 0.99
      : progress <= 0.25
      ? 0.0
      : (0.20 + (progress - 0.25) / 0.50 * 0.55 + (isBossLevel ? 0.08 : 0))
            .clamp(0.20, 0.90);
  final minimumRouteConflict =
      (0.05 + progress * 0.35 + (isBossLevel ? 0.08 : 0)).clamp(0, 0.90);
  final maximumCornerRatio = progress < 0.35
      ? 1.0
      : (0.30 - (progress - 0.35) / 0.65 * 0.20).clamp(0.10, 0.30);
  final minimumEndpointCongestion = progress >= 0.75
      ? 0.55
      : progress < 0.40
      ? 0.0
      : ((progress - 0.40) / 0.35 * 0.40).clamp(0, 0.40);
  final minimumChokePoint = progress < 0.35
      ? 0.0
      : (0.40 + (progress - 0.35) / 0.65 * 0.24 + (isBossLevel ? 0.04 : 0))
            .clamp(0.40, 0.72);
  final minimumBoardDistribution =
      (0.60 + progress * 0.20 + (isBossLevel ? 0.04 : 0)).clamp(0.60, 0.88);
  final minimumNaturalCoverage = 0.70 + (isBossLevel ? 0.03 : 0);
  final minimumEndpointDemand =
      (0.68 + progress * 0.10 + (isBossLevel ? 0.02 : 0)).clamp(0.68, 0.82);
  final maximumPathExcess = math.max(
    6,
    (rows * columns / pairCount * 1.15).round(),
  );
  final minimumShortcutTrap = progress < 0.18
      ? 0.10
      : (0.20 + progress * 0.34 + (isBossLevel ? 0.05 : 0)).clamp(0.20, 0.62);
  final minimumKRouteConflict = progress < 0.30
      ? 0.0
      : (0.10 + progress * 0.34 + (isBossLevel ? 0.05 : 0)).clamp(0.10, 0.55);
  final minimumMisleadingRoutes = progress < 0.35
      ? 0.0
      : (0.08 + progress * 0.32 + (isBossLevel ? 0.05 : 0)).clamp(0.08, 0.48);
  final lateQualityCandidates = progress < 0.75
      ? candidates
      : candidates.where((candidate) {
          return candidate.difficulty.endpointCongestionRatio >= 0.45 &&
              candidate.difficulty.endpointDemandRatio >= 0.80;
        }).toList();
  final selectionCandidates = lateQualityCandidates.isEmpty
      ? candidates
      : lateQualityCandidates;
  final structuralChokeCandidates = selectionCandidates.where((candidate) {
    return candidate.isStructuralChoke &&
        candidate.difficulty.endpointDemandRatio >=
            (progress >= 0.75
                ? math.max(0.80, minimumEndpointDemand)
                : minimumEndpointDemand) &&
        candidate.difficulty.endpointCongestionRatio >=
            (progress >= 0.75 ? 0.45 : minimumEndpointCongestion) &&
        candidate.difficulty.naturalCoverageRatio >= minimumNaturalCoverage &&
        candidate.difficulty.alignedPairRatio <= 0.50 &&
        _hasInternalShortestRouteChoke(
          candidate.paths,
          rows: rows,
          columns: columns,
        ) &&
        candidate.difficulty.boardDistributionRatio >=
            minimumBoardDistribution &&
        candidate.difficulty.shortcutTrapRatio >= minimumShortcutTrap * 0.65 &&
        candidate.difficulty.kShortestRouteConflictRatio >=
            minimumKRouteConflict * 0.70 &&
        candidate.difficulty.misleadingRouteRatio >=
            minimumMisleadingRoutes * 0.65 &&
        candidate.difficulty.chokePointRatio >=
            (progress < 0.35 ? 0.12 : minimumChokePoint * 0.50);
  }).toList()..sort(_comparePathLayoutPriority);
  for (final candidate in structuralChokeCandidates.reversed) {
    if (_passesCoverageSearch(
      candidate,
      rows: rows,
      columns: columns,
      levelNumber: levelNumber,
      seed: baseSeed,
    )) {
      return candidate.paths;
    }
  }
  for (final candidate in selectionCandidates) {
    if (candidate.difficulty.score >= targetDifficulty &&
        _maximumPathExcessCells(candidate.paths) <= maximumPathExcess &&
        candidate.difficulty.greedyFailureRatio >= minimumGreedyFailure &&
        candidate.difficulty.routeConflictRatio >= minimumRouteConflict &&
        candidate.difficulty.cornerEndpointRatio <= maximumCornerRatio &&
        candidate.difficulty.endpointCongestionRatio >=
            minimumEndpointCongestion &&
        candidate.difficulty.chokePointRatio >= minimumChokePoint &&
        candidate.difficulty.boardDistributionRatio >=
            minimumBoardDistribution &&
        candidate.difficulty.naturalCoverageRatio >= minimumNaturalCoverage &&
        candidate.difficulty.endpointDemandRatio >= minimumEndpointDemand &&
        candidate.difficulty.shortcutTrapRatio >= minimumShortcutTrap &&
        candidate.difficulty.kShortestRouteConflictRatio >=
            minimumKRouteConflict &&
        candidate.difficulty.misleadingRouteRatio >= minimumMisleadingRoutes &&
        (progress < 0.55 || !candidate.difficulty.easyJointCompletionFound)) {
      if (_passesCoverageSearch(
        candidate,
        rows: rows,
        columns: columns,
        levelNumber: levelNumber,
        seed: baseSeed,
      )) {
        return candidate.paths;
      }
    }
  }
  var fallbackCandidates = selectionCandidates.where((candidate) {
    return candidate.difficulty.endpointDemandRatio >= minimumEndpointDemand &&
        candidate.difficulty.shortcutTrapRatio >= minimumShortcutTrap * 0.70 &&
        candidate.difficulty.kShortestRouteConflictRatio >=
            minimumKRouteConflict * 0.55 &&
        candidate.difficulty.misleadingRouteRatio >=
            minimumMisleadingRoutes * 0.50 &&
        _maximumPathExcessCells(candidate.paths) <= maximumPathExcess;
  }).toList();
  if (fallbackCandidates.isEmpty) {
    fallbackCandidates = selectionCandidates.where((candidate) {
      return candidate.difficulty.endpointDemandRatio >=
              (progress >= 0.75 ? 0.80 : 0.65) &&
          candidate.difficulty.endpointCongestionRatio >=
              (progress >= 0.75 ? 0.45 : 0.0) &&
          _maximumPathExcessCells(candidate.paths) <= maximumPathExcess;
    }).toList();
  }
  if (fallbackCandidates.isEmpty) {
    fallbackCandidates = selectionCandidates;
  }
  if (progress >= 0.75) {
    final lateGameCandidates = fallbackCandidates.where((candidate) {
      return candidate.difficulty.greedyFailureRatio >= 0.99 &&
          candidate.difficulty.chokePointRatio >= 0.50 &&
          candidate.difficulty.endpointCongestionRatio >=
              minimumEndpointCongestion &&
          candidate.difficulty.cornerEndpointRatio <= maximumCornerRatio &&
          candidate.difficulty.boardDistributionRatio >=
              minimumBoardDistribution &&
          candidate.difficulty.naturalCoverageRatio >= minimumNaturalCoverage &&
          candidate.difficulty.shortcutTrapRatio >=
              minimumShortcutTrap * 0.80 &&
          candidate.difficulty.kShortestRouteConflictRatio >=
              minimumKRouteConflict * 0.75 &&
          candidate.difficulty.misleadingRouteRatio >=
              minimumMisleadingRoutes * 0.70 &&
          !candidate.difficulty.easyJointCompletionFound;
    }).toList();
    if (lateGameCandidates.isNotEmpty) {
      fallbackCandidates = lateGameCandidates;
    }
  }
  fallbackCandidates.sort(_comparePathLayoutPriority);
  final coverageSearchCandidates = <_PathLayoutCandidate>[
    ...fallbackCandidates.reversed,
    ...selectionCandidates.reversed.where(
      (candidate) => !fallbackCandidates.contains(candidate),
    ),
  ];
  for (final candidate in coverageSearchCandidates) {
    if (_passesCoverageSearch(
      candidate,
      rows: rows,
      columns: columns,
      levelNumber: levelNumber,
      seed: baseSeed,
    )) {
      return candidate.paths;
    }
  }
  if (coverageSearchCandidates.isNotEmpty) {
    return coverageSearchCandidates.first.paths;
  }
  throw StateError(
    'Unable to generate level $levelNumber ($rows x $columns, $pairCount '
    'pairs) without an incomplete endpoint-only completion. Seed: $baseSeed.',
  );
}

List<List<BoardPosition>> _forcedFiveByFiveThreePairPaths() {
  return const [
    [
      BoardPosition(row: 0, column: 2),
      BoardPosition(row: 0, column: 3),
      BoardPosition(row: 0, column: 4),
      BoardPosition(row: 1, column: 4),
      BoardPosition(row: 2, column: 4),
      BoardPosition(row: 3, column: 4),
      BoardPosition(row: 4, column: 4),
      BoardPosition(row: 4, column: 3),
      BoardPosition(row: 4, column: 2),
      BoardPosition(row: 4, column: 1),
      BoardPosition(row: 4, column: 0),
      BoardPosition(row: 3, column: 0),
      BoardPosition(row: 2, column: 0),
      BoardPosition(row: 1, column: 0),
      BoardPosition(row: 0, column: 0),
    ],
    [
      BoardPosition(row: 0, column: 1),
      BoardPosition(row: 1, column: 1),
      BoardPosition(row: 1, column: 2),
      BoardPosition(row: 1, column: 3),
      BoardPosition(row: 2, column: 3),
      BoardPosition(row: 3, column: 3),
      BoardPosition(row: 3, column: 2),
    ],
    [
      BoardPosition(row: 2, column: 2),
      BoardPosition(row: 2, column: 1),
      BoardPosition(row: 3, column: 1),
    ],
  ];
}

BoardPosition _transformSquareCell(
  BoardPosition cell, {
  required int size,
  required int rotation,
  required bool reflect,
}) {
  var transformed = reflect
      ? BoardPosition(row: cell.row, column: size - 1 - cell.column)
      : cell;
  for (var turn = 0; turn < rotation; turn += 1) {
    transformed = BoardPosition(
      row: transformed.column,
      column: size - 1 - transformed.row,
    );
  }
  return transformed;
}

bool _passesCoverageSearch(
  _PathLayoutCandidate candidate, {
  required int rows,
  required int columns,
  required int levelNumber,
  required int seed,
}) {
  final knownCoveredCells = candidate.paths.expand((path) => path).toSet();
  if (knownCoveredCells.length == rows * columns &&
      candidate.difficulty.endpointDemandRatio >= 0.999999) {
    if (kDebugMode) {
      debugPrint(
        'Generated level $levelNumber\n'
        'Seed: $seed\n'
        'Board: ${rows}x$columns\n'
        'Pairs: ${candidate.paths.length}\n'
        'Path lengths: ${candidate.paths.map((path) => path.length).toList()}\n'
        'Known coverage: ${knownCoveredCells.length}/${rows * columns}\n'
        'Incomplete completion found: false\n'
        'Minimum completion coverage: ${rows * columns}/${rows * columns}\n'
        'Coverage solver states: 0\n'
        'Coverage search exhausted: true (shortest-route lower bound)\n'
        'Candidate accepted: true',
      );
    }
    return true;
  }
  const solver = FullBoardPuzzleSolver(defaultMaxSearchStates: 50000);
  final generatedPaths = <GeneratedPuzzlePath>[
    for (var index = 0; index < candidate.paths.length; index += 1)
      GeneratedPuzzlePath(id: index, cells: candidate.paths[index]),
  ];
  final analysis = solver.analyzeCoverage(
    GeneratedPuzzle(
      rows: rows,
      columns: columns,
      seed: seed,
      paths: generatedPaths,
      signature: '',
      metrics: PuzzleDifficultyMetrics(
        pairCount: generatedPaths.length,
        averagePathLength: rows * columns / generatedPaths.length,
        totalTurns: 0,
        averageTurnsPerPath: 0,
        longestPath: generatedPaths
            .map((path) => path.cells.length)
            .reduce(math.max),
        shortestPath: generatedPaths
            .map((path) => path.cells.length)
            .reduce(math.min),
      ),
      generationAttempts: 1,
      backtracks: 0,
      usedFallback: false,
    ),
  );
  // Gameplay independently requires a filled board. The shared
  // PuzzleGenerator exposes a stricter opt-in policy for callers that want to
  // reject inconclusive bounded searches as well as found counterexamples.
  const rejectWhenCoverageSearchIsInconclusive = false;
  final accepted =
      analysis.hasFullCoverageSolution &&
      !analysis.hasIncompleteCompletion &&
      (analysis.searchExhausted || !rejectWhenCoverageSearchIsInconclusive);
  if (kDebugMode && accepted) {
    debugPrint(
      'Generated level $levelNumber\n'
      'Seed: $seed\n'
      'Board: ${rows}x$columns\n'
      'Pairs: ${candidate.paths.length}\n'
      'Path lengths: ${candidate.paths.map((path) => path.length).toList()}\n'
      'Known coverage: ${candidate.paths.expand((path) => path).toSet().length}/${rows * columns}\n'
      'Incomplete completion found: ${analysis.hasIncompleteCompletion}\n'
      'Minimum completion coverage: ${analysis.minimumCoveredCellCount}/${rows * columns}\n'
      'Coverage solver states: ${analysis.exploredStates}\n'
      'Coverage search exhausted: ${analysis.searchExhausted}\n'
      'Candidate accepted: $accepted\n'
      '${accepted ? '' : 'Rejection reason: ${analysis.hasIncompleteCompletion ? 'endpoint layout allows partial-board completion' : 'coverage search inconclusive'}'}',
    );
  }
  return accepted;
}

int _comparePathLayoutPriority(
  _PathLayoutCandidate first,
  _PathLayoutCandidate second,
) {
  return _pathLayoutPriority(first).compareTo(_pathLayoutPriority(second));
}

double _pathLayoutPriority(_PathLayoutCandidate candidate) {
  return candidate.difficulty.greedyFailureRatio * 30 +
      candidate.difficulty.routeConflictRatio * 22 +
      candidate.difficulty.chokePointRatio * 22 +
      candidate.difficulty.endpointCongestionRatio * 12 +
      candidate.difficulty.boardDistributionRatio * 12 +
      candidate.difficulty.endpointDemandRatio * 20 +
      candidate.difficulty.shortcutTrapRatio * 30 +
      candidate.difficulty.kShortestRouteConflictRatio * 24 +
      candidate.difficulty.misleadingRouteRatio * 32 +
      candidate.difficulty.alternativeRouteDiversity * 8 +
      (candidate.difficulty.easyJointCompletionFound ? -24 : 14) +
      candidate.difficulty.naturalCoverageRatio * 15 +
      (1 - candidate.difficulty.cornerEndpointRatio) * 8 +
      candidate.difficulty.detourRatio * 2 +
      candidate.difficulty.score * 0.03 +
      (candidate.isStructuralChoke ? 18 : 0);
}

Iterable<List<List<BoardPosition>>> _fullCoverageChokePathOptions({
  required int rows,
  required int columns,
  required int pairCount,
  required int seed,
  required double progress,
  required bool isBossLevel,
}) sync* {
  final optionCount = 16 + (progress * 16).round() + (isBossLevel ? 8 : 0);
  for (var optionIndex = 0; optionIndex < optionCount; optionIndex += 1) {
    final random = math.Random(seed + optionIndex * 104729);
    final cycle = _hamiltonianCycleTraversal(rows, columns);
    if (cycle != null) {
      var traversal = _transformTraversal(
        cycle,
        rows: rows,
        columns: columns,
        random: random,
      );
      final offset = random.nextInt(traversal.length);
      traversal = List<BoardPosition>.unmodifiable([
        ...traversal.skip(offset),
        ...traversal.take(offset),
      ]);
      final paths = _partitionCycleWithChokeCuts(
        cycle: traversal,
        pairCount: pairCount,
        rows: rows,
        columns: columns,
        random: random,
      );
      if (paths != null) {
        yield paths;
      }
      continue;
    }

    var traversal = _baseTraversalForCandidate(
      rows: rows,
      columns: columns,
      candidateIndex: optionIndex,
    );
    traversal = _transformTraversal(
      traversal,
      rows: rows,
      columns: columns,
      random: random,
    );
    if (progress >= 0.45 && optionIndex.isOdd) {
      traversal = _mutateTraversal(
        traversal,
        random: random,
        mutationCount: 1 + (progress * 4).round(),
      );
    }
    if (!_isContinuousTraversal(traversal)) {
      continue;
    }
    final paths = _partitionTraversalWithChokeCuts(
      traversal: traversal,
      pairCount: pairCount,
      rows: rows,
      columns: columns,
      random: random,
    );
    if (paths != null) {
      yield paths;
    }
  }
}

List<List<BoardPosition>>? _partitionCycleWithChokeCuts({
  required List<BoardPosition> cycle,
  required int pairCount,
  required int rows,
  required int columns,
  required math.Random random,
}) {
  final cuts = _chooseChokeCutEdges(
    traversal: cycle,
    cutCount: pairCount,
    rows: rows,
    columns: columns,
    random: random,
    isCycle: true,
  );
  if (cuts == null) {
    return null;
  }

  final sortedCuts = [...cuts]..sort();
  final paths = <List<BoardPosition>>[];
  for (var index = 0; index < sortedCuts.length; index += 1) {
    final start = (sortedCuts[index] + 1) % cycle.length;
    final end = sortedCuts[(index + 1) % sortedCuts.length];
    final cells = <BoardPosition>[];
    var cursor = start;
    while (true) {
      cells.add(cycle[cursor]);
      if (cursor == end) {
        break;
      }
      cursor = (cursor + 1) % cycle.length;
    }
    paths.add(List<BoardPosition>.unmodifiable(cells));
  }

  return _randomlyOrientAndOrderPaths(paths, random);
}

List<List<BoardPosition>>? _partitionTraversalWithChokeCuts({
  required List<BoardPosition> traversal,
  required int pairCount,
  required int rows,
  required int columns,
  required math.Random random,
}) {
  final cuts = _chooseChokeCutEdges(
    traversal: traversal,
    cutCount: pairCount - 1,
    rows: rows,
    columns: columns,
    random: random,
    isCycle: false,
  );
  if (cuts == null) {
    return null;
  }

  final paths = <List<BoardPosition>>[];
  var start = 0;
  for (final cut in [...cuts]..sort()) {
    paths.add(
      List<BoardPosition>.unmodifiable(traversal.sublist(start, cut + 1)),
    );
    start = cut + 1;
  }
  paths.add(List<BoardPosition>.unmodifiable(traversal.sublist(start)));
  return _randomlyOrientAndOrderPaths(paths, random);
}

List<int>? _chooseChokeCutEdges({
  required List<BoardPosition> traversal,
  required int cutCount,
  required int rows,
  required int columns,
  required math.Random random,
  required bool isCycle,
}) {
  if (cutCount <= 0) {
    return const [];
  }

  final lastEdgeIndex = isCycle ? traversal.length - 1 : traversal.length - 2;
  final scoredEdges = [
    for (var edgeIndex = 0; edgeIndex <= lastEdgeIndex; edgeIndex += 1)
      (
        index: edgeIndex,
        score: _chokeCutScore(
          traversal,
          edgeIndex,
          rows: rows,
          columns: columns,
          random: random,
          isCycle: isCycle,
        ),
      ),
  ]..sort((first, second) => first.score.compareTo(second.score));

  const minimumPathLength = 3;
  final averageLength = traversal.length / math.max(1, cutCount);
  for (final gapFactor in const [0.70, 0.55, 0.40, 0.28, 0.0]) {
    final minimumGap = math.max(
      minimumPathLength,
      (averageLength * gapFactor).round(),
    );
    final selected = <int>[];
    for (final edge in scoredEdges) {
      final farEnough = selected.every((other) {
        final distance = isCycle
            ? _cyclicDistance(edge.index, other, traversal.length)
            : (edge.index - other).abs();
        return distance >= minimumGap;
      });
      if (!farEnough) {
        continue;
      }
      selected.add(edge.index);
      if (selected.length == cutCount) {
        break;
      }
    }
    if (selected.length == cutCount &&
        _cutSegmentsMeetMinimumLength(
          selected,
          totalLength: traversal.length,
          isCycle: isCycle,
          minimumPathLength: minimumPathLength,
        )) {
      return List<int>.unmodifiable(selected);
    }
  }
  return null;
}

double _chokeCutScore(
  List<BoardPosition> traversal,
  int edgeIndex, {
  required int rows,
  required int columns,
  required math.Random random,
  required bool isCycle,
}) {
  final first = traversal[edgeIndex];
  final second = traversal[(edgeIndex + 1) % traversal.length];
  final centerRow = (rows - 1) / 2;
  final centerColumn = (columns - 1) / 2;
  final midpointRow = (first.row + second.row) / 2;
  final midpointColumn = (first.column + second.column) / 2;
  final centerDistance =
      (midpointRow - centerRow).abs() + (midpointColumn - centerColumn).abs();
  final boundaryPenalty =
      (_isBoundary(first, rows, columns) ? 1 : 0) +
      (_isBoundary(second, rows, columns) ? 1 : 0);
  final cornerPenalty =
      (_isCorner(first, rows, columns) ? 1 : 0) +
      (_isCorner(second, rows, columns) ? 1 : 0);
  final seamPenalty =
      !isCycle && (edgeIndex < 2 || edgeIndex > traversal.length - 4) ? 4 : 0;
  return centerDistance +
      boundaryPenalty * 1.1 +
      cornerPenalty * 2.0 +
      seamPenalty +
      random.nextDouble() * 0.45;
}

bool _cutSegmentsMeetMinimumLength(
  List<int> cuts, {
  required int totalLength,
  required bool isCycle,
  required int minimumPathLength,
}) {
  if (cuts.isEmpty) {
    return totalLength >= minimumPathLength;
  }
  final sortedCuts = [...cuts]..sort();
  if (isCycle) {
    for (var index = 0; index < sortedCuts.length; index += 1) {
      final current = sortedCuts[index];
      final next = sortedCuts[(index + 1) % sortedCuts.length];
      final length = (next - current + totalLength) % totalLength;
      if (length < minimumPathLength) {
        return false;
      }
    }
    return true;
  }

  var previousCut = -1;
  for (final cut in sortedCuts) {
    if (cut - previousCut < minimumPathLength) {
      return false;
    }
    previousCut = cut;
  }
  return totalLength - previousCut - 1 >= minimumPathLength;
}

int _cyclicDistance(int first, int second, int length) {
  final distance = (first - second).abs();
  return math.min(distance, length - distance);
}

List<List<BoardPosition>> _randomlyOrientAndOrderPaths(
  List<List<BoardPosition>> paths,
  math.Random random,
) {
  final oriented = [
    for (final path in paths)
      List<BoardPosition>.unmodifiable(
        random.nextBool() ? path : path.reversed,
      ),
  ]..shuffle(random);
  return List<List<BoardPosition>>.unmodifiable(oriented);
}

bool _isValidFullCoveragePathPartition(
  List<List<BoardPosition>> paths, {
  required int rows,
  required int columns,
}) {
  final seen = <BoardPosition>{};
  for (final path in paths) {
    if (path.length < 2) {
      return false;
    }
    for (var index = 0; index < path.length; index += 1) {
      final cell = path[index];
      if (cell.row < 0 ||
          cell.row >= rows ||
          cell.column < 0 ||
          cell.column >= columns ||
          !seen.add(cell)) {
        return false;
      }
      if (index > 0 && !_areAdjacent(path[index - 1], cell)) {
        return false;
      }
    }
  }
  return seen.length == rows * columns;
}

double _difficultyProgress({
  required int levelNumber,
  required int totalLevelCount,
  required ThemedLevelProgression progression,
}) {
  if (totalLevelCount <= 1) {
    return 1;
  }
  if (progression == ThemedLevelProgression.linear) {
    return (levelNumber - 1) / (totalLevelCount - 1);
  }

  final levelInChapter = (levelNumber - 1) % 10;
  final baseProgress = (levelNumber - 1) / (totalLevelCount - 1);
  const chapterRhythm = [
    -0.02,
    0.00,
    0.01,
    0.015,
    0.00,
    0.015,
    0.025,
    -0.03,
    0.025,
    0.04,
  ];
  return (baseProgress + chapterRhythm[levelInChapter]).clamp(0, 1);
}

List<BoardPosition> _baseTraversalForCandidate({
  required int rows,
  required int columns,
  required int candidateIndex,
}) {
  return switch (candidateIndex % 4) {
    0 => _rowSerpentineTraversal(rows, columns),
    1 => _columnSerpentineTraversal(rows, columns),
    2 => _spiralTraversal(rows, columns),
    _ =>
      _hamiltonianCycleTraversal(rows, columns) ??
          _rowSerpentineTraversal(rows, columns),
  };
}

List<BoardPosition> _transformTraversal(
  List<BoardPosition> traversal, {
  required int rows,
  required int columns,
  required math.Random random,
}) {
  final reflectRows = random.nextBool();
  var transformed = [
    for (final position in traversal)
      BoardPosition(
        row: reflectRows ? rows - 1 - position.row : position.row,
        column: position.column,
      ),
  ];

  if (random.nextBool()) {
    transformed = [
      for (final position in transformed)
        BoardPosition(row: position.row, column: columns - 1 - position.column),
    ];
  }
  if (random.nextBool()) {
    transformed = transformed.reversed.toList();
  }
  return List<BoardPosition>.unmodifiable(transformed);
}

List<BoardPosition> _mutateTraversal(
  List<BoardPosition> traversal, {
  required math.Random random,
  required int mutationCount,
}) {
  final mutated = List<BoardPosition>.of(traversal);
  var acceptedMutations = 0;
  var attempts = 0;
  final maxAttempts = mutationCount * 36;

  while (acceptedMutations < mutationCount && attempts < maxAttempts) {
    attempts += 1;
    final firstEdgeIndex = random.nextInt(mutated.length - 3);
    final secondEdgeIndex =
        firstEdgeIndex +
        2 +
        random.nextInt(mutated.length - firstEdgeIndex - 3);
    final first = mutated[firstEdgeIndex];
    final afterFirst = mutated[firstEdgeIndex + 1];
    final second = mutated[secondEdgeIndex];
    final afterSecond = mutated[secondEdgeIndex + 1];

    if (!_areAdjacent(first, second) ||
        !_areAdjacent(afterFirst, afterSecond)) {
      continue;
    }

    mutated.replaceRange(
      firstEdgeIndex + 1,
      secondEdgeIndex + 1,
      mutated.sublist(firstEdgeIndex + 1, secondEdgeIndex + 1).reversed,
    );
    acceptedMutations += 1;
  }

  return List<BoardPosition>.unmodifiable(mutated);
}

List<BoardPosition> _rowSerpentineTraversal(int rows, int columns) {
  return List<BoardPosition>.unmodifiable([
    for (var row = 0; row < rows; row += 1)
      if (row.isEven)
        for (var column = 0; column < columns; column += 1)
          BoardPosition(row: row, column: column)
      else
        for (var column = columns - 1; column >= 0; column -= 1)
          BoardPosition(row: row, column: column),
  ]);
}

List<BoardPosition> _columnSerpentineTraversal(int rows, int columns) {
  return List<BoardPosition>.unmodifiable([
    for (var column = 0; column < columns; column += 1)
      if (column.isEven)
        for (var row = 0; row < rows; row += 1)
          BoardPosition(row: row, column: column)
      else
        for (var row = rows - 1; row >= 0; row -= 1)
          BoardPosition(row: row, column: column),
  ]);
}

List<BoardPosition>? _hamiltonianCycleTraversal(int rows, int columns) {
  if (rows.isEven) {
    return _rowCycleTraversal(rows, columns);
  }
  if (columns.isEven) {
    return List<BoardPosition>.unmodifiable([
      for (final position in _rowCycleTraversal(columns, rows))
        BoardPosition(row: position.column, column: position.row),
    ]);
  }
  return null;
}

List<BoardPosition> _rowCycleTraversal(int rows, int columns) {
  final traversal = <BoardPosition>[
    for (var column = 0; column < columns; column += 1)
      BoardPosition(row: 0, column: column),
  ];

  for (var row = 1; row < rows; row += 1) {
    if (row.isOdd) {
      for (var column = columns - 1; column >= 1; column -= 1) {
        traversal.add(BoardPosition(row: row, column: column));
      }
    } else {
      for (var column = 1; column < columns; column += 1) {
        traversal.add(BoardPosition(row: row, column: column));
      }
    }
  }

  traversal.add(BoardPosition(row: rows - 1, column: 0));
  for (var row = rows - 2; row >= 1; row -= 1) {
    traversal.add(BoardPosition(row: row, column: 0));
  }
  return List<BoardPosition>.unmodifiable(traversal);
}

ThemedLevelDifficulty _analyzePathLayout({
  required List<List<BoardPosition>> paths,
  required int rows,
  required int columns,
}) {
  if (paths.isEmpty) {
    return const ThemedLevelDifficulty(
      score: 0,
      interiorEndpointRatio: 0,
      cornerEndpointRatio: 0,
      alignedPairRatio: 0,
      distanceRatio: 0,
      routeConflictRatio: 0,
      detourRatio: 0,
      turnRatio: 0,
      greedyFailureRatio: 0,
      greedyCoverageRatio: 0,
      endpointCongestionRatio: 0,
      chokePointRatio: 0,
      boardDistributionRatio: 0,
      naturalCoverageRatio: 0,
      endpointDemandRatio: 0,
      shortcutTrapRatio: 0,
      kShortestRouteConflictRatio: 0,
      misleadingRouteRatio: 0,
      alternativeRouteDiversity: 0,
      easyJointCompletionFound: false,
    );
  }

  final endpointPairs = [
    for (final path in paths) _canonicalEndpointPair(path.first, path.last),
  ];
  final endpoints = [
    for (final pair in endpointPairs) ...[pair.source, pair.target],
  ];
  final interiorRatio =
      endpoints
          .where((position) => _isInterior(position, rows, columns))
          .length /
      endpoints.length;
  final cornerRatio =
      endpoints.where((position) => _isCorner(position, rows, columns)).length /
      endpoints.length;
  final alignedRatio =
      endpointPairs
          .where(
            (pair) =>
                pair.source.row == pair.target.row ||
                pair.source.column == pair.target.column,
          )
          .length /
      endpointPairs.length;
  final maxDistance = math.max(1, rows + columns - 2);
  final distanceRatio =
      endpointPairs
          .map(
            (pair) =>
                _manhattanDistance(pair.source, pair.target) / maxDistance,
          )
          .reduce((total, value) => total + value) /
      endpointPairs.length;
  final conflictRatio = _shortestRouteConflictRatio(endpointPairs);
  final detourRatio =
      paths
          .map((path) {
            final directCells = _manhattanDistance(path.first, path.last) + 1;
            return ((path.length / directCells - 1) / 2).clamp(0, 1);
          })
          .reduce((total, value) => total + value) /
      paths.length;
  final turnRatio =
      paths.map(_pathTurnRatio).reduce((total, value) => total + value) /
      paths.length;
  final greedyAnalysis = _analyzeGreedyRoutes(
    endpointPairs,
    rows: rows,
    columns: columns,
  );
  final endpointCongestionRatio = _endpointCongestionRatio(endpointPairs);
  final chokePointRatio = _chokePointRatio(endpointPairs);
  final boardDistributionRatio = _boardDistributionRatio(
    endpoints,
    rows: rows,
    columns: columns,
  );
  final naturalCoverageRatio = _naturalCoverageRatio(
    paths,
    rows: rows,
    columns: columns,
  );
  final endpointDemandRatio = _endpointDemandRatio(
    endpointPairs,
    rows: rows,
    columns: columns,
  );
  final shortcutTrapRatio = _shortcutTrapRatio(
    paths,
    endpointPairs,
    rows: rows,
    columns: columns,
  );
  final kShortestAnalysis = _analyzeKShortestRoutes(
    paths,
    endpointPairs,
    rows: rows,
    columns: columns,
  );
  final score =
      100 *
          (interiorRatio * 0.04 +
              (1 - cornerRatio) * 0.03 +
              (1 - alignedRatio) * 0.03 +
              distanceRatio * 0.03 +
              conflictRatio * 0.20 +
              detourRatio * 0.13 +
              greedyAnalysis.failureRatio * 0.22 +
              endpointCongestionRatio * 0.06 +
              chokePointRatio * 0.06 +
              boardDistributionRatio * 0.09 +
              naturalCoverageRatio * 0.08 +
              shortcutTrapRatio * 0.12 +
              kShortestAnalysis.routeConflictRatio * 0.10 +
              kShortestAnalysis.misleadingRouteRatio * 0.14 +
              kShortestAnalysis.alternativeDiversity * 0.04 +
              (kShortestAnalysis.easyJointCompletionFound ? 0 : 0.06)) +
      ((rows * columns - 36) / 64).clamp(0, 1) * 12;
  return ThemedLevelDifficulty(
    score: score,
    interiorEndpointRatio: interiorRatio,
    cornerEndpointRatio: cornerRatio,
    alignedPairRatio: alignedRatio,
    distanceRatio: distanceRatio,
    routeConflictRatio: conflictRatio,
    detourRatio: detourRatio,
    turnRatio: turnRatio,
    greedyFailureRatio: greedyAnalysis.failureRatio,
    greedyCoverageRatio: greedyAnalysis.coverageRatio,
    endpointCongestionRatio: endpointCongestionRatio,
    chokePointRatio: chokePointRatio,
    boardDistributionRatio: boardDistributionRatio,
    naturalCoverageRatio: naturalCoverageRatio,
    endpointDemandRatio: endpointDemandRatio,
    shortcutTrapRatio: shortcutTrapRatio,
    kShortestRouteConflictRatio: kShortestAnalysis.routeConflictRatio,
    misleadingRouteRatio: kShortestAnalysis.misleadingRouteRatio,
    alternativeRouteDiversity: kShortestAnalysis.alternativeDiversity,
    easyJointCompletionFound: kShortestAnalysis.easyJointCompletionFound,
  );
}

const int _difficultyRouteOptionCount = 4;
const int _difficultyRouteStateBudget = 900;
const int _difficultyJointBeamWidth = 24;

_KShortestDifficultyAnalysis _analyzeKShortestRoutes(
  List<List<BoardPosition>> intendedPaths,
  List<_EndpointPair> pairs, {
  required int rows,
  required int columns,
}) {
  if (pairs.isEmpty) {
    return const _KShortestDifficultyAnalysis.empty();
  }

  final endpoints = {
    for (final pair in pairs) ...[pair.source, pair.target],
  };
  final routeOptions = <List<List<BoardPosition>>>[];
  for (final pair in pairs) {
    final blocked = <BoardPosition>{...endpoints}
      ..remove(pair.source)
      ..remove(pair.target);
    routeOptions.add(
      _kShortestAvailableRoutes(
        pair.source,
        pair.target,
        blocked: blocked,
        rows: rows,
        columns: columns,
        routeLimit: _difficultyRouteOptionCount,
        maxExtraSteps: 6,
        maxExploredStates: _difficultyRouteStateBudget,
      ),
    );
  }

  final routeCellOptions = [
    for (var pairIndex = 0; pairIndex < pairs.length; pairIndex += 1)
      [
        for (final route in routeOptions[pairIndex])
          route
              .where(
                (cell) =>
                    cell != pairs[pairIndex].source &&
                    cell != pairs[pairIndex].target,
              )
              .toSet(),
      ],
  ];

  final strongestConflictByPair = List<double>.filled(pairs.length, 0);
  for (var firstIndex = 0; firstIndex < pairs.length; firstIndex += 1) {
    for (
      var secondIndex = firstIndex + 1;
      secondIndex < pairs.length;
      secondIndex += 1
    ) {
      final firstRoutes = routeCellOptions[firstIndex];
      final secondRoutes = routeCellOptions[secondIndex];
      if (firstRoutes.isEmpty || secondRoutes.isEmpty) {
        continue;
      }
      var conflicts = 0;
      for (final firstRoute in firstRoutes) {
        for (final secondRoute in secondRoutes) {
          if (firstRoute.intersection(secondRoute).isNotEmpty) {
            conflicts += 1;
          }
        }
      }
      final strength = conflicts / (firstRoutes.length * secondRoutes.length);
      strongestConflictByPair[firstIndex] = math.max(
        strongestConflictByPair[firstIndex],
        strength,
      );
      strongestConflictByPair[secondIndex] = math.max(
        strongestConflictByPair[secondIndex],
        strength,
      );
    }
  }

  var temptingRouteCount = 0;
  var misleadingRouteCount = 0;
  for (var pairIndex = 0; pairIndex < pairs.length; pairIndex += 1) {
    for (
      var routeIndex = 0;
      routeIndex < routeOptions[pairIndex].length;
      routeIndex += 1
    ) {
      final route = routeOptions[pairIndex][routeIndex];
      if (route.length >= intendedPaths[pairIndex].length) {
        continue;
      }
      temptingRouteCount += 1;
      final occupied = routeCellOptions[pairIndex][routeIndex];
      final blocksAnotherPair = routeCellOptions.indexed.any((entry) {
        final (otherIndex, otherRoutes) = entry;
        return otherIndex != pairIndex &&
            otherRoutes.isNotEmpty &&
            otherRoutes.every(
              (otherRoute) => occupied.intersection(otherRoute).isNotEmpty,
            );
      });
      if (blocksAnotherPair) {
        misleadingRouteCount += 1;
      }
    }
  }

  final diversity =
      routeOptions
          .map(
            (routes) =>
                ((routes.length - 1) / (_difficultyRouteOptionCount - 1)).clamp(
                  0,
                  1,
                ),
          )
          .reduce((total, value) => total + value) /
      routeOptions.length;
  final conflictRatio =
      strongestConflictByPair.reduce((total, value) => total + value) /
      strongestConflictByPair.length;

  return _KShortestDifficultyAnalysis(
    routeConflictRatio: conflictRatio,
    misleadingRouteRatio: temptingRouteCount == 0
        ? 0
        : misleadingRouteCount / temptingRouteCount,
    alternativeDiversity: diversity,
    easyJointCompletionFound: _hasEasyJointRouteCompletion(
      routeCellOptions,
      beamWidth: _difficultyJointBeamWidth,
    ),
  );
}

List<List<BoardPosition>> _kShortestAvailableRoutes(
  BoardPosition source,
  BoardPosition target, {
  required Set<BoardPosition> blocked,
  required int rows,
  required int columns,
  required int routeLimit,
  required int maxExtraSteps,
  required int maxExploredStates,
}) {
  final distanceToTarget = _distanceMap(
    target,
    blocked: blocked,
    rows: rows,
    columns: columns,
  );
  final shortestDistance = distanceToTarget[source];
  if (shortestDistance == null) {
    return const [];
  }

  final routes = <List<BoardPosition>>[];
  final signatures = <String>{};
  var exploredStates = 0;
  final maximumDistance = shortestDistance + maxExtraSteps;
  for (
    var targetDistance = shortestDistance;
    targetDistance <= maximumDistance &&
        routes.length < routeLimit &&
        exploredStates < maxExploredStates;
    targetDistance += 2
  ) {
    final path = <BoardPosition>[source];
    final visited = <BoardPosition>{source};

    void search(BoardPosition current) {
      if (routes.length >= routeLimit || exploredStates >= maxExploredStates) {
        return;
      }
      exploredStates += 1;
      final usedEdges = path.length - 1;
      final remainingDistance = distanceToTarget[current];
      if (remainingDistance == null ||
          usedEdges + remainingDistance > targetDistance) {
        return;
      }
      if (current == target) {
        if (usedEdges == targetDistance) {
          final signature = path
              .map((cell) => '${cell.row},${cell.column}')
              .join(';');
          if (signatures.add(signature)) {
            routes.add(List<BoardPosition>.unmodifiable(path));
          }
        }
        return;
      }

      final candidates =
          _neighbors(current, rows: rows, columns: columns).where((next) {
            return !blocked.contains(next) && !visited.contains(next);
          }).toList()..sort((first, second) {
            final distanceOrder = (distanceToTarget[first] ?? rows * columns)
                .compareTo(distanceToTarget[second] ?? rows * columns);
            if (distanceOrder != 0) {
              return distanceOrder;
            }
            final rowOrder = first.row.compareTo(second.row);
            return rowOrder != 0
                ? rowOrder
                : first.column.compareTo(second.column);
          });
      for (final next in candidates) {
        path.add(next);
        visited.add(next);
        search(next);
        visited.remove(next);
        path.removeLast();
        if (routes.length >= routeLimit ||
            exploredStates >= maxExploredStates) {
          return;
        }
      }
    }

    search(source);
  }
  return routes;
}

Map<BoardPosition, int> _distanceMap(
  BoardPosition target, {
  required Set<BoardPosition> blocked,
  required int rows,
  required int columns,
}) {
  final distances = <BoardPosition, int>{target: 0};
  final queue = <BoardPosition>[target];
  var cursor = 0;
  while (cursor < queue.length) {
    final current = queue[cursor++];
    for (final next in _neighbors(current, rows: rows, columns: columns)) {
      if (blocked.contains(next) || distances.containsKey(next)) {
        continue;
      }
      distances[next] = distances[current]! + 1;
      queue.add(next);
    }
  }
  return distances;
}

bool _hasEasyJointRouteCompletion(
  List<List<Set<BoardPosition>>> routeOptions, {
  required int beamWidth,
}) {
  if (routeOptions.any((routes) => routes.isEmpty)) {
    return false;
  }
  final pairOrder =
      [for (var index = 0; index < routeOptions.length; index++) index]..sort(
        (first, second) =>
            routeOptions[first].length.compareTo(routeOptions[second].length),
      );
  var beam = <Set<BoardPosition>>[<BoardPosition>{}];
  for (final pairIndex in pairOrder) {
    final nextBeam = <Set<BoardPosition>>[];
    final seen = <String>{};
    for (final occupied in beam) {
      for (final route in routeOptions[pairIndex]) {
        if (occupied.intersection(route).isNotEmpty) {
          continue;
        }
        final combined = <BoardPosition>{...occupied, ...route};
        final signature = combined.toList()
          ..sort((first, second) {
            final rowOrder = first.row.compareTo(second.row);
            return rowOrder != 0
                ? rowOrder
                : first.column.compareTo(second.column);
          });
        final key = signature
            .map((cell) => '${cell.row},${cell.column}')
            .join(';');
        if (seen.add(key)) {
          nextBeam.add(combined);
        }
      }
    }
    if (nextBeam.isEmpty) {
      return false;
    }
    nextBeam.sort((first, second) => first.length.compareTo(second.length));
    beam = nextBeam.take(beamWidth).toList();
  }
  return beam.isNotEmpty;
}

double _shortcutTrapRatio(
  List<List<BoardPosition>> paths,
  List<_EndpointPair> pairs, {
  required int rows,
  required int columns,
}) {
  if (paths.isEmpty) {
    return 0;
  }

  final allEndpoints = {
    for (final pair in pairs) ...[pair.source, pair.target],
  };
  var trappedPairs = 0;
  for (var index = 0; index < paths.length; index += 1) {
    final path = paths[index];
    final pair = pairs[index];
    final blockedEndpoints = <BoardPosition>{...allEndpoints}
      ..remove(pair.source)
      ..remove(pair.target);
    final shortestRoute = _shortestAvailableRoute(
      pair.source,
      pair.target,
      blocked: blockedEndpoints,
      rows: rows,
      columns: columns,
    );
    if (shortestRoute != null && shortestRoute.length < path.length) {
      trappedPairs += 1;
    }
  }
  return trappedPairs / paths.length;
}

double _endpointDemandRatio(
  List<_EndpointPair> pairs, {
  required int rows,
  required int columns,
}) {
  if (pairs.isEmpty || rows * columns == 0) {
    return 0;
  }
  final allEndpoints = {
    for (final pair in pairs) ...[pair.source, pair.target],
  };
  var naturallyRequiredCells = 0;
  for (final pair in pairs) {
    final blockedEndpoints = <BoardPosition>{...allEndpoints}
      ..remove(pair.source)
      ..remove(pair.target);
    final route = _shortestAvailableRoute(
      pair.source,
      pair.target,
      blocked: blockedEndpoints,
      rows: rows,
      columns: columns,
    );
    if (route == null) {
      return 0;
    }
    naturallyRequiredCells += route.length;
  }
  return (naturallyRequiredCells / (rows * columns)).clamp(0, 1);
}

int _maximumPathExcessCells(List<List<BoardPosition>> paths) {
  var maximumExcess = 0;
  for (final path in paths) {
    final directCells = _manhattanDistance(path.first, path.last) + 1;
    maximumExcess = math.max(maximumExcess, path.length - directCells);
  }
  return maximumExcess;
}

double _naturalCoverageRatio(
  List<List<BoardPosition>> paths, {
  required int rows,
  required int columns,
}) {
  if (paths.isEmpty) {
    return 0;
  }

  final boardScale = math.max(2.0, math.min(rows, columns) * 0.40);
  final pathScores = paths.map((path) {
    if (path.length < 2) {
      return 0.0;
    }
    final turnDensity = _pathTurnRatio(path);
    var turnCount = 0;
    for (var index = 2; index < path.length; index += 1) {
      final previousDirection = (
        path[index - 1].row - path[index - 2].row,
        path[index - 1].column - path[index - 2].column,
      );
      final direction = (
        path[index].row - path[index - 1].row,
        path[index].column - path[index - 1].column,
      );
      if (direction != previousDirection) {
        turnCount += 1;
      }
    }
    final averageStraightRun = (path.length - 1) / (turnCount + 1);
    final runEconomy = (averageStraightRun / boardScale).clamp(0, 1);
    return (1 - turnDensity) * 0.65 + runEconomy * 0.35;
  });
  return pathScores.reduce((total, score) => total + score) / paths.length;
}

double _boardDistributionRatio(
  List<BoardPosition> endpoints, {
  required int rows,
  required int columns,
}) {
  if (endpoints.isEmpty) {
    return 0;
  }

  final minimumRow = endpoints.map((position) => position.row).reduce(math.min);
  final maximumRow = endpoints.map((position) => position.row).reduce(math.max);
  final minimumColumn = endpoints
      .map((position) => position.column)
      .reduce(math.min);
  final maximumColumn = endpoints
      .map((position) => position.column)
      .reduce(math.max);
  final rowSpan = rows <= 1 ? 1.0 : (maximumRow - minimumRow) / (rows - 1);
  final columnSpan = columns <= 1
      ? 1.0
      : (maximumColumn - minimumColumn) / (columns - 1);

  final occupiedRegions = <(int, int)>{
    for (final endpoint in endpoints)
      (
        math.min(2, endpoint.row * 3 ~/ rows),
        math.min(2, endpoint.column * 3 ~/ columns),
      ),
  };
  final reachableRegionCount = math.min(9, endpoints.length);
  final regionCoverage = occupiedRegions.length / reachableRegionCount;

  return ((rowSpan + columnSpan) / 2 * 0.65 + regionCoverage * 0.35).clamp(
    0,
    1,
  );
}

double _endpointCongestionRatio(List<_EndpointPair> pairs) {
  if (pairs.length < 2) {
    return 0;
  }

  final indexedEndpoints = <({BoardPosition position, int pairIndex})>[
    for (var pairIndex = 0; pairIndex < pairs.length; pairIndex += 1) ...[
      (position: pairs[pairIndex].source, pairIndex: pairIndex),
      (position: pairs[pairIndex].target, pairIndex: pairIndex),
    ],
  ];
  var congestedEndpoints = 0;
  for (final endpoint in indexedEndpoints) {
    final nearbyForeignEndpoints = indexedEndpoints.where((other) {
      return other.pairIndex != endpoint.pairIndex &&
          _manhattanDistance(endpoint.position, other.position) <= 2;
    }).length;
    if (nearbyForeignEndpoints >= 2) {
      congestedEndpoints += 1;
    }
  }
  return congestedEndpoints / indexedEndpoints.length;
}

double _chokePointRatio(List<_EndpointPair> pairs) {
  if (pairs.length < 2) {
    return 0;
  }

  final endpoints = {
    for (final pair in pairs) ...[pair.source, pair.target],
  };
  final pairMembershipByCell = <BoardPosition, Set<int>>{};
  for (var pairIndex = 0; pairIndex < pairs.length; pairIndex += 1) {
    for (final route in _shortestRouteOptions(pairs[pairIndex])) {
      for (final cell in route) {
        if (endpoints.contains(cell)) {
          continue;
        }
        pairMembershipByCell.putIfAbsent(cell, () => <int>{}).add(pairIndex);
      }
    }
  }

  var maximumCompetingPairCount = 0;
  for (final membership in pairMembershipByCell.values) {
    maximumCompetingPairCount = math.max(
      maximumCompetingPairCount,
      membership.length,
    );
  }
  return maximumCompetingPairCount / pairs.length;
}

bool _hasInternalShortestRouteChoke(
  List<List<BoardPosition>> paths, {
  required int rows,
  required int columns,
}) {
  if (paths.length < 2) {
    return false;
  }

  final endpointPairs = [
    for (final path in paths) _canonicalEndpointPair(path.first, path.last),
  ];
  final endpoints = {
    for (final pair in endpointPairs) ...[pair.source, pair.target],
  };
  final pairMembershipByCell = <BoardPosition, Set<int>>{};
  for (var pairIndex = 0; pairIndex < endpointPairs.length; pairIndex += 1) {
    for (final route in _shortestRouteOptions(endpointPairs[pairIndex])) {
      for (final cell in route) {
        if (endpoints.contains(cell) || !_isInterior(cell, rows, columns)) {
          continue;
        }
        pairMembershipByCell.putIfAbsent(cell, () => <int>{}).add(pairIndex);
      }
    }
  }

  return pairMembershipByCell.values.any(
    (membership) => membership.length >= 2,
  );
}

double _shortestRouteConflictRatio(List<_EndpointPair> pairs) {
  if (pairs.length < 2) {
    return 0;
  }

  final strongestConflictByPair = List<double>.filled(pairs.length, 0);
  for (var firstIndex = 0; firstIndex < pairs.length; firstIndex += 1) {
    final firstOptions = _shortestRouteOptions(pairs[firstIndex]);
    for (
      var secondIndex = firstIndex + 1;
      secondIndex < pairs.length;
      secondIndex += 1
    ) {
      final secondOptions = _shortestRouteOptions(pairs[secondIndex]);
      var intersectingCombinations = 0;
      for (final firstRoute in firstOptions) {
        for (final secondRoute in secondOptions) {
          if (firstRoute.intersection(secondRoute).isNotEmpty) {
            intersectingCombinations += 1;
          }
        }
      }
      final conflictStrength =
          intersectingCombinations /
          (firstOptions.length * secondOptions.length);
      strongestConflictByPair[firstIndex] = math.max(
        strongestConflictByPair[firstIndex],
        conflictStrength,
      );
      strongestConflictByPair[secondIndex] = math.max(
        strongestConflictByPair[secondIndex],
        conflictStrength,
      );
    }
  }
  return strongestConflictByPair.reduce((total, value) => total + value) /
      strongestConflictByPair.length;
}

List<Set<BoardPosition>> _shortestRouteOptions(_EndpointPair pair) {
  return [
    _orthogonalRoute(pair.source, pair.target, horizontalFirst: true),
    _orthogonalRoute(pair.source, pair.target, horizontalFirst: false),
  ];
}

Set<BoardPosition> _orthogonalRoute(
  BoardPosition source,
  BoardPosition target, {
  required bool horizontalFirst,
}) {
  final corner = horizontalFirst
      ? BoardPosition(row: source.row, column: target.column)
      : BoardPosition(row: target.row, column: source.column);
  return {..._straightCells(source, corner), ..._straightCells(corner, target)};
}

Iterable<BoardPosition> _straightCells(
  BoardPosition source,
  BoardPosition target,
) sync* {
  final rowStep = target.row.compareTo(source.row);
  final columnStep = target.column.compareTo(source.column);
  var current = source;
  yield current;
  while (current != target) {
    current = BoardPosition(
      row: current.row + rowStep,
      column: current.column + columnStep,
    );
    yield current;
  }
}

double _pathTurnRatio(List<BoardPosition> path) {
  if (path.length < 3) {
    return 0;
  }
  var turns = 0;
  for (var index = 2; index < path.length; index += 1) {
    final previousRowDelta = path[index - 1].row - path[index - 2].row;
    final previousColumnDelta = path[index - 1].column - path[index - 2].column;
    final rowDelta = path[index].row - path[index - 1].row;
    final columnDelta = path[index].column - path[index - 1].column;
    if (previousRowDelta != rowDelta || previousColumnDelta != columnDelta) {
      turns += 1;
    }
  }
  return turns / (path.length - 2);
}

({double failureRatio, double coverageRatio}) _analyzeGreedyRoutes(
  List<_EndpointPair> pairs, {
  required int rows,
  required int columns,
}) {
  if (pairs.isEmpty) {
    return (failureRatio: 0, coverageRatio: 0);
  }
  final orders = <List<int>>[];
  final natural = [for (var index = 0; index < pairs.length; index += 1) index];
  final reversed = natural.reversed.toList();
  for (
    var offset = 0;
    offset < pairs.length && orders.length < 4;
    offset += 1
  ) {
    orders.add([...natural.skip(offset), ...natural.take(offset)]);
    if (orders.length < 4) {
      orders.add([...reversed.skip(offset), ...reversed.take(offset)]);
    }
  }
  orders
    ..add(
      [...natural]..sort(
        (first, second) =>
            _manhattanDistance(
              pairs[first].source,
              pairs[first].target,
            ).compareTo(
              _manhattanDistance(pairs[second].source, pairs[second].target),
            ),
      ),
    )
    ..add(
      [...natural]..sort(
        (first, second) =>
            _manhattanDistance(
              pairs[second].source,
              pairs[second].target,
            ).compareTo(
              _manhattanDistance(pairs[first].source, pairs[first].target),
            ),
      ),
    );

  final results = [
    for (final order in orders)
      _evaluateGreedyRouteOrder(
        pairs,
        order: order,
        rows: rows,
        columns: columns,
      ),
  ];
  final failedOrders = results.where((result) => !result.connected).length;
  final averageCoverage =
      results
          .map((result) => result.coverageRatio)
          .reduce((total, value) => total + value) /
      results.length;
  return (
    failureRatio: failedOrders / results.length,
    coverageRatio: averageCoverage,
  );
}

_GreedyRouteResult _evaluateGreedyRouteOrder(
  List<_EndpointPair> pairs, {
  required List<int> order,
  required int rows,
  required int columns,
}) {
  final allEndpoints = {
    for (final pair in pairs) ...[pair.source, pair.target],
  };
  final occupied = <BoardPosition>{};

  for (final pairIndex in order) {
    final pair = pairs[pairIndex];
    final blocked = <BoardPosition>{...allEndpoints, ...occupied}
      ..remove(pair.source)
      ..remove(pair.target);
    final route = _shortestAvailableRoute(
      pair.source,
      pair.target,
      blocked: blocked,
      rows: rows,
      columns: columns,
    );
    if (route == null) {
      return _GreedyRouteResult(
        connected: false,
        coverageRatio: occupied.length / (rows * columns),
      );
    }
    occupied.addAll(route);
  }
  return _GreedyRouteResult(
    connected: true,
    coverageRatio: occupied.length / (rows * columns),
  );
}

List<BoardPosition>? _shortestAvailableRoute(
  BoardPosition source,
  BoardPosition target, {
  required Set<BoardPosition> blocked,
  required int rows,
  required int columns,
}) {
  final queue = <BoardPosition>[source];
  final previous = <BoardPosition, BoardPosition?>{source: null};
  var cursor = 0;

  while (cursor < queue.length) {
    final current = queue[cursor];
    cursor += 1;
    if (current == target) {
      final route = <BoardPosition>[];
      BoardPosition? position = target;
      while (position != null) {
        route.add(position);
        position = previous[position];
      }
      return route.reversed.toList();
    }

    for (final next in _neighbors(current, rows: rows, columns: columns)) {
      if (blocked.contains(next) || previous.containsKey(next)) {
        continue;
      }
      previous[next] = current;
      queue.add(next);
    }
  }
  return null;
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

bool _isInterior(BoardPosition position, int rows, int columns) {
  return position.row > 0 &&
      position.row < rows - 1 &&
      position.column > 0 &&
      position.column < columns - 1;
}

bool _isCorner(BoardPosition position, int rows, int columns) {
  final isOuterRow = position.row == 0 || position.row == rows - 1;
  final isOuterColumn = position.column == 0 || position.column == columns - 1;
  return isOuterRow && isOuterColumn;
}

bool _isBoundary(BoardPosition position, int rows, int columns) {
  return position.row == 0 ||
      position.row == rows - 1 ||
      position.column == 0 ||
      position.column == columns - 1;
}

int _manhattanDistance(BoardPosition first, BoardPosition second) {
  return (first.row - second.row).abs() + (first.column - second.column).abs();
}

_EndpointPair _canonicalEndpointPair(
  BoardPosition first,
  BoardPosition second,
) {
  final firstComesFirst =
      first.row < second.row ||
      (first.row == second.row && first.column <= second.column);
  return firstComesFirst
      ? _EndpointPair(source: first, target: second)
      : _EndpointPair(source: second, target: first);
}

int _stableSeed(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}

List<List<BoardPosition>> _partitionTraversalIntoPaths({
  required List<BoardPosition> traversal,
  required int pairCount,
  math.Random? random,
  double variation = 0,
}) {
  var plannedLengths = _planPathLengths(
    traversal: traversal,
    pairCount: pairCount,
  );
  if (random != null && variation > 0) {
    plannedLengths = _varyPathLengths(
      traversal: traversal,
      plannedLengths: plannedLengths,
      random: random,
      variation: variation,
    );
  }
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

List<int> _varyPathLengths({
  required List<BoardPosition> traversal,
  required List<int> plannedLengths,
  required math.Random random,
  required double variation,
}) {
  final varied = List<int>.of(plannedLengths);
  final averageLength = traversal.length / varied.length;
  final maximumLength = math.max(4, (averageLength * 2.2).round());
  final targetChanges = (varied.length * 5 * variation).round();
  var acceptedChanges = 0;
  var attempts = 0;

  while (acceptedChanges < targetChanges && attempts < targetChanges * 18) {
    attempts += 1;
    final donorIndex = random.nextInt(varied.length);
    var receiverIndex = random.nextInt(varied.length);
    if (receiverIndex == donorIndex) {
      receiverIndex = (receiverIndex + 1) % varied.length;
    }
    if (varied[donorIndex] <= 3 || varied[receiverIndex] >= maximumLength) {
      continue;
    }

    varied[donorIndex] -= 1;
    varied[receiverIndex] += 1;
    if (_areAllSegmentsInteresting(traversal, varied)) {
      acceptedChanges += 1;
    } else {
      varied[donorIndex] += 1;
      varied[receiverIndex] -= 1;
    }
  }

  return List<int>.unmodifiable(varied);
}

bool _areAllSegmentsInteresting(
  List<BoardPosition> traversal,
  List<int> lengths,
) {
  var cursor = 0;
  for (final length in lengths) {
    if (!_isInterestingSegment(traversal, cursor, length)) {
      return false;
    }
    cursor += length;
  }
  return cursor == traversal.length;
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
    failedStates: <(int, int)>{},
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
  required Set<(int, int)> failedStates,
}) {
  final pathIndex = planned.length;
  final state = (pathIndex, cursor);
  if (failedStates.contains(state)) {
    return false;
  }
  final remainingPaths = pairCount - pathIndex;
  final remainingCells = traversal.length - cursor;
  const minimumPathLength = 3;

  if (remainingPaths == 1) {
    if (_isInterestingSegment(traversal, cursor, remainingCells)) {
      planned.add(remainingCells);
      return true;
    }
    failedStates.add(state);
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
      failedStates: failedStates,
    )) {
      return true;
    }
    planned.removeLast();
  }

  failedStates.add(state);
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

  static const _boardShapeRecipe = <_BoardShape>[
    _BoardShape(rows: 5, columns: 5),
    _BoardShape(rows: 6, columns: 6),
    _BoardShape(rows: 6, columns: 6),
    _BoardShape(rows: 7, columns: 6),
    _BoardShape(rows: 8, columns: 6),
    _BoardShape(rows: 8, columns: 7),
    _BoardShape(rows: 9, columns: 7),
    _BoardShape(rows: 10, columns: 7),
    _BoardShape(rows: 10, columns: 8),
    _BoardShape(rows: 11, columns: 8),
    _BoardShape(rows: 12, columns: 8),
    _BoardShape(rows: 12, columns: 8),
    _BoardShape(rows: 13, columns: 8),
    _BoardShape(rows: 13, columns: 8),
    _BoardShape(rows: 14, columns: 8),
  ];

  factory _LevelBlueprint.forLevel({
    required int levelNumber,
    required int totalLevelCount,
    required int relationshipCount,
    required ThemeBoardProfile profile,
    required ThemedLevelProgression progression,
  }) {
    if (totalLevelCount == 20) {
      final band = ((levelNumber.clamp(1, 20) - 1) ~/ 5).clamp(0, 3);
      final size = 5 + band;
      return _LevelBlueprint(
        levelNumber: levelNumber,
        rows: size,
        columns: size,
        pairCount: 3 + band,
      );
    }
    if (progression == ThemedLevelProgression.chaptered) {
      return _chapteredBlueprint(
        levelNumber: levelNumber,
        totalLevelCount: totalLevelCount,
        relationshipCount: relationshipCount,
        profile: profile,
      );
    }

    final progress = totalLevelCount <= 1
        ? 1.0
        : (levelNumber - 1) / (totalLevelCount - 1);
    final boardShape = _boardShapeForLevel(
      levelNumber: levelNumber,
      totalLevelCount: totalLevelCount,
      profile: profile,
    );
    final pairCount = _scaledValue(
      start: 3,
      end: profile.maxPairs,
      progress: progress,
    ).clamp(3, math.min(profile.maxPairs, relationshipCount)).toInt();

    return _LevelBlueprint(
      levelNumber: levelNumber,
      rows: boardShape.rows,
      columns: boardShape.columns,
      pairCount: math.min(pairCount, boardShape.rows * boardShape.columns ~/ 6),
    );
  }

  static _LevelBlueprint _chapteredBlueprint({
    required int levelNumber,
    required int totalLevelCount,
    required int relationshipCount,
    required ThemeBoardProfile profile,
  }) {
    final progress = totalLevelCount <= 1
        ? 1.0
        : (levelNumber - 1) / (totalLevelCount - 1);
    final levelInChapter = (levelNumber - 1) % 10;
    final isBossLevel = levelInChapter == 9;
    final isRecoveryLevel = levelInChapter == 7;

    final maximumSize = math.min(
      math.min(profile.maxRows, profile.maxColumns),
      math.min(profile.maxPairs, relationshipCount),
    );
    var boardSize = _scaledValue(
      start: 6,
      end: maximumSize,
      progress: progress,
    );
    if (isBossLevel) {
      boardSize += 1;
    } else if (isRecoveryLevel) {
      boardSize -= 1;
    }
    boardSize = boardSize.clamp(6, maximumSize);
    final pairCount = levelNumber == 1
        ? 4
        : boardSize == 6
        ? 5
        : boardSize;

    return _LevelBlueprint(
      levelNumber: levelNumber,
      rows: boardSize,
      columns: boardSize,
      pairCount: pairCount,
    );
  }

  static _BoardShape _boardShapeForLevel({
    required int levelNumber,
    required int totalLevelCount,
    required ThemeBoardProfile profile,
  }) {
    final lastRecipeIndex = _boardShapeRecipe.length - 1;
    final recipeIndex = totalLevelCount <= 1
        ? lastRecipeIndex
        : ((levelNumber - 1) * lastRecipeIndex / (totalLevelCount - 1))
              .round()
              .clamp(0, lastRecipeIndex);
    final recipe = _boardShapeRecipe[recipeIndex];

    if (recipe.rows == recipe.columns) {
      final squareLimit = math.min(profile.maxRows, profile.maxColumns);
      final size = recipe.rows.clamp(5, squareLimit);
      return _BoardShape(rows: size, columns: size);
    }

    return _BoardShape(
      rows: _scaleRecipeDimension(
        value: recipe.rows,
        recipeEnd: 14,
        profileEnd: profile.maxRows,
      ),
      columns: recipe.columns.clamp(5, profile.maxColumns),
    );
  }

  static int _scaleRecipeDimension({
    required int value,
    required int recipeEnd,
    required int profileEnd,
  }) {
    if (recipeEnd <= 5 || profileEnd <= 5) {
      return 5;
    }
    final progress = (value - 5) / (recipeEnd - 5);
    return _scaledValue(start: 5, end: profileEnd, progress: progress);
  }

  static int _scaledValue({
    required int start,
    required int end,
    required double progress,
  }) {
    return (start + (end - start) * progress).round().clamp(start, end);
  }
}

class _BoardShape {
  const _BoardShape({required this.rows, required this.columns});

  final int rows;
  final int columns;
}

class _PathLayoutCandidate {
  const _PathLayoutCandidate({
    required this.paths,
    required this.difficulty,
    this.isStructuralChoke = false,
  });

  final List<List<BoardPosition>> paths;
  final ThemedLevelDifficulty difficulty;
  final bool isStructuralChoke;
}

class _EndpointPair {
  const _EndpointPair({required this.source, required this.target});

  final BoardPosition source;
  final BoardPosition target;
}

class _GreedyRouteResult {
  const _GreedyRouteResult({
    required this.connected,
    required this.coverageRatio,
  });

  final bool connected;
  final double coverageRatio;
}

class _KShortestDifficultyAnalysis {
  const _KShortestDifficultyAnalysis({
    required this.routeConflictRatio,
    required this.misleadingRouteRatio,
    required this.alternativeDiversity,
    required this.easyJointCompletionFound,
  });

  const _KShortestDifficultyAnalysis.empty()
    : routeConflictRatio = 0,
      misleadingRouteRatio = 0,
      alternativeDiversity = 0,
      easyJointCompletionFound = false;

  final double routeConflictRatio;
  final double misleadingRouteRatio;
  final double alternativeDiversity;
  final bool easyJointCompletionFound;
}
