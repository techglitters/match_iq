import 'package:flutter_test/flutter_test.dart';
import 'package:match_iq/core/persistence/memory_progress_store.dart';
import 'package:match_iq/features/game/data/nature_levels.dart';
import 'package:match_iq/features/game/data/nature_relationships.dart';
import 'package:match_iq/features/game/domain/models/board_position.dart';
import 'package:match_iq/features/game/domain/models/game_level.dart';
import 'package:match_iq/features/game/domain/models/game_path.dart';
import 'package:match_iq/features/game/domain/models/learning_relationship.dart';
import 'package:match_iq/features/game/domain/models/level_pair_placement.dart';
import 'package:match_iq/features/game/presentation/controllers/game_controller.dart';
import 'package:match_iq/features/themes/data/theme_catalog.dart';
import 'package:match_iq/features/themes/presentation/controllers/app_progress_controller.dart';

void main() {
  group('Nature levels', () {
    test('contains exactly 15 deterministic levels', () {
      final levels = createNatureLevels();

      expect(levels, hasLength(15));
      expect(levels.first.rows, 4);
      expect(levels.first.columns, 4);
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

    test('all known solutions validate', () {
      expect(NatureLevels.validateAll(), isEmpty);
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

  group('AppProgressController', () {
    test(
      'first launch defaults to Nature World and level 1 unlocked',
      () async {
        final controller = _progressController();

        await controller.load();

        expect(controller.activeTheme.id, ThemeCatalog.natureThemeId);
        expect(controller.highestUnlockedLevel(ThemeCatalog.natureThemeId), 1);
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
      await controller.selectTheme(ThemeCatalog.natureThemeId);

      final restored = _progressController(store);
      await restored.load();

      expect(restored.activeTheme.id, ThemeCatalog.natureThemeId);
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
