import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../themes/data/theme_catalog.dart';
import '../../../themes/domain/level_completion_result.dart';
import '../../../themes/presentation/controllers/app_progress_controller.dart';
import '../controllers/game_controller.dart';
import '../widgets/game_board.dart';
import '../widgets/game_header.dart';
import '../widgets/level_complete_dialog.dart';
import '../widgets/matched_pairs_tray.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.themeId,
    required this.levelNumber,
    this.isDailyPuzzle = false,
    this.isDailyReplay = false,
    this.dailyPuzzleId,
    this.dailySubtitle,
    super.key,
  });

  final String themeId;
  final int levelNumber;
  final bool isDailyPuzzle;
  final bool isDailyReplay;
  final String? dailyPuzzleId;
  final String? dailySubtitle;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _dialogShown = false;
  bool _savingCompletion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.isDailyPuzzle) {
        return;
      }
      context.read<AppProgressController>().recordLevelOpened(
        themeId: widget.themeId,
        levelNumber: widget.levelNumber,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        context.watch<AppProgressController>().themeById(widget.themeId) ??
        ThemeCatalog.natureWorld;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<GameController>(
          builder: (context, controller, _) {
            _showCompleteDialogIfNeeded(controller, themeName: theme.name);

            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: [
                  GameHeader(
                    controller: controller,
                    onBack: () => Navigator.of(context).pushReplacementNamed(
                      widget.isDailyPuzzle
                          ? widget.isDailyReplay
                                ? AppRoutes.dailyHistory
                                : AppRoutes.home
                          : AppRoutes.themeLevels(theme.id),
                    ),
                    subtitle: widget.isDailyPuzzle
                        ? widget.dailySubtitle
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _BoardHost(controller: controller)),
                  const SizedBox(height: 10),
                  MatchedPairsTray(controller: controller),
                  if (controller.completedPathOrder.isNotEmpty)
                    const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCompleteDialogIfNeeded(
    GameController controller, {
    required String themeName,
  }) {
    if (!controller.isLevelComplete || _dialogShown || _savingCompletion) {
      return;
    }

    _dialogShown = true;
    _savingCompletion = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appProgress = context.read<AppProgressController>();
      final dailyPuzzleId =
          widget.dailyPuzzleId ?? appProgress.dailyPuzzleDateKey();
      final earnedStars = controller.level.starsForMoves(controller.moves);
      final result = widget.isDailyReplay
          ? LevelCompletionResult(
              levelNumber: widget.levelNumber,
              earnedStars: earnedStars,
              savedStars: earnedStars,
              moves: controller.moves,
              bestMoves: controller.moves,
              unlockedLevel: widget.levelNumber,
              isThemeComplete: false,
            )
          : widget.isDailyPuzzle
          ? await appProgress.completeDailyPuzzle(
              dateKey: dailyPuzzleId,
              themeId: widget.themeId,
              levelNumber: widget.levelNumber,
              earnedStars: earnedStars,
              moves: controller.moves,
            )
          : await appProgress.completeLevel(
              themeId: widget.themeId,
              levelNumber: widget.levelNumber,
              moves: controller.moves,
            );
      _savingCompletion = false;

      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return LevelCompleteDialog(
            result: result,
            themeName: themeName,
            isDailyPuzzle: widget.isDailyPuzzle,
            isDailyReplay: widget.isDailyReplay,
            dailySubtitle: widget.dailySubtitle,
            showLevelMapAction: !widget.isDailyPuzzle,
            onPlayAgain: () {
              Navigator.of(dialogContext).pop();
              controller.restartLevel();
              if (mounted) {
                setState(() => _dialogShown = false);
              }
            },
            onNextLevel: !widget.isDailyPuzzle && _canOpenNext(result)
                ? () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.themeLevel(
                        widget.themeId,
                        widget.levelNumber + 1,
                      ),
                    );
                  }
                : null,
            onLevelMap: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushReplacementNamed(
                widget.isDailyPuzzle
                    ? AppRoutes.dailyHistory
                    : AppRoutes.themeLevels(widget.themeId),
              );
            },
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

  bool _canOpenNext(LevelCompletionResult result) {
    return !result.isThemeComplete && result.unlockedLevel > widget.levelNumber;
  }
}

class _BoardHost extends StatelessWidget {
  const _BoardHost({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = controller.level.columns / controller.level.rows;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 560
            ? 560.0
            : constraints.maxWidth;
        var boardWidth = maxWidth;
        var boardHeight = boardWidth / aspectRatio;

        if (boardHeight > constraints.maxHeight) {
          boardHeight = constraints.maxHeight;
          boardWidth = boardHeight * aspectRatio;
        }

        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: const GameBoard(),
          ),
        );
      },
    );
  }
}
