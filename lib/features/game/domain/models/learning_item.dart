import 'package:flutter/material.dart';

class LearningItem {
  const LearningItem({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final IconData icon;
}
