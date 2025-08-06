
import 'package:flutter/material.dart';
import 'package:sentia_flow/constants.dart';

// Énumération des angles clés que nous voulons calculer
enum AngleType {
  leftElbow,
  rightElbow,
  leftShoulder,
  rightShoulder,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
}

class Exercise {
  final String name;
  final String description;
  final IconData icon;
  final String imagePath; // Une image d'exemple pour l'utilisateur
  final List<AngleType> keyAngles; // Les angles à calculer pour cet exercice

  Exercise({
    required this.name,
    required this.description,
    required this.icon,
    required this.imagePath,
    required this.keyAngles,
  });
}

// --- Base de données des exercices (traduite en anglais) ---
final List<Exercise> exercises = [
  Exercise(
    name: 'Squat',
    description: 'Analyze squat depth and posture.',
    icon: Icons.fitness_center,
    imagePath: squatImage,
    keyAngles: [AngleType.leftHip, AngleType.rightHip, AngleType.leftKnee, AngleType.rightKnee],
  ),
  Exercise(
    name: 'Warrior II (Yoga)',
    description: 'Check arm and leg alignment.',
    icon: Icons.self_improvement,
    imagePath: warrior2Image, // Nom de constante corrigé
    keyAngles: [AngleType.leftElbow, AngleType.rightElbow, AngleType.leftKnee, AngleType.rightKnee],
  ),
  Exercise(
    name: 'Downward Dog (Yoga)',
    description: 'Analyze arm, back, and leg alignment.',
    icon: Icons.self_improvement,
    imagePath: downwardDogImage,
    keyAngles: [AngleType.leftShoulder, AngleType.rightShoulder, AngleType.leftKnee, AngleType.rightKnee],
  ),
    Exercise(
    name: 'Bicep Curl',
    description: 'Analyze the range of motion of the arms.',
    icon: Icons.fitness_center,
    imagePath: bicepCurlImage,
    keyAngles: [AngleType.leftElbow, AngleType.rightElbow],
  ),
  Exercise(
    name: 'Push-up',
    description: 'Analyze body and arm posture.',
    icon: Icons.fitness_center,
    imagePath: pushupImage,
    keyAngles: [AngleType.leftElbow, AngleType.rightElbow, AngleType.leftHip, AngleType.rightHip],
  ),
];
