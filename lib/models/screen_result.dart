// A completed squat screen. I store this both in Firestore (for signed-in users)
// and in SharedPreferences as JSON (for guests and offline fallback).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fault.dart';

class ScreenResult {
  final String sport;
  final String goal;
  final int repCount;
  final List<Fault> faults;
  final DateTime completedAt;
  final int score;

  const ScreenResult({
    required this.sport,
    required this.goal,
    required this.repCount,
    required this.faults,
    required this.completedAt,
    required this.score,
  });

  // Score is 100 minus 15 points per unique fault type, clamped to 0-100.
  // Simple enough to explain to a user, meaningful enough to track progress.
  static int calculateScore(List<Fault> faults) {
    final uniqueFaults = faults.map((f) => f.type).toSet().length;
    return (100 - uniqueFaults * 15).clamp(0, 100);
  }

  // Firestore version uses a Timestamp for completedAt.
  Map<String, dynamic> toFirestore() {
    return {
      'sport': sport,
      'goal': goal,
      'repCount': repCount,
      'faults': faults.map((f) => f.toMap()).toList(),
      'completedAt': Timestamp.fromDate(completedAt),
      'score': score,
    };
  }

  factory ScreenResult.fromFirestore(Map<String, dynamic> data) {
    final faultList = (data['faults'] as List<dynamic>? ?? [])
        .map((f) => Fault.fromMap(f as Map<String, dynamic>))
        .toList();
    final ts = data['completedAt'];
    final completedAt =
        ts is Timestamp ? ts.toDate() : DateTime.parse(ts as String);
    return ScreenResult(
      sport: data['sport'] as String? ?? '',
      goal: data['goal'] as String? ?? '',
      repCount: data['repCount'] as int? ?? 0,
      faults: faultList,
      completedAt: completedAt,
      score: data['score'] as int? ?? 0,
    );
  }

  // JSON version uses an ISO 8601 string for SharedPreferences storage.
  Map<String, dynamic> toJson() {
    return {
      'sport': sport,
      'goal': goal,
      'repCount': repCount,
      'faults': faults.map((f) => f.toMap()).toList(),
      'completedAt': completedAt.toIso8601String(),
      'score': score,
    };
  }

  factory ScreenResult.fromJson(Map<String, dynamic> data) {
    final faultList = (data['faults'] as List<dynamic>? ?? [])
        .map((f) => Fault.fromMap(f as Map<String, dynamic>))
        .toList();
    return ScreenResult(
      sport: data['sport'] as String? ?? '',
      goal: data['goal'] as String? ?? '',
      repCount: data['repCount'] as int? ?? 0,
      faults: faultList,
      completedAt: DateTime.parse(data['completedAt'] as String),
      score: data['score'] as int? ?? 0,
    );
  }
}
