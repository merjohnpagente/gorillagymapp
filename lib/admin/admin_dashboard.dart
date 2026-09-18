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

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard_rounded, Icons.dashboard_rounded, 'Dashboard'),
      (Icons.people_rounded, Icons.people_rounded, 'Members'),
      (Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_rounded, 'Scan'),
      (Icons.calendar_month_rounded, Icons.calendar_month_rounded, 'Attendance'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.border.withValues(alpha: 0.8))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final (outlineIcon, filledIcon, label) = items[i];
              final active = i == selected;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(colors: [AppTheme.primary, Color(0xFF0A9A3F)])
                        : null,
                    color: active ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: active
                        ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.28), blurRadius: 12, spreadRadius: 1)]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(active ? filledIcon : outlineIcon,
                          color: active ? Colors.white : AppTheme.textMuted, size: 22),
                      const SizedBox(height: 3),
                      Text(label,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: active ? Colors.white : AppTheme.textMuted,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            letterSpacing: 0.3,
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
      final members = await AuthService().getAllMembers().timeout(const Duration(seconds: 3), onTimeout: () => []);
      final checkIns = await AttendanceService().totalCheckInsToday().timeout(const Duration(seconds: 3), onTimeout: () => 0);
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));
      if (!mounted) return;
      setState(() {
        _totalMembers = members.length;
        _activeMembers = members.where((m) => m.isActive && m.isMembershipActive).length;
        _todayCheckIns = checkIns;
        _expiringThisWeek = members.where((m) {
          if (m.membershipExpiry == null) return false;
          return m.membershipExpiry!.isAfter(now) && m.membershipExpiry!.isBefore(nextWeek);
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Admin';
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.bgCard,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F2A1A), Color(0xFF111816), Color(0xFF0A1A12)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border, width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF0A9A3F)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.32), blurRadius: 16)],
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(20)),
                                  child: const Text('ADMIN', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                ),
                                const SizedBox(width: 8),
                                Text(dateStr, style: TextStyle(color: AppTheme.textDim, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(email, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                            const Text('Welcome back, champion!', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _signOut,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Stats grid — nindot gradient cards
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                  )
                else ...[
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.42,
                    children: [
                      _StatCard(
                          'Total Members',
                          '$_totalMembers',
                          Icons.groups_rounded,
                          const [Color(0xFF1A2B4A), Color(0xFF0F1D33)],
                          AppTheme.blue,
                          AppTheme.blueDim,
                          'All time'),
                      _StatCard(
                          'Active Members',
                          '$_activeMembers',
                          Icons.verified_rounded,
                          const [Color(0xFF0F2A1A), Color(0xFF0F1D14)],
                          AppTheme.primary,
                          AppTheme.primaryDim,
                          'Healthy'),
                      _StatCard(
                          "Today's Check-ins",
                          '$_todayCheckIns',
                          Icons.qr_code_scanner_rounded,
                          const [Color(0xFF0A2F1F), Color(0xFF0E3D26)],
                          AppTheme.primary,
                          AppTheme.primaryDim,
                          'Today'),
                      _StatCard(
                          'Expiring This Week',
                          '$_expiringThisWeek',
                          Icons.timer_outlined,
                          const [Color(0xFF2A1A0F), Color(0xFF1F140A)],
                          AppTheme.amber,
                          AppTheme.amberDim,
                          'Action needed'),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Quick Actions — nindot pill gradients
                  const Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 18),
                      SizedBox(width: 6),
                      Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      SizedBox(width: 8),
                      Expanded(child: Divider(color: AppTheme.border, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.person_add_alt_1_rounded,
                          label: 'Register',
                          sub: 'New Member',
                          gradient: const [AppTheme.primary, Color(0xFF0A9A3F)],
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterMemberScreen())),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.qr_code_2_rounded,
                          label: 'Scan QR',
                          sub: 'Attendance',
                          gradient: const [Color(0xFF1A3A5A), Color(0xFF0F2A44)],
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.group_rounded,
                          label: 'Members',
                          sub: 'View All',
                          gradient: const [Color(0xFF2A1F0F), Color(0xFF3D2E12)],
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersListScreen())),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Attendance preview — glass
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history_rounded, color: AppTheme.textMuted, size: 18),
                          SizedBox(width: 6),
                          Text("Today's Attendance", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())),
                        style: TextButton.styleFrom(
                            backgroundColor: AppTheme.primaryDim,
                            foregroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream: AttendanceService().todayAttendance().timeout(const Duration(seconds: 5), onTimeout: (sink) => sink.add([])),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.card(),
                          child: Row(children: [const Icon(Icons.error_outline, color: AppTheme.textMuted, size: 20), const SizedBox(width: 10), Expanded(child: Text('Attendance unavailable: ${snap.error}', style: AppTheme.bodyMuted.copyWith(fontSize: 12)))]),
                        );
                      }
                      if (!snap.hasData) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.primary)));
                      }
                      final list = snap.data!.take(5).toList();
                      if (list.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(color: AppTheme.bgCardAlt, shape: BoxShape.circle),
                                  child: const Icon(Icons.inbox_rounded, color: AppTheme.textMuted, size: 28)),
                              const SizedBox(height: 10),
                              const Text('No check-ins yet today', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              const Text('Scan a member QR to get started', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        );
                      }
                      return Column(children: list.map((att) => _AttendanceTile(att.memberName, att.timeIn, att.timeOut)).toList());
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
  final List<Color> gradient;
  final Color color;
  final Color dimColor;
  final String caption;
  const _StatCard(this.label, this.value, this.icon, this.gradient, this.color, this.dimColor, this.caption);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: dimColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                child: Text(caption, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)])),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 11.5, fontWeight: FontWeight.w600)),
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
  final String sub;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.sub, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800)),
              Text(sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.75))),
            ],
          ),
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

  String _fmt(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final inside = timeOut == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: inside ? AppTheme.primaryDim : AppTheme.bgCardAlt,
                radius: 22,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: inside ? AppTheme.primary : AppTheme.textMuted, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              if (inside)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, border: Border.all(color: AppTheme.bgCard, width: 1.5)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                Text('In: ${_fmt(timeIn)}${timeOut != null ? ' · Out: ${_fmt(timeOut!)}' : ''}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: inside ? const LinearGradient(colors: [AppTheme.primary, Color(0xFF0A9A3F)]) : null,
              color: inside ? null : AppTheme.bgCardAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(inside ? 'Inside • ${DateTime.now().difference(timeIn).inMinutes}m' : 'Left',
                style: TextStyle(fontSize: 11, color: inside ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
