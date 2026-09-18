// ═══════════════════════════════════════════════════════════════════════════════
// lib/services/firebase_service.dart
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ─── MODELS ───────────────────────────────────────────────────────────────────

enum UserRole { admin, manager, member }

class GymProfile {
  final String id;
  final UserRole role;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;

  GymProfile({
    required this.id,
    required this.role,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
  });

  String get fullName =>
      [firstName, lastName].where((s) => s?.isNotEmpty ?? false).join(' ');

  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager;
  bool get isStaff => role == UserRole.admin || role == UserRole.manager;

  factory GymProfile.fromMap(String id, Map<String, dynamic> map) {
    return GymProfile(
      id: id,
      role: UserRole.values.firstWhere(
        (r) => r.name == (map['role'] as String? ?? 'member'),
        orElse: () => UserRole.member,
      ),
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
    );
  }
}

class GymTransaction {
  final String id;
  final String membershipId;
  final String memberId;
  final double subtotal;
  final double discountPct;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String txnRef;
  final DateTime? paidAt;
  final DateTime createdAt;

  GymTransaction({
    required this.id,
    required this.membershipId,
    required this.memberId,
    required this.subtotal,
    required this.discountPct,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.txnRef,
    this.paidAt,
    required this.createdAt,
  });

  factory GymTransaction.fromMap(String id, Map<String, dynamic> map) {
    DateTime toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      return DateTime.now();
    }

    return GymTransaction(
      id: id,
      membershipId: map['membership_id'] as String? ?? '',
      memberId: map['member_id'] as String? ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discountPct: (map['discount_pct'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String? ?? '',
      paymentStatus: map['payment_status'] as String? ?? 'pending',
      txnRef: map['txn_ref'] as String? ?? id,
      paidAt: map['paid_at'] != null ? toDate(map['paid_at']) : null,
      createdAt: toDate(map['created_at']),
    );
  }
}

// ─── SERVICE ──────────────────────────────────────────────────────────────────

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── AUTH STATE ──────────────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── EMAIL / PASSWORD LOGIN ──────────────────────────────────────────────────

  Future<GymProfile> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Authentication succeeded but no user was returned.',
      );
    }
    return _fetchOrCreateProfile(user);
  }

  // ── REGISTER ────────────────────────────────────────────────────────────────

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('profiles').doc(cred.user!.uid).set({
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'role': 'member',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ── LOGOUT ──────────────────────────────────────────────────────────────────

  Future<void> logout() async => _auth.signOut();

  // ── PASSWORD RESET ──────────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── PROFILE ─────────────────────────────────────────────────────────────────

  Future<GymProfile> getProfile(String uid) async {
    final doc = await _db.collection('profiles').doc(uid).get();
    if (!doc.exists) throw Exception('Profile not found');
    return GymProfile.fromMap(uid, doc.data()!);
  }

  Future<GymProfile> getMyProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    return getProfile(uid);
  }

  // ── FULL REGISTRATION FLOW ──────────────────────────────────────────────────

  Future<GymTransaction> completeRegistration({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String planName,
    required String paymentMethod,
    String branchName = '', // kept optional for backwards-compat, not stored
  }) async {
    await register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );

    final uid = _auth.currentUser!.uid;

    // Fetch plan details from Firestore
    final planSnap = await _db
        .collection('plans')
        .where('name', isEqualTo: planName)
        .limit(1)
        .get();

    late String planId;
    late double planPrice;

    if (planSnap.docs.isEmpty) {
      const prices = {
        'Monthly': 799.0,
        'Quarterly': 2150.0,
        'Annual': 7500.0,
        'Day Pass': 150.0,
      };
      planPrice = prices[planName] ?? 799.0;
      final ref = await _db.collection('plans').add({
        'name': planName,
        'price': planPrice,
        'is_active': true,
      });
      planId = ref.id;
    } else {
      planId = planSnap.docs.first.id;
      planPrice = (planSnap.docs.first['price'] as num).toDouble();
    }

    // Membership validity
    final now = DateTime.now();
    DateTime validUntil;

    switch (planName) {
      case 'Monthly':
        validUntil = DateTime(now.year, now.month + 1, now.day);
        break;
      case 'Quarterly':
        validUntil = DateTime(now.year, now.month + 3, now.day);
        break;
      case 'Annual':
        validUntil = DateTime(now.year + 1, now.month, now.day);
        break;
      case 'Day Pass':
        validUntil = now;
        break;
      default:
        validUntil = DateTime(now.year, now.month + 1, now.day);
        break;
    }

    // Create membership document (no branch stored)
    final membershipRef = await _db.collection('memberships').add({
      'member_id': uid,
      'plan_id': planId,
      'status': paymentMethod == 'cash' ? 'pending' : 'active',
      'valid_from': Timestamp.fromDate(now),
      'valid_until': Timestamp.fromDate(validUntil),
      'created_at': FieldValue.serverTimestamp(),
    });

    // Compute discount
    const discountPct = 10.0;
    final subtotal = planPrice / 0.9;
    final discountAmount = subtotal - planPrice;

    // Transaction reference
    final txnRefString =
        'GG-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${uid.substring(0, 4).toUpperCase()}';

    final txnData = {
      'membership_id': membershipRef.id,
      'member_id': uid,
      'plan_id': planId,
      'subtotal': double.parse(subtotal.toStringAsFixed(2)),
      'discount_pct': discountPct,
      'discount_amount': double.parse(discountAmount.toStringAsFixed(2)),
      'processing_fee': 0,
      'total_amount': planPrice,
      'payment_method': paymentMethod,
      'payment_status': paymentMethod == 'cash' ? 'pending' : 'paid',
      'txn_ref': txnRefString,
      'paid_at': paymentMethod != 'cash' ? FieldValue.serverTimestamp() : null,
      'created_at': FieldValue.serverTimestamp(),
    };

    final txnDoc = await _db.collection('transactions').add(txnData);

    return GymTransaction(
      id: txnDoc.id,
      membershipId: membershipRef.id,
      memberId: uid,
      subtotal: double.parse(subtotal.toStringAsFixed(2)),
      discountPct: discountPct,
      discountAmount: double.parse(discountAmount.toStringAsFixed(2)),
      totalAmount: planPrice,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'cash' ? 'pending' : 'paid',
      txnRef: txnRefString,
      paidAt: paymentMethod != 'cash' ? now : null,
      createdAt: now,
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  Future<GymProfile> _fetchOrCreateProfile(User user) async {
    final doc = await _db.collection('profiles').doc(user.uid).get();
    if (doc.exists) {
      return GymProfile.fromMap(user.uid, doc.data()!);
    }

    final nameParts = user.displayName?.split(' ') ?? [];
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final data = {
      'email': user.email ?? '',
      'first_name': firstName,
      'last_name': lastName,
      'phone': user.phoneNumber ?? '',
      'role': 'member',
      'created_at': FieldValue.serverTimestamp(),
    };

    await _db.collection('profiles').doc(user.uid).set(data);
    return GymProfile.fromMap(user.uid, data);
  }

  Future<GymProfile> signInWithGoogle() async {
    // google_sign_in ^7.2.0 requires explicit initialize before authenticate
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {
      // already initialized — ignore
    }
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    return _fetchOrCreateProfile(cred.user!);
  }
}

// ─── Backwards-compat alias ───────────────────────────────────────────────────
typedef SupabaseService = FirebaseService;
