import 'package:flutter/material.dart';

import '../domain/models/learning_item.dart';

class LearningItems {
  const LearningItems._();

  static const seed = LearningItem(id: 'seed', name: 'Seed', icon: Icons.grass);

  static const flower = LearningItem(
    id: 'flower',
    name: 'Flower',
    icon: Icons.local_florist,
  );

  static const tree = LearningItem(id: 'tree', name: 'Tree', icon: Icons.park);

  static const fruit = LearningItem(
    id: 'fruit',
    name: 'Fruit',
    icon: Icons.apple,
  );

  static const cloud = LearningItem(
    id: 'cloud',
    name: 'Cloud',
    icon: Icons.cloud,
  );

  static const rain = LearningItem(
    id: 'rain',
    name: 'Rain',
    icon: Icons.water_drop,
  );

  static const sun = LearningItem(
    id: 'sun',
    name: 'Sun',
    icon: Icons.wb_sunny_rounded,
  );

  static const plant = LearningItem(
    id: 'plant',
    name: 'Plant',
    icon: Icons.eco,
  );

  static const mountain = LearningItem(
    id: 'mountain',
    name: 'Mountain',
    icon: Icons.terrain,
  );

  static const river = LearningItem(
    id: 'river',
    name: 'River',
    icon: Icons.water,
  );

  static const leaf = LearningItem(id: 'leaf', name: 'Leaf', icon: Icons.spa);

  static const soil = LearningItem(
    id: 'soil',
    name: 'Soil',
    icon: Icons.landscape,
  );

  static const bird = LearningItem(
    id: 'bird',
    name: 'Bird',
    icon: Icons.flutter_dash,
  );

  static const nest = LearningItem(id: 'nest', name: 'Nest', icon: Icons.home);

  static const snow = LearningItem(
    id: 'snow',
    name: 'Snow',
    icon: Icons.ac_unit,
  );

  static const wind = LearningItem(id: 'wind', name: 'Wind', icon: Icons.air);

  static const fire = LearningItem(
    id: 'fire',
    name: 'Fire',
    icon: Icons.local_fire_department,
  );

  static const smoke = LearningItem(
    id: 'smoke',
    name: 'Smoke',
    icon: Icons.cloud,
  );

  static const car = LearningItem(
    id: 'car',
    name: 'Car',
    icon: Icons.directions_car,
  );

  static const road = LearningItem(
    id: 'road',
    name: 'Road',
    icon: Icons.traffic,
  );

  static const family = LearningItem(
    id: 'family',
    name: 'Family',
    icon: Icons.family_restroom,
  );

  static const home = LearningItem(id: 'home', name: 'Home', icon: Icons.home);
}
