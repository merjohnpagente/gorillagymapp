import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String memberId;
  final String memberName;
  final DateTime timeIn;
  final DateTime? timeOut;
  final String scannedBy;

  const Attendance({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.timeIn,
    this.timeOut,
    required this.scannedBy,
  });

  static DateTime _toDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  static DateTime? _toDateNullable(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    if (v is DateTime) return v;
    return null;
  }

  factory Attendance.fromMap(Map<String, dynamic> map, String id) {
    return Attendance(
      id: id,
      memberId: map['memberId'] as String? ?? '',
      memberName: map['memberName'] as String? ?? '',
      timeIn: _toDate(map['timeIn']),
      timeOut: _toDateNullable(map['timeOut']),
      scannedBy: map['scannedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'memberName': memberName,
        'timeIn': Timestamp.fromDate(timeIn),
        'timeOut': timeOut != null ? Timestamp.fromDate(timeOut!) : null,
        'scannedBy': scannedBy,
      };

  String get durationStr {
    if (timeOut == null) return 'Active';
    final diff = timeOut!.difference(timeIn);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
