// Single leg stand analyser -- timed balance test, 15 seconds each side.
// The timing itself is managed by ScreenScreen. This analyser detects whether
// the user is in valid single-leg stance and tracks lateral sway.
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/fault.dart';

class SingleLegStandAnalyser {
  String activeSide = 'left';

  // inStance is true when the non-stance foot is visibly lifted.
  bool inStance = false;

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

  void switchSide() {
    activeSide = 'right';
    inStance = false;
    _frameCounts = {for (final t in FaultType.values) t: 0};
    activeFaults.clear();
  }

  // Returns true when the user is currently in valid single-leg stance.
  // ScreenScreen uses this to start/stop the hold timer.
  bool analyseFrame(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftAnkle == null || rightAnkle == null) {
      inStance = false;
      return false;
    }

    // In image coordinates y increases downward, so a smaller y = higher in frame.
    // The non-stance (lifted) foot should have a noticeably smaller y than the planted foot.
    if (activeSide == 'left') {
      // Standing on left -- right foot should be lifted (smaller y).
      inStance = rightAnkle.dy < leftAnkle.dy - imageSize.height * 0.06;
    } else {
      // Standing on right -- left foot should be lifted.
      inStance = leftAnkle.dy < rightAnkle.dy - imageSize.height * 0.06;
    }

    if (inStance) {
      _analyseFaults(landmarks, imageSize);
    } else {
      _frameCounts[FaultType.excessiveSway] = 0;
      activeFaults.remove(FaultType.excessiveSway);
    }

    return inStance;
  }

  void _analyseFaults(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    final detected = <FaultType>{};

    // Excessive sway -- shoulder midpoint drifts laterally from hip midpoint.
    if (leftHip != null &&
        rightHip != null &&
        leftShoulder != null &&
        rightShoulder != null) {
      final hipMidX = (leftHip.dx + rightHip.dx) / 2;
      final shoulderMidX = (leftShoulder.dx + rightShoulder.dx) / 2;
      if ((shoulderMidX - hipMidX).abs() > imageSize.width * 0.06) {
        detected.add(FaultType.excessiveSway);
      }
    }

    final totalFrames =
        activeSide == 'left' ? _leftTotalFrames : _rightTotalFrames;
    final sessionFaults =
        activeSide == 'left' ? _leftSessionFaults : _rightSessionFaults;

    for (final type in [FaultType.excessiveSway]) {
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
    inStance = false;
    _frameCounts = {for (final t in FaultType.values) t: 0};
    _leftTotalFrames = {for (final t in FaultType.values) t: 0};
    _rightTotalFrames = {for (final t in FaultType.values) t: 0};
    _leftSessionFaults = {};
    _rightSessionFaults = {};
    activeFaults.clear();
  }
}
