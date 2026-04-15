// Single leg stand analyser -- timed balance test, 15 seconds each side.
// The timing itself is managed by ScreenScreen. This analyser detects whether
// the user is in valid single-leg stance and tracks lateral sway.
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/movement_observation.dart';

class SingleLegStandAnalyser {
  String activeSide = 'left';

  // inStance is true when the non-stance foot is visibly lifted.
  bool inStance = false;

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

  void switchSide() {
    activeSide = 'right';
    inStance = false;
    observationFrameCounts = {for (final t in MovementObservationType.values) t: 0};
    activeObservations.clear();
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
      _analyseObservations(landmarks, imageSize);
    } else {
      observationFrameCounts[MovementObservationType.excessiveSway] = 0;
      activeObservations.remove(MovementObservationType.excessiveSway);
    }

    return inStance;
  }

  void _analyseObservations(
      Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    final detected = <MovementObservationType>{};

    // Excessive sway -- shoulder midpoint drifts laterally from hip midpoint.
    if (leftHip != null &&
        rightHip != null &&
        leftShoulder != null &&
        rightShoulder != null) {
      final hipMidX = (leftHip.dx + rightHip.dx) / 2;
      final shoulderMidX = (leftShoulder.dx + rightShoulder.dx) / 2;
      if ((shoulderMidX - hipMidX).abs() > imageSize.width * 0.06) {
        detected.add(MovementObservationType.excessiveSway);
      }
    }

    final totalFrames =
        activeSide == 'left' ? _leftTotalFrames : _rightTotalFrames;
    final sessionObservations =
        activeSide == 'left' ? _leftSessionObservations : _rightSessionObservations;

    for (final type in [MovementObservationType.excessiveSway]) {
      if (detected.contains(type)) {
        observationFrameCounts[type] = (observationFrameCounts[type] ?? 0) + 1;
        if ((observationFrameCounts[type] ?? 0) >= 3) {
          activeObservations.add(type);
          sessionObservations.add(type);
          totalFrames[type] = (totalFrames[type] ?? 0) + 1;
        }
      } else {
        observationFrameCounts[type] = 0;
        activeObservations.remove(type);
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
    inStance = false;
    observationFrameCounts = {for (final t in MovementObservationType.values) t: 0};
    _leftTotalFrames = {for (final t in MovementObservationType.values) t: 0};
    _rightTotalFrames = {for (final t in MovementObservationType.values) t: 0};
    _leftSessionObservations = {};
    _rightSessionObservations = {};
    activeObservations.clear();
  }
}
