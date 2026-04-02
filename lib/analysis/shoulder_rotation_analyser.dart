// Shoulder rotation analyser -- unilateral overhead reach test.
// The user raises one arm fully overhead and lowers it back to their side.
// Raising the arm to full overhead requires shoulder external rotation, so
// this doubles as a rotation range-of-motion test.
// Call switchSide() after the left phase to begin the right phase.
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/fault.dart';

class ShoulderRotationAnalyser {
  String activeSide = 'left';

  int leftRepCount = 0;
  int rightRepCount = 0;
  bool inRaise = false;

  // Tracks the peak (highest) wrist position during each raise.
  // Smaller y = higher in frame = better overhead reach.
  double? _peakWristDy;

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
    inRaise = false;
    _peakWristDy = null;
    _frameCounts = {for (final t in FaultType.values) t: 0};
    activeFaults.clear();
  }

  bool analyseFrame(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    final shoulder = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftShoulder]
        : landmarks[PoseLandmarkType.rightShoulder];
    final wrist = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftWrist]
        : landmarks[PoseLandmarkType.rightWrist];
    final hip = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftHip]
        : landmarks[PoseLandmarkType.rightHip];

    if (shoulder == null || wrist == null || hip == null) return false;

    bool newRep = false;

    if (!inRaise) {
      // Enter raise when wrist crosses above shoulder level.
      if (wrist.dy < shoulder.dy) {
        inRaise = true;
        _peakWristDy = wrist.dy;
      }
    } else {
      // Track the highest point reached this rep.
      if (wrist.dy < _peakWristDy!) _peakWristDy = wrist.dy;

      // Rep complete when wrist returns below hip level.
      if (wrist.dy > hip.dy) {
        inRaise = false;
        if (activeSide == 'left') { leftRepCount++; } else { rightRepCount++; }
        newRep = true;
        _checkPeakFault(landmarks);
        _peakWristDy = null;
      }
    }

    if (inRaise) {
      _analyseFaults(landmarks, imageSize);
    } else {
      _frameCounts[FaultType.limitedRotation] = 0;
      activeFaults.remove(FaultType.limitedRotation);
    }

    return newRep;
  }

  // At the end of each rep, check if the wrist ever reached above nose level.
  // If not, the user has limited overhead reach indicating restricted rotation.
  void _checkPeakFault(Map<PoseLandmarkType, Offset> landmarks) {
    if (_peakWristDy == null) return;
    final nose = landmarks[PoseLandmarkType.nose];
    if (nose == null) return;

    // If the highest wrist position was still below the nose, flag the fault.
    if (_peakWristDy! > nose.dy) {
      final sessionFaults =
          activeSide == 'left' ? _leftSessionFaults : _rightSessionFaults;
      final totalFrames =
          activeSide == 'left' ? _leftTotalFrames : _rightTotalFrames;
      sessionFaults.add(FaultType.limitedRotation);
      // Use 10 pseudo-frames per flagged rep so severity scales with
      // how many reps show the restriction.
      totalFrames[FaultType.limitedRotation] =
          (totalFrames[FaultType.limitedRotation] ?? 0) + 10;
    }
  }

  void _analyseFaults(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    // Per-frame fault during raise: if wrist is above shoulder but below nose,
    // show the live limited-rotation pill as a real-time cue.
    final wrist = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftWrist]
        : landmarks[PoseLandmarkType.rightWrist];
    final nose = landmarks[PoseLandmarkType.nose];

    if (wrist != null && nose != null && _peakWristDy != null) {
      // Flag while wrist hasn't yet passed nose on the way up.
      if (wrist.dy > nose.dy) {
        _frameCounts[FaultType.limitedRotation] =
            (_frameCounts[FaultType.limitedRotation] ?? 0) + 1;
        if ((_frameCounts[FaultType.limitedRotation] ?? 0) >= 3) {
          activeFaults.add(FaultType.limitedRotation);
        }
      } else {
        _frameCounts[FaultType.limitedRotation] = 0;
        activeFaults.remove(FaultType.limitedRotation);
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
    leftRepCount = 0;
    rightRepCount = 0;
    inRaise = false;
    _peakWristDy = null;
    _frameCounts = {for (final t in FaultType.values) t: 0};
    _leftTotalFrames = {for (final t in FaultType.values) t: 0};
    _rightTotalFrames = {for (final t in FaultType.values) t: 0};
    _leftSessionFaults = {};
    _rightSessionFaults = {};
    activeFaults.clear();
  }
}
