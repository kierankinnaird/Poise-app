// MLKit landmarks jitter frame-to-frame, especially on the edges of the body.
// I run a rolling average over the last N frames to smooth that out before
// passing landmarks to the squat analyser.
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class LandmarkSmoother {
  final int windowSize;
  final Map<PoseLandmarkType, List<Offset>> _history = {};

  LandmarkSmoother({this.windowSize = 5});

  Map<PoseLandmarkType, Offset> smooth(
      Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final smoothed = <PoseLandmarkType, Offset>{};
    for (final entry in landmarks.entries) {
      final type = entry.key;
      final current = Offset(entry.value.x, entry.value.y);
      _history.putIfAbsent(type, () => []);
      _history[type]!.add(current);
      if (_history[type]!.length > windowSize) {
        _history[type]!.removeAt(0);
      }
      final avg = _history[type]!.fold(Offset.zero, (a, b) => a + b) /
          _history[type]!.length.toDouble();
      smoothed[type] = avg;
    }
    return smoothed;
  }

  void reset() => _history.clear();
}
