// I keep all Firestore reads and writes here so screens never
// touch the database directly. getScreenHistory is added in Stage 8.
// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/screen_result.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveUserProfile(UserProfile profile) async {
    // merge: true means I won't wipe fields I didn't include
    await _db
        .collection('users')
        .doc(profile.uid)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc.data()!);
  }

  Future<void> saveScreenResult(String uid, ScreenResult result) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('screens')
        .add(result.toFirestore());
  }

  Future<void> deleteScreenHistory(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('screens')
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<List<ScreenResult>> getScreenHistory(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('screens')
        .orderBy('completedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ScreenResult.fromFirestore(doc.data()))
        .toList();
  }
}
