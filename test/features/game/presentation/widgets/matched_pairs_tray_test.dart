import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_iq/features/game/data/nature_levels.dart';
import 'package:match_iq/features/game/domain/models/level_solution.dart';
import 'package:match_iq/features/game/presentation/controllers/game_controller.dart';
import 'package:match_iq/features/game/presentation/widgets/matched_pairs_tray.dart';

void main() {
  testWidgets('shows newest completed pair first in lifo order', (
    tester,
  ) async {
    final level = createNatureLevel(levelNumber: 1);
    final controller = GameController(initialLevel: level);
    final firstSolution = level.solutions[0];
    final secondSolution = level.solutions[1];
    final firstRelationship = level.pairs
        .firstWhere(
          (pair) => pair.relationship.id == firstSolution.relationshipId,
        )
        .relationship;
    final secondRelationship = level.pairs
        .firstWhere(
          (pair) => pair.relationship.id == secondSolution.relationshipId,
        )
        .relationship;

    _completeSolution(controller, firstSolution);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MatchedPairsTray(controller: controller)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    _completeSolution(controller, secondSolution);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final firstLabel =
        '${firstRelationship.source.name} - ${firstRelationship.target.name}';
    final secondLabel =
        '${secondRelationship.source.name} - ${secondRelationship.target.name}';

    expect(find.text(firstLabel), findsOneWidget);
    expect(find.text(secondLabel), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(secondLabel)).dx,
      lessThan(tester.getTopLeft(find.text(firstLabel)).dx),
    );
  });
}

void _completeSolution(GameController controller, LevelSolution solution) {
  controller.startPath(solution.cells.first);
  for (final cell in solution.cells.skip(1)) {
    controller.extendPath(cell);
  }
  controller.finishPath();
}
