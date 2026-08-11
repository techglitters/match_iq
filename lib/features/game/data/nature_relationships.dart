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

  static const sunToDay = LearningRelationship(
    id: 'sun_to_day',
    source: LearningItems.sun,
    target: LearningItems.day,
    description: 'The sun lights up the day',
    category: RelationshipCategory.nature,
  );

  static const flowerToBee = LearningRelationship(
    id: 'flower_to_bee',
    source: LearningItems.flower,
    target: LearningItems.bee,
    description: 'Bees visit flowers',
    category: RelationshipCategory.nature,
  );

  static const caterpillarToButterfly = LearningRelationship(
    id: 'nature_caterpillar_to_butterfly',
    source: LearningItems.caterpillar,
    target: LearningItems.butterfly,
    description: 'A caterpillar changes into a butterfly',
    category: RelationshipCategory.nature,
  );

  static const leafToSoil = LearningRelationship(
    id: 'leaf_to_soil',
    source: LearningItems.leaf,
    target: LearningItems.soil,
    description: 'Fallen leaves become soil',
    category: RelationshipCategory.nature,
  );

  static const mountainToRiver = LearningRelationship(
    id: 'mountain_to_river',
    source: LearningItems.mountain,
    target: LearningItems.river,
    description: 'Rivers can start in mountains',
    category: RelationshipCategory.nature,
  );

  static const rainToRainbow = LearningRelationship(
    id: 'rain_to_rainbow',
    source: LearningItems.rain,
    target: LearningItems.rainbow,
    description: 'Rain and light can make a rainbow',
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

  static const riverToOcean = LearningRelationship(
    id: 'river_to_ocean',
    source: LearningItems.river,
    target: LearningItems.ocean,
    description: 'Rivers flow toward the ocean',
    category: RelationshipCategory.nature,
  );

  static const fireToSmoke = LearningRelationship(
    id: 'fire_to_smoke',
    source: LearningItems.fire,
    target: LearningItems.smoke,
    description: 'Smoke rises from fire',
    category: RelationshipCategory.nature,
  );

  static const all = [
    seedToFlower,
    treeToFruit,
    cloudToRain,
    sunToDay,
    flowerToBee,
    caterpillarToButterfly,
    leafToSoil,
    mountainToRiver,
    nestToBird,
    moonToNight,
    mountainToSnow,
    windToLeaf,
    fireToSmoke,
    rainToRainbow,
    riverToOcean,
  ];
}
