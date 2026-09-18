import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance.dart';
import '../models/gym_user.dart';

class AttendanceService {
  final _db = FirebaseFirestore.instance;

  // ── Record attendance from QR scan ────────────────────
  /// Returns the created Attendance record or throws if member not found.
  /// Uses Timestamp for queries and transaction for atomic check-in/out.
  Future<Attendance> recordFromQr(String qrToken) async {
    // qrToken == member uid
    final userDoc = await _db.collection('users').doc(qrToken).get();
    if (!userDoc.exists) throw Exception('Member not found for QR: $qrToken');

    final member = GymUser.fromMap(userDoc.data()!, qrToken);
    if (!member.isActive) throw Exception('Member account is inactive.');
    if (!member.isMembershipActive) {
      throw Exception('Membership expired for ${member.name}.');
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startTs = Timestamp.fromDate(startOfDay);

    // Use transaction to avoid duplicate check-ins on rapid scans
    return _db.runTransaction((txn) async {
      final existingQuery = await _db
          .collection('attendance')
          .where('memberId', isEqualTo: qrToken)
          .where('timeIn', isGreaterThanOrEqualTo: startTs)
          .where('timeOut', isNull: true)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Check out
        final doc = existingQuery.docs.first;
        final timeOut = DateTime.now();
        txn.update(doc.reference, {
          'timeOut': Timestamp.fromDate(timeOut),
        });
        final data = doc.data();
        return Attendance.fromMap(
            {...data, 'timeOut': Timestamp.fromDate(timeOut)}, doc.id);
      }

      // Check in
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final att = Attendance(
        id: '',
        memberId: qrToken,
        memberName: member.name,
        timeIn: DateTime.now(),
        scannedBy: adminUid,
      );

      final ref = _db.collection('attendance').doc();
      txn.set(ref, att.toMap());
      return Attendance(
        id: ref.id,
        memberId: att.memberId,
        memberName: att.memberName,
        timeIn: att.timeIn,
        scannedBy: att.scannedBy,
      );
    });
  }

  // ── Today's attendance list ────────────────────────────
  Stream<List<Attendance>> todayAttendance() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startTs = Timestamp.fromDate(startOfDay);
    return _db
        .collection('attendance')
        .where('timeIn', isGreaterThanOrEqualTo: startTs)
        .orderBy('timeIn', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Attendance.fromMap(d.data(), d.id)).toList());
  }

  // ── Member's own attendance history ───────────────────
  Future<List<Attendance>> memberHistory(String uid) async {
    final snap = await _db
        .collection('attendance')
        .where('memberId', isEqualTo: uid)
        .orderBy('timeIn', descending: true)
        .limit(30)
        .get();
    return snap.docs.map((d) => Attendance.fromMap(d.data(), d.id)).toList();
  }

  // ── All-time count for dashboard ───────────────────────
  Future<int> totalCheckInsToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startTs = Timestamp.fromDate(startOfDay);
    final snap = await _db
        .collection('attendance')
        .where('timeIn', isGreaterThanOrEqualTo: startTs)
        .get();
    return snap.docs.length;
  }
}
