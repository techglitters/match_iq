import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';

class GameHeader extends StatelessWidget {
  const GameHeader({
    required this.controller,
    required this.onBack,
    this.subtitle,
    super.key,
  });

  final GameController controller;
  final VoidCallback onBack;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final instruction =
        controller.allPairsConnected && !controller.isBoardFilled
        ? '${controller.remainingCellCount} cells still need a path'
        : subtitle ?? 'Connect every pair and fill the board';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.82),
                foregroundColor: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.level.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      instruction,
                      key: ValueKey<String>(instruction),
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _HeaderPill(
                label: 'Pairs',
                value:
                    '${controller.connectedPairCount}/${controller.totalPairCount}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HeaderPill(
                label: 'Board',
                value: '${controller.coveragePercent}%',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HeaderPill(label: 'Moves', value: '${controller.moves}'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Text(
                value,
                key: ValueKey<String>('$label-$value'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
