import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../screens/auth/login_screen.dart';
import 'register_member_screen.dart';
import 'members_list_screen.dart';
import 'qr_scanner_screen.dart';
import 'attendance_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;

  final List<Widget> _pages = [
    const _DashboardHome(),
    const MembersListScreen(),
    const QrScannerScreen(),
    const AttendanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: _pages[_tab],
      bottomNavigationBar: _BottomNav(
        selected: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
      (Icons.people_outline, Icons.people, 'Members'),
      (Icons.qr_code_scanner, Icons.qr_code_scanner, 'Scan'),
      (Icons.calendar_today_outlined, Icons.calendar_today, 'Attendance'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final (outlineIcon, filledIcon, label) = items[i];
              final active = i == selected;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primaryDim : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(active ? filledIcon : outlineIcon,
                          color: active ? AppTheme.primary : AppTheme.textMuted,
                          size: 24),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                active ? AppTheme.primary : AppTheme.textMuted,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard Home Tab ───────────────────────────────────
class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  int _totalMembers = 0;
  int _activeMembers = 0;
  int _todayCheckIns = 0;
  int _expiringThisWeek = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Each with 3s timeout so whole screen never hangs "loading perme"
      final members = await AuthService()
          .getAllMembers()
          .timeout(const Duration(seconds: 3), onTimeout: () => []);
      final checkIns = await AttendanceService()
          .totalCheckInsToday()
          .timeout(const Duration(seconds: 3), onTimeout: () => 0);
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));
      if (!mounted) return;
      setState(() {
        _totalMembers = members.length;
        _activeMembers =
            members.where((m) => m.isActive && m.isMembershipActive).length;
        _todayCheckIns = checkIns;
        _expiringThisWeek = members.where((m) {
          if (m.membershipExpiry == null) return false;
          return m.membershipExpiry!.isAfter(now) &&
              m.membershipExpiry!.isBefore(nextWeek);
        }).length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.bgCard,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Good day,', style: AppTheme.bodyMuted),
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? 'Admin',
                            style: AppTheme.displayMd,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_outlined,
                          color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats grid
                if (_loading)
                  const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary))
                else ...[
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(
                          'Total Members',
                          '$_totalMembers',
                          Icons.people_outline,
                          AppTheme.blue,
                          AppTheme.blueDim),
                      _StatCard(
                          'Active Members',
                          '$_activeMembers',
                          Icons.check_circle_outline,
                          AppTheme.green,
                          AppTheme.greenDim),
                      _StatCard(
                          "Today's Check-ins",
                          '$_todayCheckIns',
                          Icons.qr_code_scanner,
                          AppTheme.primary,
                          AppTheme.primaryDim),
                      _StatCard(
                          'Expiring This Week',
                          '$_expiringThisWeek',
                          Icons.warning_amber_outlined,
                          AppTheme.red,
                          AppTheme.redDim),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Quick Actions
                  const Text('Quick Actions', style: AppTheme.heading),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.person_add_outlined,
                          label: 'Register\nMember',
                          color: AppTheme.primary,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const RegisterMemberScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.qr_code_scanner,
                          label: 'Scan\nQR Code',
                          color: AppTheme.green,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const QrScannerScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.people_outline,
                          label: 'View\nMembers',
                          color: AppTheme.blue,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MembersListScreen())),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Today's attendance preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Today's Attendance", style: AppTheme.heading),
                      TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AttendanceScreen())),
                        child: const Text('See all',
                            style: TextStyle(color: AppTheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream: AttendanceService()
                        .todayAttendance()
                        .timeout(const Duration(seconds: 5),
                            onTimeout: (sink) => sink.add([])),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.card(),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.textMuted, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Attendance unavailable: ${snap.error}',
                                    style: AppTheme.bodyMuted.copyWith(fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary));
                      }
                      final list = snap.data!.take(5).toList();
                      if (list.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: AppTheme.card(),
                          child: const Center(
                            child: Text('No check-ins yet today',
                                style: AppTheme.bodyMuted),
                          ),
                        );
                      }
                      return Column(
                        children: list
                            .map((att) => _AttendanceTile(
                                att.memberName, att.timeIn, att.timeOut))
                            .toList(),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color dimColor;
  const _StatCard(this.label, this.value, this.icon, this.color, this.dimColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: dimColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: AppTheme.bodyMuted.copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppTheme.card(),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final String name;
  final DateTime timeIn;
  final DateTime? timeOut;
  const _AttendanceTile(this.name, this.timeIn, this.timeOut);

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.card(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryDim,
            radius: 20,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(
                    'In: ${_fmt(timeIn)}${timeOut != null ? ' · Out: ${_fmt(timeOut!)}' : ''}',
                    style: AppTheme.bodyMuted.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: timeOut == null ? AppTheme.greenDim : AppTheme.bgCardAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(timeOut == null ? 'Inside' : 'Left',
                style: TextStyle(
                  fontSize: 11,
                  color: timeOut == null ? AppTheme.green : AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}
