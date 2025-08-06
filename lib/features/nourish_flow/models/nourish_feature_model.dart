
import 'package:sentia_flow/constants.dart';

enum FeatureType {
  mealPlanner,
  mealAnalyzer,
}

class NourishFeature {
  final String name;
  final String description;
  final String imagePath;
  final FeatureType type; // The type of the feature

  NourishFeature({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.type,
  });
}

final List<NourishFeature> nourishFeatures = [
  NourishFeature(
    name: 'Personalized Healthy Meal Planner',
    description: 'Upload an image of your ingredients for a custom meal plan, tailored to your health profile.',
    imagePath: ingredientsImage,
    type: FeatureType.mealPlanner,
  ),
  NourishFeature(
    name: 'Instant Meal Analyzer',
    description: 'Snap a photo of your meal to get instant analysis and calorie estimation.',
    imagePath: mealImage,
    type: FeatureType.mealAnalyzer,
  ),
];

