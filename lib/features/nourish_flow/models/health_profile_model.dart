// Modèle pour représenter le profil de santé complet de l'utilisateur
class HealthProfile {
  final double weightKg;
  final double heightCm;
  final int bloodPressureSystolic;
  final int bloodPressureDiastolic;
  final double bloodGlucoseMgDL;
  final Set<DietaryPreference> preferences; // Utilisation d'un Set pour éviter les doublons

  HealthProfile({
    required this.weightKg,
    required this.heightCm,
    required this.bloodPressureSystolic,
    required this.bloodPressureDiastolic,
    required this.bloodGlucoseMgDL,
    required this.preferences,
  });
}

// Énumération pour les préférences alimentaires
enum DietaryPreference {
  vegan,
  glutenFree,
  vegetarian,
  keto,
}