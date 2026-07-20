import 'package:flutter/material.dart';

class GameBottomControls extends StatelessWidget {
  const GameBottomControls({
    required this.canUndo,
    required this.onUndo,
    required this.onRestart,
    super.key,
  });

  final bool canUndo;
  final VoidCallback? onUndo;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canUndo ? onUndo : null,
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Undo'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Restart'),
          ),
        ),
      ],
    );
  }
}
