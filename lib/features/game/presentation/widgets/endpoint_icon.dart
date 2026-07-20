import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/learning_item.dart';

class EndpointIcon extends StatelessWidget {
  const EndpointIcon({
    required this.item,
    required this.color,
    required this.isConnected,
    this.invalidFeedbackProgress = 0,
    super.key,
  });

  final LearningItem item;
  final Color color;
  final bool isConnected;
  final double invalidFeedbackProgress;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final feedback = invalidFeedbackProgress.clamp(0, 1).toDouble();
    final pulseWave = math.sin((1 - feedback) * math.pi * 4).abs();
    final feedbackStrength = feedback * (0.78 + pulseWave * 0.22);
    final effectiveColor = Color.lerp(color, errorColor, feedbackStrength)!;
    final scale =
        (isConnected ? 1.08 : 1) +
        feedback * 0.08 +
        pulseWave * feedback * 0.08;

    return Semantics(
      label: '${item.name}${isConnected ? ', connected' : ''}',
      child: AnimatedScale(
        scale: scale,
        duration: Duration(milliseconds: feedback > 0 ? 70 : 180),
        curve: Curves.easeOutBack,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.14 + feedback * 0.10),
            shape: BoxShape.circle,
            border: Border.all(color: effectiveColor, width: 3 + feedback),
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withValues(
                  alpha: feedback > 0
                      ? 0.34 * feedback
                      : isConnected
                      ? 0.22
                      : 0.08,
                ),
                blurRadius: feedback > 0
                    ? 20 + 8 * pulseWave
                    : isConnected
                    ? 18
                    : 10,
                offset: Offset(0, feedback > 0 ? 2 : 6),
              ),
            ],
          ),
          child: Center(
            child: Icon(item.icon, color: effectiveColor, size: 32),
          ),
        ),
      ),
    );
  }
}
