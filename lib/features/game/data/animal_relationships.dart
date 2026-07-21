import '../domain/models/learning_relationship.dart';
import 'learning_items.dart';

class AnimalRelationships {
  const AnimalRelationships._();

  static const puppyToDog = LearningRelationship(
    id: 'puppy_to_dog',
    source: LearningItems.puppy,
    target: LearningItems.dog,
    description: 'A puppy grows into a dog',
    category: RelationshipCategory.animals,
  );

  static const kittenToCat = LearningRelationship(
    id: 'kitten_to_cat',
    source: LearningItems.kitten,
    target: LearningItems.cat,
    description: 'A kitten grows into a cat',
    category: RelationshipCategory.animals,
  );

  static const caterpillarToButterfly = LearningRelationship(
    id: 'caterpillar_to_butterfly',
    source: LearningItems.caterpillar,
    target: LearningItems.butterfly,
    description: 'A caterpillar changes into a butterfly',
    category: RelationshipCategory.animals,
  );

  static const tadpoleToFrog = LearningRelationship(
    id: 'tadpole_to_frog',
    source: LearningItems.tadpole,
    target: LearningItems.frog,
    description: 'A tadpole grows into a frog',
    category: RelationshipCategory.animals,
  );

  static const birdToNest = LearningRelationship(
    id: 'bird_to_nest',
    source: LearningItems.bird,
    target: LearningItems.nest,
    description: 'Birds rest in nests',
    category: RelationshipCategory.animals,
  );

  static const fishToWater = LearningRelationship(
    id: 'fish_to_water',
    source: LearningItems.fish,
    target: LearningItems.pond,
    description: 'Fish live in ponds',
    category: RelationshipCategory.animals,
  );

  static const duckToWater = LearningRelationship(
    id: 'duck_to_water',
    source: LearningItems.duck,
    target: LearningItems.pond,
    description: 'Ducks swim in ponds',
    category: RelationshipCategory.animals,
  );

  static const beeToFlower = LearningRelationship(
    id: 'bee_to_flower',
    source: LearningItems.bee,
    target: LearningItems.flower,
    description: 'Bees visit flowers',
    category: RelationshipCategory.animals,
  );

  static const sheepToWool = LearningRelationship(
    id: 'sheep_to_wool',
    source: LearningItems.sheep,
    target: LearningItems.wool,
    description: 'Wool comes from sheep',
    category: RelationshipCategory.animals,
  );

  static const cowToGrass = LearningRelationship(
    id: 'cow_to_grass',
    source: LearningItems.cow,
    target: LearningItems.plant,
    description: 'Cows eat grass',
    category: RelationshipCategory.animals,
  );

  static const horseToStable = LearningRelationship(
    id: 'horse_to_stable',
    source: LearningItems.horse,
    target: LearningItems.stable,
    description: 'Horses rest in stables',
    category: RelationshipCategory.animals,
  );

  static const bearToCave = LearningRelationship(
    id: 'bear_to_cave',
    source: LearningItems.bear,
    target: LearningItems.cave,
    description: 'Bears can rest in caves',
    category: RelationshipCategory.animals,
  );

  static const rabbitToCarrot = LearningRelationship(
    id: 'rabbit_to_carrot',
    source: LearningItems.rabbit,
    target: LearningItems.carrot,
    description: 'Rabbits eat carrots',
    category: RelationshipCategory.animals,
  );

  static const butterflyToFlower = LearningRelationship(
    id: 'butterfly_to_flower',
    source: LearningItems.butterfly,
    target: LearningItems.flower,
    description: 'Butterflies visit flowers',
    category: RelationshipCategory.animals,
  );

  static const frogToWater = LearningRelationship(
    id: 'frog_to_water',
    source: LearningItems.frog,
    target: LearningItems.pond,
    description: 'Frogs live near ponds',
    category: RelationshipCategory.animals,
  );

  static const all = [
    puppyToDog,
    kittenToCat,
    caterpillarToButterfly,
    tadpoleToFrog,
    birdToNest,
    fishToWater,
    duckToWater,
    beeToFlower,
    sheepToWool,
    cowToGrass,
    horseToStable,
    bearToCave,
    rabbitToCarrot,
    butterflyToFlower,
    frogToWater,
  ];
}
