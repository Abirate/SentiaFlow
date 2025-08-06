
import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:sentia_flow/features/active_flow/models/exercise_model.dart';

class AngleCalculator {
  static double _calculateAngle(PoseLandmark first, PoseLandmark mid, PoseLandmark last) {
    final radians = atan2(last.y - mid.y, last.x - mid.x) - atan2(first.y - mid.y, first.x - mid.x);
    double degrees = radians * 180.0 / pi;
    degrees = degrees.abs();
    if (degrees > 180.0) {
      degrees = 360.0 - degrees;
    }
    return degrees;
  }

  static Map<String, double> getAngles(Pose? pose, List<AngleType> keyAngles) {
    if (pose == null) return {};

    final Map<String, double> angles = {};
    final landmarks = pose.landmarks;

    for (var angleType in keyAngles) {
      // CORRECTION: Noms des angles traduits en anglais
      switch (angleType) {
        case AngleType.leftElbow:
          angles['Left Elbow'] = _calculateAngle(
              landmarks[PoseLandmarkType.leftShoulder]!,
              landmarks[PoseLandmarkType.leftElbow]!,
              landmarks[PoseLandmarkType.leftWrist]!);
          break;
        case AngleType.rightElbow:
          angles['Right Elbow'] = _calculateAngle(
              landmarks[PoseLandmarkType.rightShoulder]!,
              landmarks[PoseLandmarkType.rightElbow]!,
              landmarks[PoseLandmarkType.rightWrist]!);
          break;
        case AngleType.leftShoulder:
           angles['Left Shoulder'] = _calculateAngle(
              landmarks[PoseLandmarkType.leftElbow]!,
              landmarks[PoseLandmarkType.leftShoulder]!,
              landmarks[PoseLandmarkType.leftHip]!);
          break;
        case AngleType.rightShoulder:
           angles['Right Shoulder'] = _calculateAngle(
              landmarks[PoseLandmarkType.rightElbow]!,
              landmarks[PoseLandmarkType.rightShoulder]!,
              landmarks[PoseLandmarkType.rightHip]!);
          break;
        case AngleType.leftHip:
           angles['Left Hip'] = _calculateAngle(
              landmarks[PoseLandmarkType.leftShoulder]!,
              landmarks[PoseLandmarkType.leftHip]!,
              landmarks[PoseLandmarkType.leftKnee]!);
          break;
        case AngleType.rightHip:
          angles['Right Hip'] = _calculateAngle(
              landmarks[PoseLandmarkType.rightShoulder]!,
              landmarks[PoseLandmarkType.rightHip]!,
              landmarks[PoseLandmarkType.rightKnee]!);
          break;
        case AngleType.leftKnee:
          angles['Left Knee'] = _calculateAngle(
              landmarks[PoseLandmarkType.leftHip]!,
              landmarks[PoseLandmarkType.leftKnee]!,
              landmarks[PoseLandmarkType.leftAnkle]!);
          break;
        case AngleType.rightKnee:
          angles['Right Knee'] = _calculateAngle(
              landmarks[PoseLandmarkType.rightHip]!,
              landmarks[PoseLandmarkType.rightKnee]!,
              landmarks[PoseLandmarkType.rightAnkle]!);
          break;
      }
    }
    return angles;
  }
}
