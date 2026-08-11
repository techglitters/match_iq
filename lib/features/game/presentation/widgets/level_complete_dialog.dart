import 'package:flutter/material.dart';

import '../../../themes/domain/level_completion_result.dart';

class LevelCompleteDialog extends StatelessWidget {
  const LevelCompleteDialog({
    required this.result,
    required this.themeName,
    required this.onPlayAgain,
    required this.onLevelMap,
    required this.onHome,
    this.isDailyPuzzle = false,
    this.isDailyReplay = false,
    this.dailySubtitle,
    this.showLevelMapAction = true,
    this.onNextLevel,
    super.key,
  });

  final LevelCompletionResult result;
  final String themeName;
  final VoidCallback onPlayAgain;
  final VoidCallback onLevelMap;
  final VoidCallback onHome;
  final bool isDailyPuzzle;
  final bool isDailyReplay;
  final String? dailySubtitle;
  final bool showLevelMapAction;
  final VoidCallback? onNextLevel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.celebration_rounded,
        color: colorScheme.primary,
        size: 42,
      ),
      title: Text(_titleText),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StarRow(stars: result.earnedStars),
          const SizedBox(height: 14),
          Text(_bodyText, textAlign: TextAlign.center),
          if (dailySubtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              dailySubtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
          Text('Moves: ${result.moves}'),
          Text('Best: ${result.bestMoves}'),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton.icon(
          onPressed: onHome,
          icon: const Icon(Icons.home_rounded),
          label: const Text('Home'),
        ),
        if (showLevelMapAction)
          TextButton.icon(
            onPressed: onLevelMap,
            icon: const Icon(Icons.map_rounded),
            label: const Text('Map'),
          ),
        FilledButton.icon(
          onPressed: onNextLevel ?? onPlayAgain,
          icon: Icon(
            onNextLevel == null
                ? Icons.replay_rounded
                : Icons.arrow_forward_rounded,
          ),
          label: Text(onNextLevel == null ? 'Replay' : 'Next Level'),
        ),
      ],
    );
  }

  String get _titleText {
    if (isDailyReplay) {
      return 'Replay Complete!';
    }
    if (isDailyPuzzle) {
      return 'Daily Complete!';
    }
    return result.isThemeComplete ? '$themeName Complete!' : 'Wonderful!';
  }

  String get _bodyText {
    if (isDailyReplay) {
      return 'Nice practice run. Your saved daily score stayed unchanged.';
    }
    if (isDailyPuzzle) {
      return "You solved today's puzzle. Come back tomorrow for a new one.";
    }
    return 'You connected all pairs!';
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 1; index <= 3; index += 1)
          Icon(
            index <= stars ? Icons.star_rounded : Icons.star_border_rounded,
            color: const Color(0xFFFFB300),
            size: 34,
          ),
      ],
    );
  }
}
