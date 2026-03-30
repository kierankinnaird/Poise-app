// The core movement analysis logic. I track squat state via knee angle
// and check four fault conditions on every frame while the user is in the squat.
// I require 3 consecutive frames before registering a fault to avoid false positives.
import 'dart:math';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/fault.dart';

class SquatAnalyser {
  int repCount = 0;
  bool inSquat = false;
  String squatState = 'Standing';

  // Consecutive frame counter per fault -- a fault must appear for 3 frames in a row.
  Map<FaultType, int> faultFrameCounts = {
    for (final t in FaultType.values) t: 0,
  };

  // Total frames each fault was active across the whole session -- used for severity.
  Map<FaultType, int> faultTotalFrames = {
    for (final t in FaultType.values) t: 0,
  };

  // Currently active faults shown on the live overlay.
  Set<FaultType> activeFaults = {};

  // All faults seen this session -- persists across reps.
  Set<FaultType> sessionFaults = {};

  double calculateAngle(Offset a, Offset b, Offset c) {
    final radians =
        atan2(c.dy - b.dy, c.dx - b.dx) - atan2(a.dy - b.dy, a.dx - b.dx);
    double angle = radians * 180 / pi;
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  // Returns true if a new rep was just completed on this frame.
  bool analyseFrame(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null ||
        leftKnee == null ||
        leftAnkle == null ||
        rightHip == null ||
        rightKnee == null ||
        rightAnkle == null) {
      return false;
    }

    final leftAngle = calculateAngle(leftHip, leftKnee, leftAnkle);
    final rightAngle = calculateAngle(rightHip, rightKnee, rightAnkle);
    final avgAngle = (leftAngle + rightAngle) / 2;

    bool newRep = false;

    // Enter squat when knee angle drops below 110 degrees.
    if (avgAngle < 110 && !inSquat) {
      inSquat = true;
      squatState = 'Squatting';
    } else if (avgAngle > 160 && inSquat) {
      // Complete the rep when the user stands back up past 160 degrees.
      inSquat = false;
      repCount++;
      squatState = 'Standing';
      newRep = true;
    }

    if (inSquat) {
      _analyseFaults(landmarks, imageSize);
    } else {
      // Reset consecutive counters and clear live faults on the way back up.
      for (final type in FaultType.values) {
        faultFrameCounts[type] = 0;
      }
      activeFaults.clear();
    }

    return newRep;
  }

  void _analyseFaults(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    final detectedThisFrame = <FaultType>{};

    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftHeel = landmarks[PoseLandmarkType.leftHeel];
    final leftFootIndex = landmarks[PoseLandmarkType.leftFootIndex];

    // 1. Knee cave -- knee tracks inside the hip line.
    if (leftHip != null && leftKnee != null &&
        rightHip != null && rightKnee != null) {
      final leftCave = leftKnee.dx > leftHip.dx + imageSize.width * 0.05;
      final rightCave = rightKnee.dx < rightHip.dx - imageSize.width * 0.05;
      if (leftCave || rightCave) detectedThisFrame.add(FaultType.kneeCave);
    }

    // 2. Insufficient depth -- hip stays above knee.
    if (leftHip != null && leftKnee != null) {
      if (leftHip.dy < leftKnee.dy - imageSize.height * 0.03) {
        detectedThisFrame.add(FaultType.depth);
      }
    }

    // 3. Forward lean -- torso angle from vertical exceeds 45 degrees.
    if (leftShoulder != null && leftHip != null) {
      final torsoAngle = calculateAngle(
        leftShoulder,
        leftHip,
        Offset(leftHip.dx, leftHip.dy - 100),
      );
      if (torsoAngle > 45) detectedThisFrame.add(FaultType.forwardLean);
    }

    // 4. Heel rise -- heel rises above the toe line.
    if (leftHeel != null && leftFootIndex != null) {
      if (leftHeel.dy < leftFootIndex.dy - imageSize.height * 0.02) {
        detectedThisFrame.add(FaultType.heelRise);
      }
    }

    // Register a fault only after 3 consecutive frames to filter noise.
    for (final type in FaultType.values) {
      if (detectedThisFrame.contains(type)) {
        faultFrameCounts[type] = (faultFrameCounts[type] ?? 0) + 1;
        if ((faultFrameCounts[type] ?? 0) >= 3) {
          activeFaults.add(type);
          sessionFaults.add(type);
          faultTotalFrames[type] = (faultTotalFrames[type] ?? 0) + 1;
        }
      } else {
        faultFrameCounts[type] = 0;
        activeFaults.remove(type);
      }
    }
  }

  List<Fault> buildFaultList() {
    return sessionFaults.map((type) {
      final frames = faultTotalFrames[type] ?? 3;
      return Fault.fromType(type, frames);
    }).toList();
  }

  void reset() {
    repCount = 0;
    inSquat = false;
    squatState = 'Standing';
    faultFrameCounts = {for (final t in FaultType.values) t: 0};
    faultTotalFrames = {for (final t in FaultType.values) t: 0};
    activeFaults.clear();
    sessionFaults.clear();
  }
}
