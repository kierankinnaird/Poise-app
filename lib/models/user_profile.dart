// I store sport and goal on the profile so I can personalise the screen
// and prehab plan without asking the user every time.
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? email; // null for Apple Sign In users
  final String? name;  // user-entered display name
  final String sport;
  final String goal;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    this.email,
    this.name,
    required this.sport,
    required this.goal,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'sport': sport,
      'goal': goal,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    final ts = data['createdAt'];
    final createdAt =
        ts is Timestamp ? ts.toDate() : DateTime.parse(ts as String);
    return UserProfile(
      uid: data['uid'] as String? ?? '',
      email: data['email'] as String?,
      name: data['name'] as String?,
      sport: data['sport'] as String? ?? '',
      goal: data['goal'] as String? ?? '',
      createdAt: createdAt,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    String? sport,
    String? goal,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      goal: goal ?? this.goal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
