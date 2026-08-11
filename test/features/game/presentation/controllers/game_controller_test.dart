import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:match_iq/core/constants/game_constants.dart';
import 'package:match_iq/core/persistence/memory_progress_store.dart';
import 'package:match_iq/features/daily/data/daily_puzzle_catalog.dart';
import 'package:match_iq/features/daily/domain/daily_puzzle_challenge.dart';
import 'package:match_iq/features/daily/domain/daily_puzzle_result.dart';
import 'package:match_iq/features/game/data/animal_levels.dart';
import 'package:match_iq/features/game/data/animal_relationships.dart';
import 'package:match_iq/features/game/data/nature_levels.dart';
import 'package:match_iq/features/game/data/nature_relationships.dart';
import 'package:match_iq/features/game/data/themed_level_builder.dart';
import 'package:match_iq/features/game/domain/models/board_position.dart';
import 'package:match_iq/features/game/domain/models/game_level.dart';
import 'package:match_iq/features/game/domain/models/game_path.dart';
import 'package:match_iq/features/game/domain/models/learning_relationship.dart';
import 'package:match_iq/features/game/domain/models/level_pair_placement.dart';
import 'package:match_iq/features/game/presentation/controllers/game_controller.dart';
import 'package:match_iq/features/themes/data/theme_catalog.dart';
import 'package:match_iq/features/themes/domain/app_progress_data.dart';
import 'package:match_iq/features/themes/domain/theme_progress.dart';
import 'package:match_iq/features/themes/presentation/controllers/app_progress_controller.dart';

