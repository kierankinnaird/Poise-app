// Shoulder rotation analyser -- unilateral overhead reach test.
// The user raises one arm fully overhead and lowers it back to their side.
// Raising the arm to full overhead requires shoulder external rotation, so
// this doubles as a rotation range-of-motion test.
// Call switchSide() after the left phase to begin the right phase.
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/movement_observation.dart';

class ShoulderRotationAnalyser {
  String activeSide = 'left';

  int leftRepCount = 0;
  int rightRepCount = 0;
  bool inRaise = false;

  // Tracks the peak (highest) wrist position during each raise.
  // Smaller y = higher in frame = better overhead reach.
  double? _peakWristDy;

  Map<MovementObservationType, int> observationFrameCounts = {
    for (final t in MovementObservationType.values) t: 0,
  };
  Map<MovementObservationType, int> _leftTotalFrames = {
    for (final t in MovementObservationType.values) t: 0,
  };
  Map<MovementObservationType, int> _rightTotalFrames = {
    for (final t in MovementObservationType.values) t: 0,
  };

  Set<MovementObservationType> _leftSessionObservations = {};
  Set<MovementObservationType> _rightSessionObservations = {};
  Set<MovementObservationType> activeObservations = {};

  int get activeRepCount =>
      activeSide == 'left' ? leftRepCount : rightRepCount;

  void switchSide() {
    activeSide = 'right';
    inRaise = false;
    _peakWristDy = null;
    observationFrameCounts = {for (final t in MovementObservationType.values) t: 0};
    activeObservations.clear();
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
        _checkPeakObservation(landmarks);
        _peakWristDy = null;
      }
    }

    if (inRaise) {
      _analyseObservations(landmarks, imageSize);
    } else {
      observationFrameCounts[MovementObservationType.limitedRotation] = 0;
      activeObservations.remove(MovementObservationType.limitedRotation);
    }

    return newRep;
  }

  // At the end of each rep, check if the wrist ever reached above nose level.
  // If not, the user has limited overhead reach indicating restricted rotation.
  void _checkPeakObservation(Map<PoseLandmarkType, Offset> landmarks) {
    if (_peakWristDy == null) return;
    final nose = landmarks[PoseLandmarkType.nose];
    if (nose == null) return;

    // If the highest wrist position was still below the nose, flag the observation.
    if (_peakWristDy! > nose.dy) {
      final sessionObservations =
          activeSide == 'left' ? _leftSessionObservations : _rightSessionObservations;
      final totalFrames =
          activeSide == 'left' ? _leftTotalFrames : _rightTotalFrames;
      sessionObservations.add(MovementObservationType.limitedRotation);
      // Use 10 pseudo-frames per flagged rep so severity scales with
      // how many reps show the restriction.
      totalFrames[MovementObservationType.limitedRotation] =
          (totalFrames[MovementObservationType.limitedRotation] ?? 0) + 10;
    }
  }

  void _analyseObservations(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    // Per-frame observation during raise: if wrist is above shoulder but below nose,
    // show the live limited-rotation pill as a real-time cue.
    final wrist = activeSide == 'left'
        ? landmarks[PoseLandmarkType.leftWrist]
        : landmarks[PoseLandmarkType.rightWrist];
    final nose = landmarks[PoseLandmarkType.nose];

    if (wrist != null && nose != null && _peakWristDy != null) {
      // Flag while wrist hasn't yet passed nose on the way up.
      if (wrist.dy > nose.dy) {
        observationFrameCounts[MovementObservationType.limitedRotation] =
            (observationFrameCounts[MovementObservationType.limitedRotation] ?? 0) + 1;
        if ((observationFrameCounts[MovementObservationType.limitedRotation] ?? 0) >= 3) {
          activeObservations.add(MovementObservationType.limitedRotation);
        }
      } else {
        observationFrameCounts[MovementObservationType.limitedRotation] = 0;
        activeObservations.remove(MovementObservationType.limitedRotation);
      }
    }
  }

  List<MovementObservation> buildObservationList() {
    final observations = <MovementObservation>[];
    for (final type in _leftSessionObservations) {
      observations.add(MovementObservation.fromType(
        type,
        _leftTotalFrames[type] ?? 3,
        side: 'left',
      ));
    }
    for (final type in _rightSessionObservations) {
      observations.add(MovementObservation.fromType(
        type,
        _rightTotalFrames[type] ?? 3,
        side: 'right',
      ));
    }
    return observations;
  }

  void reset() {
    activeSide = 'left';
    leftRepCount = 0;
    rightRepCount = 0;
    inRaise = false;
    _peakWristDy = null;
    observationFrameCounts = {for (final t in MovementObservationType.values) t: 0};
    _leftTotalFrames = {for (final t in MovementObservationType.values) t: 0};
    _rightTotalFrames = {for (final t in MovementObservationType.values) t: 0};
    _leftSessionObservations = {};
    _rightSessionObservations = {};
    activeObservations.clear();
  }
}
