// Organisation model for practitioner accounts. Each org has a unique referral
// code that athletes redeem to get free pro access (faults only, no prehab plan).
import 'package:cloud_firestore/cloud_firestore.dart';

// Matches the billing tiers on the web portal. Enterprise is manually provisioned.
enum OrgTier { starter, pro, team, club, enterprise }

extension OrgTierExtension on OrgTier {
  String get name {
    switch (this) {
      case OrgTier.starter:    return 'starter';
      case OrgTier.pro:        return 'pro';
      case OrgTier.team:       return 'team';
      case OrgTier.club:       return 'club';
      case OrgTier.enterprise: return 'enterprise';
    }
  }

  // -1 means unlimited.
  int get maxSeats {
    switch (this) {
      case OrgTier.starter:    return 10;
      case OrgTier.pro:        return 30;
      case OrgTier.team:       return 75;
      case OrgTier.club:       return 250;
      case OrgTier.enterprise: return -1;
    }
  }

  static OrgTier fromString(String value) {
    switch (value) {
      case 'starter':    return OrgTier.starter;
      case 'pro':        return OrgTier.pro;
      case 'team':       return OrgTier.team;
      case 'club':       return OrgTier.club;
      case 'enterprise': return OrgTier.enterprise;
      default:           return OrgTier.starter;
    }
  }
}

class Organisation {
  final String id;
  final String name;
  final String ownerUid;
  final String code; // unique referral code athletes enter in the app
  final OrgTier tier;
  final DateTime createdAt;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;

  const Organisation({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.code,
    required this.tier,
    required this.createdAt,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
  });

  int get maxSeats => tier.maxSeats;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'ownerUid': ownerUid,
      'code': code,
      'tier': tier.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (stripeCustomerId != null) 'stripeCustomerId': stripeCustomerId,
      if (stripeSubscriptionId != null) 'stripeSubscriptionId': stripeSubscriptionId,
    };
  }

  factory Organisation.fromFirestore(String docId, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    final createdAt =
        ts is Timestamp ? ts.toDate() : DateTime.parse(ts as String);
    return Organisation(
      id: docId,
      name: data['name'] as String? ?? '',
      ownerUid: data['ownerUid'] as String? ?? '',
      code: data['code'] as String? ?? '',
      tier: OrgTierExtension.fromString(data['tier'] as String? ?? 'starter'),
      createdAt: createdAt,
      stripeCustomerId: data['stripeCustomerId'] as String?,
      stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
    );
  }
}

// Stored in organisations/{orgId}/members/{uid}
class OrgMember {
  final String uid;
  final String? displayName; // denormalised for dashboard queries
  final DateTime joinedAt;

  const OrgMember({
    required this.uid,
    this.displayName,
    required this.joinedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      if (displayName != null) 'displayName': displayName,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory OrgMember.fromFirestore(Map<String, dynamic> data) {
    final ts = data['joinedAt'];
    final joinedAt =
        ts is Timestamp ? ts.toDate() : DateTime.parse(ts as String);
    return OrgMember(
      uid: data['uid'] as String? ?? '',
      displayName: data['displayName'] as String?,
      joinedAt: joinedAt,
    );
  }
}
