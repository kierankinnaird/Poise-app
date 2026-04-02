// Single leg squat analyser -- the most demanding unilateral screen.
// The user squats on one leg at a time. This exposes asymmetries in hip stability,
// knee control, and balance that bilateral squats can mask.
// Same left/right phase pattern as LungeAnalyser -- call switchSide() between phases.
import 'dart:math';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/fault.dart';

class SingleLegSquatAnalyser {
  String activeSide = 'left';

  int leftRepCount = 0;
  int rightRepCount = 0;
  bool inSquat = false;

  Map<FaultType, int> _frameCounts = {
    for (final t in FaultType.values) t: 0,
  };
  Map<FaultType, int> _leftTotalFrames = {
    for (final t in FaultType.values) t: 0,
  };
  Map<FaultType, int> _rightTotalFrames = {
    for (final t in FaultType.values) t: 0,
  };

  Set<FaultType> _leftSessionFaults = {};
  Set<FaultType> _rightSessionFaults = {};
  Set<FaultType> activeFaults = {};

  int get activeRepCount =>
      activeSide == 'left' ? leftRepCount : rightRepCount;

  void switchSide() {
    activeSide = 'right';
    inSquat = false;
    _frameCounts = {for (final t in FaultType.values) t: 0};
    activeFaults.clear();
  }

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

    // Single leg squats typically reach 90-110 degrees -- slightly more lenient
    // than a bilateral squat since balance is harder.
    if (angle < 110 && !inSquat) {
      inSquat = true;
    } else if (angle > 160 && inSquat) {
      inSquat = false;
      if (activeSide == 'left') {
        leftRepCount++;
      } else {
        rightRepCount++;
      }
      newRep = true;
    }

    if (inSquat) {
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

    final stanceHip = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftHip]
        : landmarks[PoseLandmarkType.rightHip];
    final stanceKnee = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftKnee]
        : landmarks[PoseLandmarkType.rightKnee];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final stanceHeel = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftHeel]
        : landmarks[PoseLandmarkType.rightHeel];
    final stanceToe = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftFootIndex]
        : landmarks[PoseLandmarkType.rightFootIndex];

    // 1. Knee cave on stance leg.
    if (stanceHip != null && stanceKnee != null) {
      final cave = activeSide == 'left'
          ? stanceKnee.dx > stanceHip.dx + imageSize.width * 0.05
          : stanceKnee.dx < stanceHip.dx - imageSize.width * 0.05;
      if (cave) detected.add(FaultType.kneeCave);
    }

    // 2. Hip drop -- non-stance hip drops below stance hip.
    if (leftHip != null && rightHip != null) {
      if ((leftHip.dy - rightHip.dy).abs() > imageSize.height * 0.04) {
        detected.add(FaultType.hipDrop);
      }
    }

    // 3. Forward lean.
    if (leftShoulder != null && leftHip != null) {
      final torsoAngle = _angle(
        leftShoulder,
        leftHip,
        Offset(leftHip.dx, leftHip.dy - 100),
      );
      if (torsoAngle > 45) detected.add(FaultType.forwardLean);
    }

    // 4. Heel rise on stance foot.
    if (stanceHeel != null && stanceToe != null) {
      if (stanceHeel.dy < stanceToe.dy - imageSize.height * 0.02) {
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
    inSquat = false;
    _frameCounts = {for (final t in FaultType.values) t: 0};
    _leftTotalFrames = {for (final t in FaultType.values) t: 0};
    _rightTotalFrames = {for (final t in FaultType.values) t: 0};
    _leftSessionFaults = {};
    _rightSessionFaults = {};
    activeFaults.clear();
  }
}
