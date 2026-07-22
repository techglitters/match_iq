import 'package:flutter/material.dart';

import '../../../../core/constants/game_constants.dart';
import '../../domain/models/learning_relationship.dart';
import '../controllers/game_controller.dart';

class MatchedPairsTray extends StatefulWidget {
  const MatchedPairsTray({required this.controller, super.key});

  final GameController controller;

  @override
  State<MatchedPairsTray> createState() => _MatchedPairsTrayState();
}

class _MatchedPairsTrayState extends State<MatchedPairsTray> {
  final _listKey = GlobalKey<AnimatedListState>();
  late List<LearningRelationship> _relationships;

  @override
  void initState() {
    super.initState();
    _relationships = _completedRelationships(widget.controller);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant MatchedPairsTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller.removeListener(_handleControllerChanged);
    _relationships = _completedRelationships(widget.controller);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        height: _relationships.isEmpty ? 0 : 82,
        child: AnimatedList(
          key: _listKey,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          initialItemCount: _relationships.length,
          itemBuilder: (context, index, animation) {
            final relationship = _relationships[index];
            return _AnimatedMatchedPairTile(
              key: ValueKey('matched_pair_${relationship.id}'),
              relationship: relationship,
              animation: animation,
            );
          },
        ),
      ),
    );
  }

  void _handleControllerChanged() {
    final desiredRelationships = _completedRelationships(widget.controller);
    final desiredIds = {
      for (final relationship in desiredRelationships) relationship.id,
    };

    for (var index = _relationships.length - 1; index >= 0; index -= 1) {
      final relationship = _relationships[index];
      if (desiredIds.contains(relationship.id)) {
        continue;
      }

      _relationships.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _AnimatedMatchedPairTile(
          relationship: relationship,
          animation: animation,
          isRemoving: true,
        ),
        duration: const Duration(milliseconds: 260),
      );
    }

    for (
      var targetIndex = 0;
      targetIndex < desiredRelationships.length;
      targetIndex += 1
    ) {
      final relationship = desiredRelationships[targetIndex];
      final currentIndex = _relationships.indexWhere(
        (currentRelationship) => currentRelationship.id == relationship.id,
      );
      if (currentIndex == -1) {
        _relationships.insert(targetIndex, relationship);
        _listKey.currentState?.insertItem(
          targetIndex,
          duration: const Duration(milliseconds: 460),
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  List<LearningRelationship> _completedRelationships(
    GameController controller,
  ) {
    final pairsById = {
      for (final pair in controller.level.pairs) pair.relationship.id: pair,
    };

    return [
      for (final relationshipId in controller.completedPathOrder.reversed)
        if (pairsById[relationshipId] != null)
          pairsById[relationshipId]!.relationship,
    ];
  }
}

class _AnimatedMatchedPairTile extends StatelessWidget {
  const _AnimatedMatchedPairTile({
    required this.relationship,
    required this.animation,
    this.isRemoving = false,
    super.key,
  });

  final LearningRelationship relationship;
  final Animation<double> animation;
  final bool isRemoving;

  @override
  Widget build(BuildContext context) {
    final size = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    final fade = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    final motion = animation.drive(
      CurveTween(curve: isRemoving ? Curves.easeInCubic : Curves.easeOutBack),
    );

    return SizeTransition(
      axis: Axis.horizontal,
      axisAlignment: -1,
      sizeFactor: size,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: motion.drive(
            Tween<Offset>(
              begin: Offset(isRemoving ? 0 : -0.18, isRemoving ? 0 : -0.14),
              end: Offset.zero,
            ),
          ),
          child: ScaleTransition(
            scale: motion.drive(Tween<double>(begin: 0.86, end: 1)),
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _MatchedPairChip(relationship: relationship),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchedPairChip extends StatelessWidget {
  const _MatchedPairChip({required this.relationship});

  final LearningRelationship relationship;

  @override
  Widget build(BuildContext context) {
    final color = GameConstants.colorForRelationship(relationship.id);
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );

    return Semantics(
      label:
          'Completed pair, ${relationship.source.name} connected to '
          '${relationship.target.name}',
      child: Container(
        width: 206,
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.42), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MatchedPairIcon(
                  icon: relationship.source.icon,
                  color: color,
                  label: relationship.source.name,
                ),
                _MatchedPairConnector(color: color),
                _MatchedPairIcon(
                  icon: relationship.target.icon,
                  color: color,
                  label: relationship.target.name,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '${relationship.source.name} - ${relationship.target.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchedPairIcon extends StatelessWidget {
  const _MatchedPairIcon({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.56), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
    );
  }
}

class _MatchedPairConnector extends StatelessWidget {
  const _MatchedPairConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 22,
      child: CustomPaint(painter: _MatchedPairConnectorPainter(color: color)),
    );
  }
}

class _MatchedPairConnectorPainter extends CustomPainter {
  const _MatchedPairConnectorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..isAntiAlias = true;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(2, centerY)
      ..cubicTo(
        size.width * 0.28,
        centerY - 7,
        size.width * 0.72,
        centerY + 7,
        size.width - 2,
        centerY,
      );

    canvas
      ..drawPath(path, glowPaint)
      ..drawPath(path, linePaint);

    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(size.width / 2, centerY), 7, checkPaint);

    final checkStroke = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    final checkPath = Path()
      ..moveTo(size.width / 2 - 3.2, centerY)
      ..lineTo(size.width / 2 - 0.6, centerY + 3)
      ..lineTo(size.width / 2 + 4.2, centerY - 3.8);
    canvas.drawPath(checkPath, checkStroke);
  }

  @override
  bool shouldRepaint(covariant _MatchedPairConnectorPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
