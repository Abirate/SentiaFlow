
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final ui.Image image;
  final List<Pose> poses;

  PosePainter({required this.image, required this.poses});

  @override
  void paint(Canvas canvas, Size size) {
    // CORRECTION: Utilisation de la couleur du thème
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.tealAccent[400]!;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightBlueAccent;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.pinkAccent;

    // Dessine l'image de fond
    canvas.drawImage(image, Offset.zero, Paint());

    for (final pose in poses) {
      // Dessine les lignes de connexion
      _paintLine(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint, canvas);
      _paintLine(pose, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint, canvas);
      _paintLine(pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, rightPaint, canvas);
      _paintLine(pose, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint, canvas);
      _paintLine(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint, canvas);
      _paintLine(pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, rightPaint, canvas);
      _paintLine(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, paint, canvas);
      _paintLine(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint, canvas);
      _paintLine(pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint, canvas);
      _paintLine(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint, canvas);
      _paintLine(pose, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint, canvas);
      _paintLine(pose, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint, canvas);

      // Dessine les points (landmarks)
      for (final landmark in pose.landmarks.values) {
        canvas.drawCircle(Offset(landmark.x, landmark.y), 4, paint..style = PaintingStyle.fill);
      }
    }
  }

  void _paintLine(Pose pose, PoseLandmarkType type1, PoseLandmarkType type2, Paint paint, Canvas canvas) {
    final landmark1 = pose.landmarks[type1];
    final landmark2 = pose.landmarks[type2];
    if (landmark1 != null && landmark2 != null) {
      canvas.drawLine(Offset(landmark1.x, landmark1.y), Offset(landmark2.x, landmark2.y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.poses != poses;
  }
}
