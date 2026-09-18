import 'package:cloud_firestore/cloud_firestore.dart';

class GymUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' | 'member'
  final String? phone;
  final String? membershipType; // 'monthly' | 'quarterly' | 'annual'
  final DateTime? membershipExpiry;
  final String? qrCode; // unique QR token = uid
  final String? photoUrl;
  final DateTime createdAt;
  final bool isActive;

  const GymUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.membershipType,
    this.membershipExpiry,
    this.qrCode,
    this.photoUrl,
    required this.createdAt,
    this.isActive = true,
  });

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    if (v is DateTime) return v;
    return null;
  }

  factory GymUser.fromMap(Map<String, dynamic> map, String uid) {
    return GymUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'member',
      phone: map['phone'] as String?,
      membershipType: map['membershipType'] as String?,
      membershipExpiry: _toDate(map['membershipExpiry']),
      qrCode: map['qrCode'] as String? ?? uid,
      photoUrl: map['photoUrl'] as String?,
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'membershipType': membershipType,
        'membershipExpiry': membershipExpiry != null ? Timestamp.fromDate(membershipExpiry!) : null,
        'qrCode': qrCode ?? uid,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'isActive': isActive,
      };

  bool get isMembershipActive {
    if (membershipExpiry == null) return false;
    return membershipExpiry!.isAfter(DateTime.now());
  }

  int get daysRemaining {
    if (membershipExpiry == null) return 0;
    return membershipExpiry!.difference(DateTime.now()).inDays;
  }
}