void main() {
  group('Nature levels', () {
    test('contains exactly 15 deterministic levels', () {
      final levels = createNatureLevels();

      expect(levels, hasLength(15));
      expect(levels.first.rows, 5);
      expect(levels.first.columns, 5);
      expect(levels.first.pairs, hasLength(3));
      expect(levels.last.rows, 14);
      expect(levels.last.columns, 8);
      expect(levels.last.pairs, hasLength(10));
    });

    test('uses nature-only relationships', () {
      for (final relationship in NatureRelationships.all) {
        expect(relationship.category, RelationshipCategory.nature);
      }
    });

    test('uses visually distinct relationship colors', () {
      _expectDistinctRelationshipColors(NatureRelationships.all);
    });

    test('all known solutions validate', () {
      expect(NatureLevels.validateAll(), isEmpty);
    });

    test('known solutions use the whole grid and spread endpoints', () {
      for (final generatedLevel in createGeneratedNatureLevels()) {
        final level = generatedLevel.level;
        final usedCells = <BoardPosition>{
          for (final path in generatedLevel.solutionPaths.values) ...path.cells,
        };
        final straightEndpointPairs = level.pairs.where((pair) {
          return pair.sourcePosition.row == pair.targetPosition.row ||
              pair.sourcePosition.column == pair.targetPosition.column;
        }).length;

        expect(usedCells.length, level.rows * level.columns);
        expect(straightEndpointPairs, lessThan(level.pairs.length ~/ 2));
      }
    });

    test('known solution paths complete every level', () {
      for (final generatedLevel in createGeneratedNatureLevels()) {
        final controller = GameController(initialLevel: generatedLevel.level);

        _completeGeneratedLevel(controller, generatedLevel);

        expect(
          controller.connectedPairCount,
          generatedLevel.level.pairs.length,
        );
        expect(controller.isLevelComplete, isTrue);
      }
    });

    test('star calculation is move based', () {
      final level = createNatureLevel(levelNumber: 5);

      expect(level.starsForMoves(level.threeStarMoveTarget), 3);
      expect(level.starsForMoves(level.twoStarMoveTarget), 2);
      expect(level.starsForMoves(level.twoStarMoveTarget + 1), 1);
    });
  });

  group('Animal levels', () {
    test('contains exactly 15 deterministic levels', () {
      final levels = createAnimalLevels();

      expect(levels, hasLength(15));
      expect(levels.first.rows, 5);
      expect(levels.first.columns, 5);
      expect(levels.first.pairs, hasLength(3));
      expect(levels.last.rows, 14);
      expect(levels.last.columns, 8);
      expect(levels.last.pairs, hasLength(10));
    });

    test('uses animal-only relationships', () {
      for (final relationship in AnimalRelationships.all) {
        expect(relationship.category, RelationshipCategory.animals);
      }
    });

    test('uses visually distinct relationship colors', () {
      _expectDistinctRelationshipColors(AnimalRelationships.all);
    });

    test('all known solutions validate', () {
      expect(AnimalLevels.validateAll(), isEmpty);
    });

    test('known solutions use the whole grid and spread endpoints', () {
      for (final generatedLevel in createGeneratedAnimalLevels()) {
        final level = generatedLevel.level;
        final usedCells = <BoardPosition>{
          for (final path in generatedLevel.solutionPaths.values) ...path.cells,
        };
        final straightEndpointPairs = level.pairs.where((pair) {
          return pair.sourcePosition.row == pair.targetPosition.row ||
              pair.sourcePosition.column == pair.targetPosition.column;
        }).length;

        expect(usedCells.length, level.rows * level.columns);
        expect(straightEndpointPairs, lessThan(level.pairs.length ~/ 2));
      }
    });

    test('known solution paths complete every level', () {
      for (final generatedLevel in createGeneratedAnimalLevels()) {
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

  group('DailyPuzzleCatalog', () {
    test('rotates available themes with deterministic recipes', () {
      final themes = [ThemeCatalog.natureWorld, ThemeCatalog.animalWorld];

      final firstDay = DailyPuzzleCatalog.challengeForDate(
        themes: themes,
        date: DateTime(2026),
      );
      final secondDay = DailyPuzzleCatalog.challengeForDate(
        themes: themes,
        date: DateTime(2026, 1, 2),
      );
      final fifthDay = DailyPuzzleCatalog.challengeForDate(
        themes: themes,
        date: DateTime(2026, 1, 5),
      );

      expect(firstDay.theme.id, ThemeCatalog.natureThemeId);
      expect(firstDay.difficulty, DailyPuzzleDifficulty.easy);
      expect(firstDay.modifier, DailyPuzzleModifier.steady);
      expect(secondDay.theme.id, ThemeCatalog.animalThemeId);
      expect(fifthDay.difficulty, DailyPuzzleDifficulty.medium);
      expect(fifthDay.modifier, DailyPuzzleModifier.longRoute);
    });

    test('daily levels validate across rotating themes', () {
      final themes = [ThemeCatalog.natureWorld, ThemeCatalog.animalWorld];

      for (var offset = 0; offset < 42; offset += 1) {
        final challenge = DailyPuzzleCatalog.challengeForDate(
          themes: themes,
          date: DateTime(2026).add(Duration(days: offset)),
        );

        expect(
          validateThemedLevelSolutions(challenge.level),
          isEmpty,
          reason: 'Daily ${challenge.dateKey} should be solvable.',
        );
      }
    });
  });

  group('AppProgressController', () {
    test(
      'first launch defaults to Nature World and level 1 unlocked',
      () async {
        final controller = _progressController();

        await controller.load();

        expect(controller.activeTheme.id, ThemeCatalog.natureThemeId);
        expect(controller.highestUnlockedLevel(ThemeCatalog.natureThemeId), 1);
        expect(controller.highestUnlockedLevel(ThemeCatalog.animalThemeId), 1);
        expect(controller.hasPlayedLevel, isFalse);
      },
    );

    test('opening a level persists last played level', () async {
      final store = MemoryProgressStore();
      final controller = _progressController(store);

      await controller.load();
      await controller.recordLevelOpened(
        themeId: ThemeCatalog.natureThemeId,
        levelNumber: 1,
      );

      final restored = _progressController(store);
      await restored.load();

      expect(restored.hasPlayedLevel, isTrue);
      expect(restored.continueLevelNumber(), 1);
    });

    test('completing Level 1 unlocks Level 2', () async {
      final controller = _progressController();
      await controller.load();

      final result = await controller.completeLevel(
        themeId: ThemeCatalog.natureThemeId,
        levelNumber: 1,
        moves: 3,
      );

      expect(result.earnedStars, 3);
      expect(controller.highestUnlockedLevel(ThemeCatalog.natureThemeId), 2);
      expect(controller.isLevelUnlocked(ThemeCatalog.natureThemeId, 2), isTrue);
    });

    test('replay does not reduce stars or replace better move count', () async {
      final controller = _progressController();
      await controller.load();

      await controller.completeLevel(
        themeId: ThemeCatalog.natureThemeId,
        levelNumber: 1,
        moves: 3,
      );
      await controller.completeLevel(
        themeId: ThemeCatalog.natureThemeId,
        levelNumber: 1,
        moves: 10,
      );

      final progress = controller
          .progressForTheme(ThemeCatalog.natureThemeId)
          .levelProgress(1);
      expect(progress.stars, 3);
      expect(progress.bestMoves, 3);
    });

    test('active theme persists', () async {
      final store = MemoryProgressStore();
      final controller = _progressController(store);

      await controller.load();
      await controller.selectTheme(ThemeCatalog.animalThemeId);

      final restored = _progressController(store);
      await restored.load();

      expect(restored.activeTheme.id, ThemeCatalog.animalThemeId);
    });

    test('solution path visibility persists', () async {
      final store = MemoryProgressStore();
      final controller = _progressController(store);

      await controller.load();
      expect(controller.showSolutionPaths, isFalse);

      await controller.setShowSolutionPaths(true);

      final restored = _progressController(store);
      await restored.load();

      expect(restored.showSolutionPaths, isTrue);
      expect(
        AppProgressData.fromJson(restored.data.toJson()).showSolutionPaths,
        isTrue,
      );
    });

    test(
      'daily puzzle completion persists without changing continue level',
      () async {
        final controller = _progressController(
          MemoryProgressStore(
            const AppProgressData(
              activeThemeId: 'nature',
              lastPlayedThemeId: null,
              lastPlayedLevelNumber: null,
              hasSeenHome: true,
              themes: {
                'nature': ThemeProgress(highestUnlockedLevel: 3, levels: {}),
                'animals': ThemeProgress.initial(),
              },
            ),
          ),
        );
        await controller.load();
        await controller.recordLevelOpened(
          themeId: ThemeCatalog.natureThemeId,
          levelNumber: 3,
        );

        await controller.completeDailyPuzzle(
          dateKey: '2026-07-22',
          themeId: ThemeCatalog.natureThemeId,
          levelNumber: 5,
          earnedStars: 2,
          moves: 8,
        );

        final dailyResult = controller.dailyPuzzleResult(
          date: DateTime(2026, 7, 22),
        );
        expect(dailyResult.completed, isTrue);
        expect(dailyResult.stars, 2);
        expect(dailyResult.bestMoves, 8);
        expect(controller.continueLevelNumber(), 3);
      },
    );

    test('daily replay result keeps best stars and moves', () async {
      final controller = _progressController();
      await controller.load();

      await controller.completeDailyPuzzle(
        dateKey: '2026-07-22',
        themeId: ThemeCatalog.natureThemeId,
        levelNumber: 5,
        earnedStars: 3,
        moves: 4,
      );
      await controller.completeDailyPuzzle(
        dateKey: '2026-07-22',
        themeId: ThemeCatalog.natureThemeId,
        levelNumber: 5,
        earnedStars: 1,
        moves: 10,
      );

      final result = controller.dailyPuzzleResult(date: DateTime(2026, 7, 22));
      expect(result.stars, 3);
      expect(result.moves, 10);
      expect(result.bestMoves, 4);
    });

    test('daily history reports solved days and streaks', () async {
      final controller = _progressController(
        MemoryProgressStore(
          const AppProgressData(
            activeThemeId: 'nature',
            lastPlayedThemeId: null,
            lastPlayedLevelNumber: null,
            hasSeenHome: true,
            themes: {
              'nature': ThemeProgress.initial(),
              'animals': ThemeProgress.initial(),
            },
            dailyPuzzles: {
              '2026-07-20': DailyPuzzleResult(
                dateKey: '2026-07-20',
                themeId: 'nature',
                levelNumber: 1,
                completed: true,
                stars: 2,
                moves: 5,
                bestMoves: 5,
              ),
              '2026-07-21': DailyPuzzleResult(
                dateKey: '2026-07-21',
                themeId: 'animals',
                levelNumber: 2,
                completed: true,
                stars: 3,
                moves: 4,
                bestMoves: 4,
              ),
              '2026-07-22': DailyPuzzleResult(
                dateKey: '2026-07-22',
                themeId: 'nature',
                levelNumber: 3,
                completed: true,
                stars: 1,
                moves: 8,
                bestMoves: 8,
              ),
            },
          ),
        ),
      );

      await controller.load();

      final history = controller.dailyPuzzleHistory(
        days: 3,
        today: DateTime(2026, 7, 22),
      );
      expect(history, hasLength(3));
      expect(history.first.dateKey, '2026-07-22');
      expect(history.first.isCompleted, isTrue);
      expect(history.last.dateKey, '2026-07-20');
      expect(controller.dailyStreak(today: DateTime(2026, 7, 22)), 3);
      expect(controller.bestDailyStreak(), 3);
    });
  });

  group('GameController', () {
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

    test(
      'diagonal movement is rejected and orthogonal movement is accepted',
      () {
        final controller = GameController(initialLevel: _ruleLevel);

        controller.startPath(const BoardPosition(row: 0, column: 0));

        expect(
          controller.extendPath(const BoardPosition(row: 1, column: 1)),
          isFalse,
        );
        expect(
          controller.extendPath(const BoardPosition(row: 0, column: 1)),
          isTrue,
        );
      },
    );

    test('backtracking removes the latest cell', () {
      final controller = GameController(initialLevel: _ruleLevel);

      controller.startPath(const BoardPosition(row: 0, column: 0));
      controller.extendPath(const BoardPosition(row: 0, column: 1));
      controller.extendPath(const BoardPosition(row: 0, column: 0));

      expect(controller.activePath, [const BoardPosition(row: 0, column: 0)]);
    });

    test('wrong endpoint rejects the path', () {
      final controller = GameController(initialLevel: _ruleLevel);

      controller.startPath(const BoardPosition(row: 0, column: 0));
      controller.extendPath(const BoardPosition(row: 0, column: 1));

      final rejectedPath = controller.rejectWrongEndpoint(
        const BoardPosition(row: 1, column: 1),
      );

      expect(rejectedPath, isNotNull);
      expect(controller.completedPaths, isEmpty);
      expect(controller.moves, 1);
    });

    test('correct adjacent endpoint saves without a detour', () {
      final controller = GameController(initialLevel: _adjacentEndpointLevel);

      controller.startPath(const BoardPosition(row: 0, column: 0));
      controller.extendPath(const BoardPosition(row: 0, column: 1));

      expect(controller.finishPath(), isTrue);
      expect(controller.completedPaths, contains('seed_to_flower'));
    });

    test('active path cannot extend past a reached endpoint', () {
      final controller = GameController(initialLevel: _adjacentEndpointLevel);

      controller.startPath(const BoardPosition(row: 0, column: 0));
      expect(
        controller.extendPath(const BoardPosition(row: 0, column: 1)),
        isTrue,
      );

      expect(
        controller.extendPath(const BoardPosition(row: 0, column: 2)),
        isFalse,
      );
      expect(controller.activePath, [
        const BoardPosition(row: 0, column: 0),
        const BoardPosition(row: 0, column: 1),
      ]);
    });

    test('entering a completed path middle cuts it and continues', () {
      final controller = GameController(initialLevel: _cutRuleLevel);
      final completedPath = GamePath(
        relationshipId: NatureRelationships.treeToFruit.id,
        cells: const [
          BoardPosition(row: 1, column: 0),
          BoardPosition(row: 1, column: 1),
          BoardPosition(row: 1, column: 2),
        ],
        isComplete: true,
      );

      _completeGamePath(controller, completedPath);
      expect(
        controller.completedPaths,
        contains(NatureRelationships.treeToFruit.id),
      );

      expect(
        controller.startPath(const BoardPosition(row: 0, column: 1)),
        isTrue,
      );
      final cutPath = controller.cutCompletedPathAtAndExtend(
        const BoardPosition(row: 1, column: 1),
      );

      expect(cutPath?.relationshipId, NatureRelationships.treeToFruit.id);
      expect(
        controller.completedPaths,
        isNot(contains(NatureRelationships.treeToFruit.id)),
      );
      expect(controller.activePath, [
        const BoardPosition(row: 0, column: 1),
        const BoardPosition(row: 1, column: 1),
      ]);
    });

    test('rectangular 14x8 level is accepted', () {
      final level = createNatureLevel(levelNumber: 15);
      final controller = GameController(initialLevel: level);

      expect(controller.level.rows, 14);
      expect(controller.level.columns, 8);
      expect(controller.totalPairCount, 10);
    });
  });
}

AppProgressController _progressController([MemoryProgressStore? store]) {
  return AppProgressController(
    store: store ?? MemoryProgressStore(),
    themes: ThemeCatalog.all,
  );
}

GeneratedNatureLevel _generatedLevel() {
  return generateNatureLevel(levelNumber: 1, pairCount: 3);
}

const _ruleLevel = GameLevel(
  id: 'rule_test',
  name: 'Rule Test',
  rows: 4,
  columns: 4,
  pairs: [
    LevelPairPlacement(
      relationship: NatureRelationships.seedToFlower,
      sourcePosition: BoardPosition(row: 0, column: 0),
      targetPosition: BoardPosition(row: 0, column: 2),
    ),
    LevelPairPlacement(
      relationship: NatureRelationships.treeToFruit,
      sourcePosition: BoardPosition(row: 1, column: 1),
      targetPosition: BoardPosition(row: 2, column: 1),
    ),
  ],
);

const _adjacentEndpointLevel = GameLevel(
  id: 'adjacent_endpoint_rule_test',
  name: 'Adjacent Endpoint Rule Test',
  rows: 4,
  columns: 4,
  pairs: [
    LevelPairPlacement(
      relationship: NatureRelationships.seedToFlower,
      sourcePosition: BoardPosition(row: 0, column: 0),
      targetPosition: BoardPosition(row: 0, column: 1),
    ),
  ],
);

const _cutRuleLevel = GameLevel(
  id: 'cut_rule_test',
  name: 'Cut Rule Test',
  rows: 4,
  columns: 4,
  pairs: [
    LevelPairPlacement(
      relationship: NatureRelationships.seedToFlower,
      sourcePosition: BoardPosition(row: 0, column: 1),
      targetPosition: BoardPosition(row: 3, column: 1),
    ),
    LevelPairPlacement(
      relationship: NatureRelationships.treeToFruit,
      sourcePosition: BoardPosition(row: 1, column: 0),
      targetPosition: BoardPosition(row: 1, column: 2),
    ),
  ],
);

void _completeGeneratedLevel(
  GameController controller,
  GeneratedNatureLevel generatedLevel,
) {
  for (final path in generatedLevel.solutionPaths.values) {
    _completeGamePath(controller, path);
  }
}

void _completeGamePath(GameController controller, GamePath path) {
  expect(controller.startPath(path.cells.first), isTrue);
  for (final position in path.cells.skip(1)) {
    expect(controller.extendPath(position), isTrue);
  }
  expect(controller.finishPath(), isTrue);
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
  throw StateError('Expected a non-endpoint cell.');
}

void _expectDistinctRelationshipColors(
  List<LearningRelationship> relationships,
) {
  final colorValues = [
    for (final relationship in relationships)
      GameConstants.colorForRelationship(relationship.id).toARGB32(),
  ];

  expect(colorValues.toSet(), hasLength(colorValues.length));

  for (var first = 0; first < relationships.length; first += 1) {
    for (var second = first + 1; second < relationships.length; second += 1) {
      expect(
        _rgbDistance(colorValues[first], colorValues[second]),
        greaterThanOrEqualTo(80),
        reason:
            '${relationships[first].id} and ${relationships[second].id} need '
            'more visual separation.',
      );
    }
  }
}

double _rgbDistance(int first, int second) {
  final firstRed = (first >> 16) & 0xff;
  final firstGreen = (first >> 8) & 0xff;
  final firstBlue = first & 0xff;
  final secondRed = (second >> 16) & 0xff;
  final secondGreen = (second >> 8) & 0xff;
  final secondBlue = second & 0xff;

  final redDelta = firstRed - secondRed;
  final greenDelta = firstGreen - secondGreen;
  final blueDelta = firstBlue - secondBlue;
  return math.sqrt(
    redDelta * redDelta + greenDelta * greenDelta + blueDelta * blueDelta,
  );
}
