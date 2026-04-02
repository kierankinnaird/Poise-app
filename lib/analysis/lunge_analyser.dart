// Lunge analyser -- tracks left and right phases separately.
// The screen does 5 reps with the left leg leading, then 5 with the right.
// Call switchSide() between phases to reset rep/fault counters for the new side.
import 'dart:math';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/fault.dart';

class LungeAnalyser {
  String activeSide = 'left';

  int leftRepCount = 0;
  int rightRepCount = 0;
  bool inLunge = false;

  // Per-frame consecutive counter -- fault must appear 3 frames in a row.
  Map<FaultType, int> _frameCounts = {
    for (final t in FaultType.values) t: 0,
  };

  // Total frames each fault was active per side.
  Map<FaultType, int> _leftTotalFrames = {
    for (final t in FaultType.values) t: 0,
  };
  Map<FaultType, int> _rightTotalFrames = {
    for (final t in FaultType.values) t: 0,
  };

  Set<FaultType> _leftSessionFaults = {};
  Set<FaultType> _rightSessionFaults = {};

  // Live faults shown on the overlay during the active frame.
  Set<FaultType> activeFaults = {};

  int get activeRepCount =>
      activeSide == 'left' ? leftRepCount : rightRepCount;

  // Call this when transitioning from left phase to right phase.
  void switchSide() {
    activeSide = 'right';
    inLunge = false;
    _frameCounts = {for (final t in FaultType.values) t: 0};
    activeFaults.clear();
  }

  // Returns true when a rep is completed on this frame.
  bool analyseFrame(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    final hip = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftHip]
        : landmarks[PoseLandmarkType.rightHip];
    final knee = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftKnee]
        : landmarks[PoseLandmarkType.rightKnee];
    final ankle = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftAnkle]
        : landmarks[PoseLandmarkType.rightAnkle];

    if (hip == null || knee == null || ankle == null) return false;

    final angle = _angle(hip, knee, ankle);
    bool newRep = false;

    // Enter lunge when lead knee drops below 100 degrees.
    if (angle < 100 && !inLunge) {
      inLunge = true;
    } else if (angle > 155 && inLunge) {
      inLunge = false;
      if (activeSide == 'left') {
        leftRepCount++;
      } else {
        rightRepCount++;
      }
      newRep = true;
    }

    if (inLunge) {
      _analyseFaults(landmarks, imageSize);
    } else {
      for (final type in FaultType.values) {
        _frameCounts[type] = 0;
      }
      activeFaults.clear();
    }

    return newRep;
  }

  void _analyseFaults(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    final detected = <FaultType>{};

    final leadHip = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftHip]
        : landmarks[PoseLandmarkType.rightHip];
    final leadKnee = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftKnee]
        : landmarks[PoseLandmarkType.rightKnee];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leadHeel = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftHeel]
        : landmarks[PoseLandmarkType.rightHeel];
    final leadToe = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftFootIndex]
        : landmarks[PoseLandmarkType.rightFootIndex];

    // 1. Knee cave -- lead knee collapses inward past the lead hip.
    if (leadHip != null && leadKnee != null) {
      final cave = activeSide == 'left'
          ? leadKnee.dx > leadHip.dx + imageSize.width * 0.05
          : leadKnee.dx < leadHip.dx - imageSize.width * 0.05;
      if (cave) detected.add(FaultType.kneeCave);
    }

    // 2. Hip drop -- pelvis tilts, one hip significantly lower than the other.
    if (leftHip != null && rightHip != null) {
      if ((leftHip.dy - rightHip.dy).abs() > imageSize.height * 0.04) {
        detected.add(FaultType.hipDrop);
      }
    }

    // 3. Forward lean -- torso angle exceeds 45 degrees from vertical.
    if (leftShoulder != null && leftHip != null) {
      final torsoAngle = _angle(
        leftShoulder,
        leftHip,
        Offset(leftHip.dx, leftHip.dy - 100),
      );
      if (torsoAngle > 45) detected.add(FaultType.forwardLean);
    }

    // 4. Heel rise on lead foot.
    if (leadHeel != null && leadToe != null) {
      if (leadHeel.dy < leadToe.dy - imageSize.height * 0.02) {
        detected.add(FaultType.heelRise);
      }
    }

    final totalFrames =
        activeSide == 'left' ? _leftTotalFrames : _rightTotalFrames;
    final sessionFaults =
        activeSide == 'left' ? _leftSessionFaults : _rightSessionFaults;

    for (final type in FaultType.values) {
      if (detected.contains(type)) {
        _frameCounts[type] = (_frameCounts[type] ?? 0) + 1;
        if ((_frameCounts[type] ?? 0) >= 3) {
          activeFaults.add(type);
          sessionFaults.add(type);
          totalFrames[type] = (totalFrames[type] ?? 0) + 1;
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
    final faults = <Fault>[];
    for (final type in _leftSessionFaults) {
      faults.add(Fault.fromType(
        type,
        _leftTotalFrames[type] ?? 3,
        side: 'left',
      ));
    }
    for (final type in _rightSessionFaults) {
      faults.add(Fault.fromType(
        type,
        _rightTotalFrames[type] ?? 3,
        side: 'right',
      ));
    }
    return faults;
  }

  void reset() {
    activeSide = 'left';
    leftRepCount = 0;
    rightRepCount = 0;
    inLunge = false;
    _frameCounts = {for (final t in FaultType.values) t: 0};
    _leftTotalFrames = {for (final t in FaultType.values) t: 0};
    _rightTotalFrames = {for (final t in FaultType.values) t: 0};
    _leftSessionFaults = {};
    _rightSessionFaults = {};
    activeFaults.clear();
  }
}
