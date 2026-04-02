// Draws the skeleton overlay on top of the camera feed.
// Fault connections are highlighted in red so the user can see exactly
// which part of their movement is being flagged in real time.
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/fault.dart';
import '../theme/app_theme.dart';

class PosePainter {
  // Maps each fault to the skeleton connections that should turn red when it fires.
  static const Map<FaultType, List<List<PoseLandmarkType>>> faultConnections = {
    FaultType.kneeCave: [
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    ],
    FaultType.depth: [
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    ],
    FaultType.forwardLean: [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    ],
    FaultType.heelRise: [
      [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel],
      [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel],
    ],
    FaultType.hipDrop: [
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    ],
    FaultType.excessiveSway: [
      [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightKnee],
    ],
    FaultType.armFallForward: [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    ],
    FaultType.limitedRotation: [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    ],
    FaultType.excessiveKneeBend: [
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ],
  };
}

class PosePainterDelegate extends CustomPainter {
  final List<Map<PoseLandmarkType, Offset>> smoothedLandmarks;
  final Size imageSize;
  final bool inSquat;
  final Set<FaultType> activeFaults;

  PosePainterDelegate({
    required this.smoothedLandmarks,
    required this.imageSize,
    required this.inSquat,
    this.activeFaults = const {},
  });

  // Build a set of connection key strings so I can look them up in O(1).
  Set<String> get _errorConnectionKeys {
    final keys = <String>{};
    for (final fault in activeFaults) {
      final connections = PosePainter.faultConnections[fault] ?? [];
      for (final conn in connections) {
        keys.add('${conn[0].index}-${conn[1].index}');
        keys.add('${conn[1].index}-${conn[0].index}');
      }
    }
    return keys;
  }

  // Accent green in a clean squat, off-white otherwise.
  Color get _baseColor {
    if (inSquat && activeFaults.isEmpty) return PoiseColors.accent;
    return PoiseColors.offWhite.withValues(alpha: 0.6);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final errorKeys = _errorConnectionKeys;

    final baseDotPaint = Paint()
      ..color = _baseColor
      ..strokeWidth = 6
      ..style = PaintingStyle.fill;

    final baseLinePaint = Paint()
      ..color = _baseColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final errorLinePaint = Paint()
      ..color = PoiseColors.error
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final errorDotPaint = Paint()
      ..color = PoiseColors.error
      ..strokeWidth = 6
      ..style = PaintingStyle.fill;

    // The connections I care about for a squat screen -- no hands or face.
    final allConnections = <List<PoseLandmarkType>>[
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    for (final landmarks in smoothedLandmarks) {
      // Lines first so dots sit on top.
      for (final conn in allConnections) {
        final key = '${conn[0].index}-${conn[1].index}';
        final isError = errorKeys.contains(key);
        _drawLine(
          canvas, size, landmarks,
          isError ? errorLinePaint : baseLinePaint,
          conn[0], conn[1],
        );
      }

      // Collect all joints involved in active faults so I can colour them red.
      final errorJoints = <PoseLandmarkType>{};
      for (final fault in activeFaults) {
        final connections = PosePainter.faultConnections[fault] ?? [];
        for (final conn in connections) {
          errorJoints.addAll(conn);
        }
      }

      for (final entry in landmarks.entries) {
        final isError = errorJoints.contains(entry.key);
        final x = entry.value.dx / imageSize.width * size.width;
        final y = entry.value.dy / imageSize.height * size.height;
        canvas.drawCircle(Offset(x, y), 4,
            isError ? errorDotPaint : baseDotPaint);
      }
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    Map<PoseLandmarkType, Offset> landmarks,
    Paint paint,
    PoseLandmarkType from,
    PoseLandmarkType to,
  ) {
    final start = landmarks[from];
    final end = landmarks[to];
    if (start == null || end == null) return;
    canvas.drawLine(
      Offset(start.dx / imageSize.width * size.width,
          start.dy / imageSize.height * size.height),
      Offset(end.dx / imageSize.width * size.width,
          end.dy / imageSize.height * size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(PosePainterDelegate oldDelegate) => true;
}
