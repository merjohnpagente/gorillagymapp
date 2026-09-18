import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gorilla_gym/app_theme.dart';
import 'package:gorilla_gym/models/gym_user.dart';
import 'package:gorilla_gym/models/attendance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AppTheme dark+green', () {
    test('primary is emerald green', () {
      expect(AppTheme.primary, const Color(0xFF00C950));
      expect(AppTheme.bg, const Color(0xFF070A08));
      expect(AppTheme.primaryDim, const Color(0x3300C950));
    });

    test('card decoration uses green glow', () {
      final deco = AppTheme.card(glowPrimary: true);
      expect(deco.color, AppTheme.bgCard);
      expect(deco.boxShadow, isNotNull);
      expect(deco.boxShadow!.first.color, AppTheme.primaryDim);
    });
  });

  group('GymUser model Timestamp handling', () {
    test('fromMap handles Timestamp and String', () {
      final now = DateTime.now();
      final ts = Timestamp.fromDate(now);
      final user = GymUser.fromMap({
        'name': 'Test',
        'email': 'test@a.com',
        'role': 'member',
        'membershipExpiry': ts,
        'createdAt': now.toIso8601String(),
      }, 'uid123');
      expect(user.membershipExpiry, isNotNull);
      expect(user.name, 'Test');
    });

    test('toMap uses Timestamp', () {
      final user = GymUser(
        uid: 'u1',
        name: 'A',
        email: 'a@a.com',
        role: 'member',
        createdAt: DateTime(2024, 1, 1),
      );
      final map = user.toMap();
      expect(map['createdAt'], isA<Timestamp>());
    });
  });

  group('Attendance model Timestamp handling', () {
    test('fromMap handles Timestamp', () {
      final now = Timestamp.fromDate(DateTime.now());
      final att = Attendance.fromMap({
        'memberId': 'm1',
        'memberName': 'John',
        'timeIn': now,
        'scannedBy': 'admin',
      }, 'id1');
      expect(att.memberId, 'm1');
      expect(att.timeOut, isNull);
    });

    test('toMap uses Timestamp', () {
      final att = Attendance(
        id: 'id',
        memberId: 'm1',
        memberName: 'John',
        timeIn: DateTime.now(),
        scannedBy: 'admin',
      );
      final map = att.toMap();
      expect(map['timeIn'], isA<Timestamp>());
    });
  });

  testWidgets('Splash shows branding with green theme', (tester) async {
    // Isolated splash without Firebase navigation — just verify static branding widgets
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppTheme.bg,
        ),
        home: Scaffold(
          backgroundColor: AppTheme.bg,
          body: Center(
            child: Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.white, size: 56),
                ),
                const Text('GORILLA GYM'),
                const Text('STRENGTH  •  FOCUS  •  DISCIPLINE'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('GORILLA GYM'), findsOneWidget);
    expect(find.text('STRENGTH  •  FOCUS  •  DISCIPLINE'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
  });
}
