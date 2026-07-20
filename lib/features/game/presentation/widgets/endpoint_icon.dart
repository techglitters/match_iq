import 'package:flutter/material.dart';

import '../../domain/models/learning_item.dart';

class EndpointIcon extends StatelessWidget {
  const EndpointIcon({
    required this.item,
    required this.color,
    required this.isConnected,
    super.key,
  });

  final LearningItem item;
  final Color color;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${item.name}${isConnected ? ', connected' : ''}',
      child: AnimatedScale(
        scale: isConnected ? 1.08 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isConnected ? 0.22 : 0.08),
                blurRadius: isConnected ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(child: Icon(item.icon, color: color, size: 32)),
        ),
      ),
    );
  }
}
