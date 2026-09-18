import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/attendance_service.dart';
import '../models/attendance.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        foregroundColor: Colors.white,
        title: const Text("Today's Attendance",
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        elevation: 0,
      ),
      body: StreamBuilder<List<Attendance>>(
        stream: AttendanceService().todayAttendance(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final list = snap.data!;

          return Column(
            children: [
              // Summary bar
              Container(
                margin: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.card(glowPrimary: false),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summary('Total', '${list.length}', AppTheme.primary),
                    _vDivider(),
                    _summary(
                        'Inside',
                        '${list.where((a) => a.timeOut == null).length}',
                        AppTheme.green),
                    _vDivider(),
                    _summary(
                        'Left',
                        '${list.where((a) => a.timeOut != null).length}',
                        AppTheme.textMuted),
                  ],
                ),
              ),

              // List
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: AppTheme.textMuted, size: 48),
                            SizedBox(height: 12),
                            Text('No check-ins today',
                                style: AppTheme.bodyMuted),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final att = list[i];
                          final inside = att.timeOut == null;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.card(),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: inside
                                        ? AppTheme.greenDim
                                        : AppTheme.bgCardAlt,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    inside ? Icons.login : Icons.logout,
                                    color: inside
                                        ? AppTheme.green
                                        : AppTheme.textMuted,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(att.memberName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          )),
                                      const SizedBox(height: 2),
                                      Text(
                                        'In: ${_fmt(att.timeIn)}${att.timeOut != null ? ' · Out: ${_fmt(att.timeOut!)}' : ''}',
                                        style: AppTheme.bodyMuted
                                            .copyWith(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: inside
                                            ? AppTheme.greenDim
                                            : AppTheme.bgCardAlt,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                          inside ? 'Inside' : att.durationStr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: inside
                                                ? AppTheme.green
                                                : AppTheme.textMuted,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summary(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.bodyMuted.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 36, color: AppTheme.border);
}
