import 'board_position.dart';
import 'learning_relationship.dart';

class LevelPairPlacement {
  const LevelPairPlacement({
    required this.relationship,
    required this.sourcePosition,
    required this.targetPosition,
  });

  final LearningRelationship relationship;
  final BoardPosition sourcePosition;
  final BoardPosition targetPosition;
}
