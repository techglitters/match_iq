import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../controllers/game_controller.dart';
import '../widgets/game_board.dart';
import '../widgets/game_bottom_controls.dart';
import '../widgets/game_header.dart';
import '../widgets/level_complete_dialog.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<GameController>(
          builder: (context, controller, _) {
            _showCompleteDialogIfNeeded(controller);

            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                children: [
                  GameHeader(controller: controller),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: const GameBoard(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GameBottomControls(
                    canUndo: controller.completedPathOrder.isNotEmpty,
                    onUndo: controller.undoLastPath,
                    onRestart: () {
                      controller.restartLevel();
                      if (_dialogShown) {
                        setState(() => _dialogShown = false);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCompleteDialogIfNeeded(GameController controller) {
    if (!controller.isLevelComplete || _dialogShown) {
      return;
    }

    _dialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return LevelCompleteDialog(
            moves: controller.moves,
            onPlayAgain: () {
              Navigator.of(dialogContext).pop();
              controller.restartLevel();
              if (mounted) {
                setState(() => _dialogShown = false);
              }
            },
            onNextLevel: controller.hasNextLevel
                ? () {
                    Navigator.of(dialogContext).pop();
                    controller.goToNextLevel();
                    if (mounted) {
                      setState(() => _dialogShown = false);
                    }
                  }
                : null,
            onHome: () {
              Navigator.of(dialogContext).pop();
              if (!mounted) {
                return;
              }
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
            },
          );
        },
      );
    });
  }
}
