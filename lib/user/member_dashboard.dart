import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_theme.dart';
import '../models/gym_user.dart';
import '../models/attendance.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../screens/auth/login_screen.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  GymUser? _user;
  List<Attendance> _history = [];
  bool _loading = true;
  int _tab = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final user = await AuthService()
          .getUserById(firebaseUser.uid)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      if (user == null) {
        setState(() {
          _loadError =
              'Profile not found. Please contact admin to complete your registration.';
          _loading = false;
        });
        return;
      }

      List<Attendance> history = [];
      try {
        history = await AttendanceService()
            .memberHistory(firebaseUser.uid)
            .timeout(const Duration(seconds: 3), onTimeout: () => []);
      } catch (_) {}

      setState(() {
        _user = user;
        _history = history;
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Failed to load profile. Please pull to refresh.';
        _loading = false;
      });
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
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.red, size: 48),
                const SizedBox(height: 16),
                Text(_loadError!, style: AppTheme.bodyMuted, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _loading = true);
                        _load();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      child: const Text('Retry'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _signOut,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_user == null) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('User not found', style: AppTheme.bodyMuted),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      bottomNavigationBar:
          _BottomNav(selected: _tab, onTap: (i) => setState(() => _tab = i)),
      body: _tab == 0 ? _buildHome() : _buildHistory(),
    );
  }

  Widget _buildHome() {
    final user = _user!;
    final active = user.isMembershipActive;
    final safeInitial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final firstName = user.name.split(' ').firstWhere((s) => s.isNotEmpty, orElse: () => 'Member');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryDim,
                  child: Text(safeInitial,
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, $firstName!', style: AppTheme.displayMd),
                      const Text('Member Portal', style: AppTheme.bodyMuted),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_outlined, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Membership status card — nindot premium
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: active
                      ? [const Color(0xFF0F2A1A), const Color(0xFF0A1F14), const Color(0xFF111816)]
                      : [const Color(0xFF2A1A12), const Color(0xFF1F140A), const Color(0xFF111816)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppTheme.primary.withValues(alpha: 0.32) : AppTheme.red.withValues(alpha: 0.28),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(color: (active ? AppTheme.primary : AppTheme.red).withValues(alpha: 0.12), blurRadius: 18, spreadRadius: 1),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Membership Status',
                          style: AppTheme.label.copyWith(color: AppTheme.textDim)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.primaryDim : AppTheme.redDim,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(active ? 'ACTIVE' : 'EXPIRED',
                            style: TextStyle(
                              color: active ? AppTheme.primary : AppTheme.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    active ? '${user.daysRemaining} days left' : 'Membership Expired',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: active ? AppTheme.primary : AppTheme.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.membershipExpiry != null
                        ? 'Expires ${user.membershipExpiry!.day}/${user.membershipExpiry!.month}/${user.membershipExpiry!.year}'
                        : 'No expiry set',
                    style: AppTheme.bodyMuted,
                  ),
                  const SizedBox(height: 14),
                  // Progress for nindot
                  Builder(builder: (_) {
                    final total = user.membershipType == 'annual'
                        ? 365
                        : user.membershipType == 'quarterly'
                            ? 90
                            : 30;
                    final progress = active ? (user.daysRemaining / total).clamp(0.0, 1.0) : 0.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${(progress * 100).toInt()}% remaining', style: TextStyle(color: active ? AppTheme.primaryLight : AppTheme.textDim, fontSize: 11, fontWeight: FontWeight.w700)),
                            Text('$total days plan', style: TextStyle(color: AppTheme.textDim, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(active ? AppTheme.primary : AppTheme.red),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppTheme.bgCardAlt, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_membership_rounded, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              user.membershipType != null
                                  ? '${user.membershipType![0].toUpperCase()}${user.membershipType!.substring(1)} Plan'
                                  : 'No Plan',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.verified_rounded, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(active ? 'Verified Member' : 'Expired', style: TextStyle(color: active ? AppTheme.primary : AppTheme.red, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // QR Code Card — nindot glass + green glow when active
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: active ? [const Color(0xFF0F1F15), const Color(0xFF111816)] : [AppTheme.bgCard, AppTheme.bgCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: active ? AppTheme.primary.withValues(alpha: 0.24) : AppTheme.border, width: 1.2),
                boxShadow: [
                  if (active) BoxShadow(color: AppTheme.primary.withValues(alpha: 0.18), blurRadius: 28, spreadRadius: 2),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 18, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  const Text('YOUR QR CODE', style: AppTheme.label),
                  const SizedBox(height: 4),
                  const Text('Show this to the admin for attendance',
                      style: AppTheme.bodyMuted, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: user.uid,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF070A08),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF070A08),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(user.email, style: AppTheme.bodyMuted.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                Expanded(child: _statMini('Total Visits', '${_history.length}', Icons.fitness_center)),
                const SizedBox(width: 12),
                Expanded(
                    child: _statMini(
                        'This Month',
                        '${_history.where((a) => a.timeIn.month == DateTime.now().month).length}',
                        Icons.calendar_today_outlined)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text('Attendance History', style: AppTheme.displayMd),
          ),
          Expanded(
            child: _history.isEmpty
                ? const Center(
                    child: Text('No attendance records yet', style: AppTheme.bodyMuted))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final att = _history[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.card(),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryDim,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.fitness_center,
                                  color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${att.timeIn.day}/${att.timeIn.month}/${att.timeIn.year}',
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'In: ${_fmt(att.timeIn)}${att.timeOut != null ? ' · Out: ${_fmt(att.timeOut!)}' : ''}',
                                    style: AppTheme.bodyMuted.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.bgCardAlt,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(att.durationStr,
                                  style: AppTheme.bodyMuted.copyWith(
                                      fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Widget _statMini(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card(),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(label, style: AppTheme.bodyMuted.copyWith(fontSize: 11)),
            ],
          ),
        ],
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
      (Icons.home_outlined, Icons.home, 'Home'),
      (Icons.history_outlined, Icons.history, 'History'),
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
              final (outline, filled, label) = items[i];
              final active = i == selected;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primaryDim : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(active ? filled : outline,
                          color: active ? AppTheme.primary : AppTheme.textMuted, size: 24),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                            fontSize: 11,
                            color: active ? AppTheme.primary : AppTheme.textMuted,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
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
