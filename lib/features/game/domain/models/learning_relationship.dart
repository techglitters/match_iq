import 'learning_item.dart';

enum RelationshipCategory { nature, family, weather, animals, home, vehicles }

class LearningRelationship {
  const LearningRelationship({
    required this.id,
    required this.source,
    required this.target,
    required this.description,
    required this.category,
  });

  final String id;
  final LearningItem source;
  final LearningItem target;
  final String description;
  final RelationshipCategory category;
}
