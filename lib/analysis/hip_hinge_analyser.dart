// Hip hinge analyser -- bilateral, 5 reps.
// A good hinge: torso tilts forward with hips pushing back, minimal knee bend, flat back.
// Detected from the front camera by tracking shoulder height relative to hips.
// When the torso hinges forward, the shoulders drop toward hip level in the frame.
import 'dart:math';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/fault.dart';

class HipHingeAnalyser {
  int repCount = 0;
  bool inHinge = false;

  Map<FaultType, int> _frameCounts = {
    for (final t in FaultType.values) t: 0,
  };
  Map<FaultType, int> _totalFrames = {
    for (final t in FaultType.values) t: 0,
  };

  Set<FaultType> _sessionFaults = {};
  Set<FaultType> activeFaults = {};

  // Returns true when a rep is completed on this frame.
  bool analyseFrame(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return false;
    }

    // Use midpoints for stability.
    final shoulderMidY = (leftShoulder.dy + rightShoulder.dy) / 2;
    final hipMidY = (leftHip.dy + rightHip.dy) / 2;

    // In image coordinates y increases downward. Standing: shoulderMidY << hipMidY.
    // As the torso hinges, shoulders drop -- shoulderMidY increases toward hipMidY.
    // Enter hinge when shoulders are within 12% of image height from hip level.
    final gap = hipMidY - shoulderMidY;
    bool newRep = false;

    if (!inHinge && gap < imageSize.height * 0.12) {
      inHinge = true;
    } else if (inHinge && gap > imageSize.height * 0.22) {
      // Rep complete when shoulders return well above hip level.
      inHinge = false;
      repCount++;
      newRep = true;
    }

    if (inHinge) {
      _analyseFaults(landmarks, imageSize);
    } else {
      for (final type in [
        FaultType.excessiveKneeBend,
        FaultType.kneeCave,
        FaultType.heelRise,
      ]) {
        _frameCounts[type] = 0;
      }
      activeFaults.clear();
    }

    return newRep;
  }

  void _analyseFaults(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    final detected = <FaultType>{};

    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftHeel = landmarks[PoseLandmarkType.leftHeel];
    final leftFootIndex = landmarks[PoseLandmarkType.leftFootIndex];

    // 1. Excessive knee bend -- average knee angle below 130 degrees is too squat-like.
    if (leftHip != null &&
        leftKnee != null &&
        leftAnkle != null &&
        rightHip != null &&
        rightKnee != null &&
        rightAnkle != null) {
      final leftAngle = _angle(leftHip, leftKnee, leftAnkle);
      final rightAngle = _angle(rightHip, rightKnee, rightAnkle);
      if ((leftAngle + rightAngle) / 2 < 130) {
        detected.add(FaultType.excessiveKneeBend);
      }
    }

    // 2. Knee cave.
    if (leftHip != null && leftKnee != null &&
        rightHip != null && rightKnee != null) {
      final leftCave = leftKnee.dx > leftHip.dx + imageSize.width * 0.05;
      final rightCave = rightKnee.dx < rightHip.dx - imageSize.width * 0.05;
      if (leftCave || rightCave) detected.add(FaultType.kneeCave);
    }

    // 3. Heel rise.
    if (leftHeel != null && leftFootIndex != null) {
      if (leftHeel.dy < leftFootIndex.dy - imageSize.height * 0.02) {
        detected.add(FaultType.heelRise);
      }
    }

    for (final type in [
      FaultType.excessiveKneeBend,
      FaultType.kneeCave,
      FaultType.heelRise,
    ]) {
      if (detected.contains(type)) {
        _frameCounts[type] = (_frameCounts[type] ?? 0) + 1;
        if ((_frameCounts[type] ?? 0) >= 3) {
          activeFaults.add(type);
          _sessionFaults.add(type);
          _totalFrames[type] = (_totalFrames[type] ?? 0) + 1;
        }
      } else {
        _frameCounts[type] = 0;
        activeFaults.remove(type);
      }
    }
  }

  double _angle(Offset a, Offset b, Offset c) {
    final radians =
        atan2(c.dy - b.dy, c.dx - b.dx) - atan2(a.dy - b.dy, a.dx - b.dx);
    double angle = radians * 180 / pi;
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  List<Fault> buildFaultList() {
    return _sessionFaults.map((type) {
      return Fault.fromType(type, _totalFrames[type] ?? 3);
    }).toList();
  }

  void reset() {
    repCount = 0;
    inHinge = false;
    _frameCounts = {for (final t in FaultType.values) t: 0};
    _totalFrames = {for (final t in FaultType.values) t: 0};
    _sessionFaults = {};
    activeFaults.clear();
  }
}
