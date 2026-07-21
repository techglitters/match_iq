import '../domain/models/learning_relationship.dart';
import 'learning_items.dart';

class NatureRelationships {
  const NatureRelationships._();

  static const seedToFlower = LearningRelationship(
    id: 'seed_to_flower',
    source: LearningItems.seed,
    target: LearningItems.flower,
    description: 'A seed grows into a flower',
    category: RelationshipCategory.nature,
  );

  static const treeToFruit = LearningRelationship(
    id: 'tree_to_fruit',
    source: LearningItems.tree,
    target: LearningItems.fruit,
    description: 'Fruit grows on a tree',
    category: RelationshipCategory.nature,
  );

  static const cloudToRain = LearningRelationship(
    id: 'cloud_to_rain',
    source: LearningItems.cloud,
    target: LearningItems.rain,
    description: 'Rain comes from clouds',
    category: RelationshipCategory.nature,
  );

  static const sunToPlant = LearningRelationship(
    id: 'sun_to_plant',
    source: LearningItems.sun,
    target: LearningItems.plant,
    description: 'Plants use sunlight to grow',
    category: RelationshipCategory.nature,
  );

  static const flowerToBee = LearningRelationship(
    id: 'flower_to_bee',
    source: LearningItems.flower,
    target: LearningItems.bee,
    description: 'Bees visit flowers',
    category: RelationshipCategory.nature,
  );

  static const flowerToButterfly = LearningRelationship(
    id: 'flower_to_butterfly',
    source: LearningItems.flower,
    target: LearningItems.butterfly,
    description: 'Butterflies visit flowers',
    category: RelationshipCategory.nature,
  );

  static const leafToTree = LearningRelationship(
    id: 'leaf_to_tree',
    source: LearningItems.leaf,
    target: LearningItems.tree,
    description: 'Leaves grow on trees',
    category: RelationshipCategory.nature,
  );

  static const waterToPlant = LearningRelationship(
    id: 'water_to_plant',
    source: LearningItems.rain,
    target: LearningItems.plant,
    description: 'Water helps plants grow',
    category: RelationshipCategory.nature,
  );

  static const rainToPlant = LearningRelationship(
    id: 'rain_to_plant',
    source: LearningItems.rain,
    target: LearningItems.plant,
    description: 'Rain helps plants grow',
    category: RelationshipCategory.nature,
  );

  static const sunToFlower = LearningRelationship(
    id: 'sun_to_flower',
    source: LearningItems.sun,
    target: LearningItems.flower,
    description: 'Sunlight helps flowers bloom',
    category: RelationshipCategory.nature,
  );

  static const nestToBird = LearningRelationship(
    id: 'nest_to_bird',
    source: LearningItems.nest,
    target: LearningItems.bird,
    description: 'Birds rest in nests',
    category: RelationshipCategory.nature,
  );

  static const moonToNight = LearningRelationship(
    id: 'moon_to_night',
    source: LearningItems.moon,
    target: LearningItems.night,
    description: 'The moon shines at night',
    category: RelationshipCategory.nature,
  );

  static const mountainToSnow = LearningRelationship(
    id: 'mountain_to_snow',
    source: LearningItems.mountain,
    target: LearningItems.snow,
    description: 'Snow can cover mountains',
    category: RelationshipCategory.nature,
  );

  static const windToLeaf = LearningRelationship(
    id: 'wind_to_leaf',
    source: LearningItems.wind,
    target: LearningItems.leaf,
    description: 'Wind moves leaves',
    category: RelationshipCategory.nature,
  );

  static const gardenToFlower = LearningRelationship(
    id: 'garden_to_flower',
    source: LearningItems.garden,
    target: LearningItems.flower,
    description: 'Flowers grow in gardens',
    category: RelationshipCategory.nature,
  );

  static const all = [
    seedToFlower,
    treeToFruit,
    cloudToRain,
    sunToPlant,
    flowerToBee,
    flowerToButterfly,
    leafToTree,
    waterToPlant,
    rainToPlant,
    sunToFlower,
    nestToBird,
    moonToNight,
    mountainToSnow,
    windToLeaf,
    gardenToFlower,
  ];
}
