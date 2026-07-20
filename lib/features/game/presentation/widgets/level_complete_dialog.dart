import 'package:flutter/material.dart';

class LevelCompleteDialog extends StatelessWidget {
  const LevelCompleteDialog({
    required this.moves,
    required this.onPlayAgain,
    required this.onHome,
    this.onNextLevel,
    super.key,
  });

  final int moves;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;
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
      title: const Text('Well Done!'),
      content: Text(
        'You connected all pairs.\nMoves: $moves',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton.icon(
          onPressed: onHome,
          icon: const Icon(Icons.home_rounded),
          label: const Text('Home'),
        ),
        if (onNextLevel == null) ...[
          FilledButton.icon(
            onPressed: onPlayAgain,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Play Again'),
          ),
        ] else ...[
          TextButton.icon(
            onPressed: onPlayAgain,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Play Again'),
          ),
          FilledButton.icon(
            onPressed: onNextLevel,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next Level'),
          ),
        ],
      ],
    );
  }
}
