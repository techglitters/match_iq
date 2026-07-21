import 'package:flutter/material.dart';

enum LevelStatus { locked, unlocked, current, completed }

class LevelNode extends StatelessWidget {
  const LevelNode({
    required this.levelNumber,
    required this.status,
    required this.stars,
    required this.onTap,
    required this.isCurrent,
    super.key,
  });

  final int levelNumber;
  final LevelStatus status;
  final int stars;
  final VoidCallback? onTap;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = _NodeColors.forStatus(status, Theme.of(context).colorScheme);
    final label = switch (status) {
      LevelStatus.completed => 'Level $levelNumber, completed, $stars stars',
      LevelStatus.current => 'Level $levelNumber, current level',
      LevelStatus.unlocked => 'Level $levelNumber, unlocked',
      LevelStatus.locked => 'Level $levelNumber, locked',
    };

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.96, end: isCurrent ? 1.05 : 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Material(
              color: colors.fill,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 3),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: colors.border.withValues(alpha: 0.24),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: status == LevelStatus.locked
                      ? Icon(Icons.lock_rounded, color: colors.content)
                      : Text(
                          '$levelNumber',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colors.content,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 1; index <= 3; index += 1)
                Icon(
                  index <= stars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 16,
                  color: status == LevelStatus.locked
                      ? Colors.grey
                      : const Color(0xFFFFB300),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NodeColors {
  const _NodeColors({
    required this.fill,
    required this.border,
    required this.content,
  });

  final Color fill;
  final Color border;
  final Color content;

  static _NodeColors forStatus(LevelStatus status, ColorScheme colorScheme) {
    return switch (status) {
      LevelStatus.completed => _NodeColors(
        fill: const Color(0xFF4CAF50),
        border: const Color(0xFF2E7D32),
        content: colorScheme.onPrimary,
      ),
      LevelStatus.current => _NodeColors(
        fill: colorScheme.primary,
        border: const Color(0xFF1565C0),
        content: colorScheme.onPrimary,
      ),
      LevelStatus.unlocked => _NodeColors(
        fill: Colors.white.withValues(alpha: 0.92),
        border: colorScheme.primary.withValues(alpha: 0.45),
        content: colorScheme.onSurface,
      ),
      LevelStatus.locked => _NodeColors(
        fill: Colors.grey.shade200.withValues(alpha: 0.82),
        border: Colors.grey.shade400,
        content: Colors.grey.shade600,
      ),
    };
  }
}
