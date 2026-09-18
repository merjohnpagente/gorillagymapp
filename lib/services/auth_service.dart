import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/gym_user.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // ── Get role ───────────────────────────────────────────
  // Optimized: single get (server + cache fallback) with 3s timeout instead of 5s+5s
  // Uses Firestore's default behavior which is much faster on good network and instant offline
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 3));
      return doc.data()?['role'] ?? 'member';
    } catch (_) {
      try {
        final doc = await _db
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        return doc.data()?['role'] ?? 'member';
      } catch (_) {
        return 'member';
      }
    }
  }

  String _normalizeEmail(String input) {
    var e = input.trim().toLowerCase();
    if (!e.contains('@')) {
      // Allow username "admin" -> admin@gorillagym.com
      if (e == 'admin') return 'admin@gorillagym.com';
      return '$e@gorillagym.com';
    }
    return e;
  }

  // ── Admin login ────────────────────────────────────────
  Future<GymUser?> signIn(String email, String password) async {
    final normalized = _normalizeEmail(email);
    final cred = await _auth.signInWithEmailAndPassword(
      email: normalized,
      password: password,
    );

    final uid = cred.user!.uid;

    // Fast path: single get with 2s timeout — avoids "sge rag loading" (stuck spinner)
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 2));
      if (doc.exists) return GymUser.fromMap(doc.data()!, uid);
    } catch (e) {
      if (e.toString().contains('FAILED_PRECONDITION')) rethrow;
      // timeout or network error → fall through to cache/synthetic
    }

    // Fallback to cache with 1.5s timeout — instant offline
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(milliseconds: 1500));
      if (doc.exists) return GymUser.fromMap(doc.data()!, uid);
    } catch (e) {
      if (e.toString().contains('FAILED_PRECONDITION')) rethrow;
    }

    // Auto-create missing admin profile for the seeded admin account
    // Do NOT await indefinitely — fire-and-forget with 2s timeout so login never hangs
    final isSeedAdmin = normalized == 'admin@gorillagym.com';
    if (isSeedAdmin) {
      final adminUser = GymUser(
        uid: uid,
        name: 'Admin',
        email: normalized,
        role: 'admin',
        createdAt: DateTime.now(),
        isActive: true,
      );
      // Fire-and-forget: don't block login if Firestore rules/network slow
      _db.collection('users').doc(uid).set(adminUser.toMap()).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
      return adminUser;
    }

    // Last resort: build from Firebase Auth — default to member for security
    return GymUser(
      uid: uid,
      name: cred.user?.email?.split('@').first ?? 'User',
      email: cred.user?.email ?? normalized,
      role: 'member',
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  // ── Admin registers a new member ───────────────────────
  Future<GymUser> registerMember({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String membershipType,
    required DateTime membershipExpiry,
  }) async {
    FirebaseApp? secondaryApp;
    bool created = false;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: Firebase.app().options,
      );
      created = true;
    } catch (_) {
      secondaryApp = Firebase.app('secondary');
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      final newUser = GymUser(
        uid: uid,
        name: name,
        email: email.trim(),
        role: 'member',
        phone: phone,
        membershipType: membershipType,
        membershipExpiry: membershipExpiry,
        qrCode: uid,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _db.collection('users').doc(uid).set(newUser.toMap());

      await secondaryAuth.signOut();
      return newUser;
    } finally {
      // Cleanup secondary app to avoid leaks
      try {
        if (created) await secondaryApp.delete();
      } catch (_) {}
    }
  }

  // ── Fetch single user ──────────────────────────────────
  Future<GymUser?> _getUser(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 2));
      if (doc.exists) return GymUser.fromMap(doc.data()!, uid);
    } catch (_) {}

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(milliseconds: 1200));
      if (doc.exists) return GymUser.fromMap(doc.data()!, uid);
    } catch (_) {}

    return null;
  }

  Future<GymUser?> getUserById(String uid) => _getUser(uid);

  // ── Fetch all members ──────────────────────────────────
  Future<List<GymUser>> getAllMembers() async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'member')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));
      return snap.docs.map((d) => GymUser.fromMap(d.data(), d.id)).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' && e.message?.contains('index') == true) {
        // Firestore requires composite index: role + createdAt
        throw Exception(
            'Missing Firestore index for members query. Create index: users (role ASC, createdAt DESC) — ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (e.toString().contains('FAILED_PRECONDITION') && e.toString().contains('index')) rethrow;
      return [];
    }
  }

  // ── Update member ──────────────────────────────────────
  Future<void> updateMember(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  // ── Deactivate member ──────────────────────────────────
  Future<void> toggleMemberStatus(String uid, bool isActive) =>
      _db.collection('users').doc(uid).update({'isActive': isActive});

  // ── Sign out ───────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();
}
