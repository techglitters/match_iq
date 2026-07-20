import '../domain/models/learning_relationship.dart';
import 'learning_items.dart';

class LearningRelationships {
  const LearningRelationships._();

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
    category: RelationshipCategory.weather,
  );

  static const sunToPlant = LearningRelationship(
    id: 'sun_to_plant',
    source: LearningItems.sun,
    target: LearningItems.plant,
    description: 'Plants use sunlight to grow',
    category: RelationshipCategory.nature,
  );

  static const mountainToRiver = LearningRelationship(
    id: 'mountain_to_river',
    source: LearningItems.mountain,
    target: LearningItems.river,
    description: 'Rivers can begin in mountains',
    category: RelationshipCategory.nature,
  );

  static const leafToSoil = LearningRelationship(
    id: 'leaf_to_soil',
    source: LearningItems.leaf,
    target: LearningItems.soil,
    description: 'Leaves return nutrients to soil',
    category: RelationshipCategory.nature,
  );

  static const birdToNest = LearningRelationship(
    id: 'bird_to_nest',
    source: LearningItems.bird,
    target: LearningItems.nest,
    description: 'A bird lives in a nest',
    category: RelationshipCategory.animals,
  );

  static const snowToMountain = LearningRelationship(
    id: 'snow_to_mountain',
    source: LearningItems.snow,
    target: LearningItems.mountain,
    description: 'Snow can cover mountains',
    category: RelationshipCategory.weather,
  );

  static const windToLeaf = LearningRelationship(
    id: 'wind_to_leaf',
    source: LearningItems.wind,
    target: LearningItems.leaf,
    description: 'Wind moves leaves',
    category: RelationshipCategory.weather,
  );

  static const fireToSmoke = LearningRelationship(
    id: 'fire_to_smoke',
    source: LearningItems.fire,
    target: LearningItems.smoke,
    description: 'Smoke comes from fire',
    category: RelationshipCategory.home,
  );

  static const carToRoad = LearningRelationship(
    id: 'car_to_road',
    source: LearningItems.car,
    target: LearningItems.road,
    description: 'Cars drive on roads',
    category: RelationshipCategory.vehicles,
  );

  static const familyToHome = LearningRelationship(
    id: 'family_to_home',
    source: LearningItems.family,
    target: LearningItems.home,
    description: 'Families live in homes',
    category: RelationshipCategory.family,
  );

  static const all = [
    seedToFlower,
    treeToFruit,
    cloudToRain,
    sunToPlant,
    mountainToRiver,
    leafToSoil,
    birdToNest,
    snowToMountain,
    windToLeaf,
    fireToSmoke,
    carToRoad,
    familyToHome,
  ];
}
