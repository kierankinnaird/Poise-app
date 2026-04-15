// A completed movement screen. I store this both in Firestore (for signed-in users)
// and in SharedPreferences as JSON (for guests and offline fallback).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'movement_observation.dart';
import 'movement_type.dart';

class ScreenResult {
  final String sport;
  final String goal;
  final MovementType movementType;
  final int repCount;
  final List<MovementObservation> observations;
  final DateTime completedAt;
  final int score;

  const ScreenResult({
    required this.sport,
    required this.goal,
    this.movementType = MovementType.squat,
    required this.repCount,
    required this.observations,
    required this.completedAt,
    required this.score,
  });

  // Score is 100 minus 15 points per unique observation type, clamped to 0-100.
  // Simple enough to explain to a user, meaningful enough to track progress.
  static int calculateScore(List<MovementObservation> observations) {
    final uniqueObservations = observations.map((o) => o.type).toSet().length;
    return (100 - uniqueObservations * 15).clamp(0, 100);
  }

  // Firestore version uses a Timestamp for completedAt.
  Map<String, dynamic> toFirestore() {
    return {
      'sport': sport,
      'goal': goal,
      'movementType': movementType.storageKey,
      'repCount': repCount,
      'observations': observations.map((o) => o.toMap()).toList(),
      'completedAt': Timestamp.fromDate(completedAt),
      'score': score,
    };
  }

  factory ScreenResult.fromFirestore(Map<String, dynamic> data) {
    final observationList = (data['observations'] as List<dynamic>? ?? [])
        .map((o) => MovementObservation.fromMap(o as Map<String, dynamic>))
        .toList();
    final ts = data['completedAt'];
    final completedAt =
        ts is Timestamp ? ts.toDate() : DateTime.parse(ts as String);
    return ScreenResult(
      sport: data['sport'] as String? ?? '',
      goal: data['goal'] as String? ?? '',
      movementType: MovementTypeX.fromStorageKey(
          data['movementType'] as String? ?? ''),
      repCount: data['repCount'] as int? ?? 0,
      observations: observationList,
      completedAt: completedAt,
      score: data['score'] as int? ?? 0,
    );
  }

  // JSON version uses an ISO 8601 string for SharedPreferences storage.
  Map<String, dynamic> toJson() {
    return {
      'sport': sport,
      'goal': goal,
      'movementType': movementType.storageKey,
      'repCount': repCount,
      'observations': observations.map((o) => o.toMap()).toList(),
      'completedAt': completedAt.toIso8601String(),
      'score': score,
    };
  }

  factory ScreenResult.fromJson(Map<String, dynamic> data) {
    final observationList = (data['observations'] as List<dynamic>? ?? [])
        .map((o) => MovementObservation.fromMap(o as Map<String, dynamic>))
        .toList();
    return ScreenResult(
      sport: data['sport'] as String? ?? '',
      goal: data['goal'] as String? ?? '',
      movementType: MovementTypeX.fromStorageKey(
          data['movementType'] as String? ?? ''),
      repCount: data['repCount'] as int? ?? 0,
      observations: observationList,
      completedAt: DateTime.parse(data['completedAt'] as String),
      score: data['score'] as int? ?? 0,
    );
  }
}
