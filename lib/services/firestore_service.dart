// I keep all Firestore reads and writes here so screens never
// touch the database directly. getScreenHistory is added in Stage 8.
// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/organisation.dart';
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

  // --- Organisation methods ---

  // Looks up an org by its referral code. Returns null if no match.
  Future<Organisation?> getOrgByCode(String code) async {
    final snapshot = await _db
        .collection('organisations')
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return Organisation.fromFirestore(doc.id, doc.data());
  }

  // Redeems a referral code for a user. Throws a descriptive string on failure
  // so the UI can show it directly without parsing exception types.
  Future<void> redeemReferralCode(String uid, String code, {String? displayName}) async {
    final org = await getOrgByCode(code);
    if (org == null) throw 'Code not found. Check the code and try again.';

    // Check seat cap for non-club tiers.
    if (org.maxSeats != -1) {
      final memberSnapshot = await _db
          .collection('organisations')
          .doc(org.id)
          .collection('members')
          .get();
      if (memberSnapshot.docs.length >= org.maxSeats) {
        throw 'This organisation has reached its seat limit. Ask your practitioner to upgrade their plan.';
      }
    }

    // Check user hasn't already redeemed a code.
    final userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data()?['orgId'] != null) {
      throw 'You are already linked to an organisation.';
    }

    // Add member + update user doc atomically.
    final batch = _db.batch();

    batch.set(
      _db.collection('organisations').doc(org.id).collection('members').doc(uid),
      OrgMember(
        uid: uid,
        displayName: displayName,
        joinedAt: DateTime.now(),
      ).toFirestore(),
    );

    batch.update(_db.collection('users').doc(uid), {
      'isPro': true,
      'orgId': org.id,
      'prehabLocked': true,
    });

    await batch.commit();
  }

  // Returns all members of an org -- used by the practitioner web dashboard.
  Future<List<OrgMember>> getOrgMembers(String orgId) async {
    final snapshot = await _db
        .collection('organisations')
        .doc(orgId)
        .collection('members')
        .orderBy('joinedAt', descending: false)
        .get();
    return snapshot.docs
        .map((doc) => OrgMember.fromFirestore(doc.data()))
        .toList();
  }

  // Returns the org for a given owner -- used by the web dashboard to load
  // the practitioner's own organisation on sign in.
  Future<Organisation?> getOrgByOwner(String ownerUid) async {
    final snapshot = await _db
        .collection('organisations')
        .where('ownerUid', isEqualTo: ownerUid)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return Organisation.fromFirestore(doc.id, doc.data());
  }
}
