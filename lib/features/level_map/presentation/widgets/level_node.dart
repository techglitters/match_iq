import 'package:flutter/material.dart';

enum LevelStatus { locked, unlocked, current, completed }

class LevelNodeVisual {
  const LevelNodeVisual({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class LevelNode extends StatefulWidget {
  const LevelNode({
    required this.levelNumber,
    required this.status,
    required this.stars,
    required this.onTap,
    required this.isCurrent,
    this.showLockIcon = true,
    this.visual,
    super.key,
  });

  final int levelNumber;
  final LevelStatus status;
  final int stars;
  final VoidCallback? onTap;
  final bool isCurrent;
  final bool showLockIcon;
  final LevelNodeVisual? visual;

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800 + widget.levelNumber * 70),
    );
  }

  @override
  void didUpdateWidget(covariant LevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMotion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  void _updateMotion() {
    final mediaQuery = MediaQuery.maybeOf(context);
    final reducedMotion =
        mediaQuery?.disableAnimations ??
        mediaQuery?.accessibleNavigation ??
        false;
    final shouldAnimate = widget.visual != null && !reducedMotion;
    if (shouldAnimate && !_motionController.isAnimating) {
      _motionController.repeat(reverse: true);
    } else if (!shouldAnimate && _motionController.isAnimating) {
      _motionController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _NodeColors.forStatus(
      widget.status,
      Theme.of(context).colorScheme,
    );
    final visual = widget.visual;
    final levelDescription = visual == null
        ? 'Level ${widget.levelNumber}'
        : 'Level ${widget.levelNumber}, ${visual.label}';
    final label = switch (widget.status) {
      LevelStatus.completed =>
        '$levelDescription, completed, ${widget.stars} stars',
      LevelStatus.current => '$levelDescription, current level',
      LevelStatus.unlocked => '$levelDescription, unlocked',
      LevelStatus.locked => '$levelDescription, locked',
    };

    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.96, end: widget.isCurrent ? 1.05 : 1.0),
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
                onTap: widget.onTap,
                child: Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 3),
                    boxShadow: widget.isCurrent
                        ? [
                            BoxShadow(
                              color: colors.border.withValues(alpha: 0.24),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: _NodeContent(
                    colors: colors,
                    levelNumber: widget.levelNumber,
                    motion: _motionController,
                    showLockIcon: widget.showLockIcon,
                    status: widget.status,
                    visual: visual,
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
                  index <= widget.stars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 16,
                  color: widget.status == LevelStatus.locked
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

class _NodeContent extends StatelessWidget {
  const _NodeContent({
    required this.colors,
    required this.levelNumber,
    required this.motion,
    required this.showLockIcon,
    required this.status,
    required this.visual,
  });

  final _NodeColors colors;
  final int levelNumber;
  final Animation<double> motion;
  final bool showLockIcon;
  final LevelStatus status;
  final LevelNodeVisual? visual;

  @override
  Widget build(BuildContext context) {
    final visual = this.visual;
    if (visual == null) {
      return status == LevelStatus.locked && showLockIcon
          ? Icon(Icons.lock_rounded, color: colors.content)
          : Text(
              '$levelNumber',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.content,
                fontWeight: FontWeight.w900,
              ),
            );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: motion,
          builder: (context, child) {
            final value = Curves.easeInOut.transform(motion.value);
            return Transform.translate(
              offset: Offset(0, -1.8 * value),
              child: Transform.scale(scale: 1 + value * 0.045, child: child),
            );
          },
          child: Icon(
            visual.icon,
            color: colors.content,
            size: 34,
            semanticLabel: visual.label,
          ),
        ),
        if (status == LevelStatus.locked && showLockIcon)
          Positioned(
            right: 9,
            bottom: 9,
            child: Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade400.withValues(alpha: 0.78),
                ),
              ),
              child: Icon(Icons.lock_rounded, color: colors.content, size: 12),
            ),
          ),
      ],
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
