// The core movement analysis logic. I track squat state via knee angle
// and check four observation conditions on every frame while the user is in the squat.
// I require 3 consecutive frames before registering an observation to avoid false positives.
import 'dart:math';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/movement_observation.dart';

class SquatAnalyser {
  int repCount = 0;
  bool inSquat = false;
  String squatState = 'Standing';

  // Consecutive frame counter per observation -- an observation must appear for 3 frames in a row.
  Map<MovementObservationType, int> observationFrameCounts = {
    for (final t in MovementObservationType.values) t: 0,
  };

  // Total frames each observation was active across the whole session -- used for intensity.
  Map<MovementObservationType, int> observationTotalFrames = {
    for (final t in MovementObservationType.values) t: 0,
  };

  // Currently active observations shown on the live overlay.
  Set<MovementObservationType> activeObservations = {};

  // All observations seen this session -- persists across reps.
  Set<MovementObservationType> sessionObservations = {};

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
      _analyseObservations(landmarks, imageSize);
    } else {
      // Reset consecutive counters and clear live observations on the way back up.
      for (final type in MovementObservationType.values) {
        observationFrameCounts[type] = 0;
      }
      activeObservations.clear();
    }

    return newRep;
  }

  void _analyseObservations(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    final detectedThisFrame = <MovementObservationType>{};

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
      if (leftCave || rightCave) detectedThisFrame.add(MovementObservationType.kneeCave);
    }

    // 2. Insufficient depth -- hip stays above knee.
    if (leftHip != null && leftKnee != null) {
      if (leftHip.dy < leftKnee.dy - imageSize.height * 0.03) {
        detectedThisFrame.add(MovementObservationType.depth);
      }
    }

    // 3. Forward lean -- torso angle from vertical exceeds 45 degrees.
    if (leftShoulder != null && leftHip != null) {
      final torsoAngle = calculateAngle(
        leftShoulder,
        leftHip,
        Offset(leftHip.dx, leftHip.dy - 100),
      );
      if (torsoAngle > 45) detectedThisFrame.add(MovementObservationType.forwardLean);
    }

    // 4. Heel rise -- heel rises above the toe line.
    if (leftHeel != null && leftFootIndex != null) {
      if (leftHeel.dy < leftFootIndex.dy - imageSize.height * 0.02) {
        detectedThisFrame.add(MovementObservationType.heelRise);
      }
    }

    // Register an observation only after 3 consecutive frames to filter noise.
    for (final type in MovementObservationType.values) {
      if (detectedThisFrame.contains(type)) {
        observationFrameCounts[type] = (observationFrameCounts[type] ?? 0) + 1;
        if ((observationFrameCounts[type] ?? 0) >= 3) {
          activeObservations.add(type);
          sessionObservations.add(type);
          observationTotalFrames[type] = (observationTotalFrames[type] ?? 0) + 1;
        }
      } else {
        observationFrameCounts[type] = 0;
        activeObservations.remove(type);
      }
    }
  }

  List<MovementObservation> buildObservationList() {
    return sessionObservations.map((type) {
      final frames = observationTotalFrames[type] ?? 3;
      return MovementObservation.fromType(type, frames);
    }).toList();
  }

  void reset() {
    repCount = 0;
    inSquat = false;
    squatState = 'Standing';
    observationFrameCounts = {for (final t in MovementObservationType.values) t: 0};
    observationTotalFrames = {for (final t in MovementObservationType.values) t: 0};
    activeObservations.clear();
    sessionObservations.clear();
  }
}
