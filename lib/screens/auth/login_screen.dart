import 'package:flutter/material.dart';
import 'dart:ui';
import '../../app_theme.dart';
import '../../services/auth_service.dart';
import '../../admin/admin_dashboard.dart';
import '../../user/member_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService()
          .signIn(_emailCtrl.text, _passCtrl.text)
          .timeout(const Duration(seconds: 8), onTimeout: () {
        throw Exception('Login timed out. Check internet or try admin/admin123');
      });
      if (!mounted) return;
      if (user == null) throw Exception('User not found.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user.role == 'admin'
              ? const AdminDashboard()
              : const MemberDashboard(),
        ),
      );
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('TimeoutException') || msg.contains('timed out')) {
        msg = 'Dugay kaayo — timeout. Check internet then try again. (admin / admin123)';
      } else if (msg.contains('wrong-password') || msg.contains('INVALID_LOGIN_CREDENTIALS')) {
        msg = 'Sayop ang password. Try admin123';
      } else if (msg.contains('user-not-found') || msg.contains('INVALID_LOGIN_CREDENTIALS')) {
        msg = 'Wala nakit-an ang account. Use admin / admin123 or contact admin.';
      } else if (msg.contains('network-request-failed')) {
        msg = 'Walay internet. Check WiFi/data.';
      }
      if (!mounted) return;
      setState(() {
        _error = msg;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 860;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gym image
          Image.asset(
            'assets/images/gym_hero.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppTheme.bg),
          ),
          // Dark green overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withValues(alpha: 0.58),
                  AppTheme.bg.withValues(alpha: 0.82),
                  AppTheme.primaryDeep.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          // Vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
              ),
            ),
          ),
          // Content
          isWide ? _buildWide() : _buildNarrow(),
        ],
      ),
    );
  }

  Widget _buildWide() {
    return Row(
      children: [
        // Left branding 55%
        Expanded(
          flex: 11,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 48, 32, 48),
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF0A9A3F)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppTheme.primaryDim, blurRadius: 28, spreadRadius: 2)],
                    ),
                    child: const Icon(Icons.fitness_center, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 28),
                  const Text('GORILLA GYM',
                      style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 6,
                          height: 1)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(20)),
                    child: const Text('STRENGTH  •  FOCUS  •  DISCIPLINE',
                        style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2.2, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Premium management for athletes who never quit. Track members, attendance, and growth — all in one dark, fast app.',
                    style: TextStyle(color: Color(0xFFC8D8D0), fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _featureChip(Icons.bolt, 'Fast check-in'),
                      const SizedBox(width: 10),
                      _featureChip(Icons.qr_code_2, 'QR Access'),
                      const SizedBox(width: 10),
                      _featureChip(Icons.shield_outlined, 'Secure'),
                    ],
                  ),
                  const Spacer(),
                  const Text('© 2025 Gorilla Gym • Dark Green Edition',
                      style: TextStyle(color: AppTheme.textDim, fontSize: 11, letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ),
        // Right form 45%
        Expanded(
          flex: 9,
          child: Center(
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: _glassForm(maxWidth: 420),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow() {
    return Center(
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _glassForm(maxWidth: 420),
          ),
        ),
      ),
    );
  }

  Widget _glassForm({double maxWidth = 420}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.32), blurRadius: 32, offset: const Offset(0, 12)),
                BoxShadow(color: AppTheme.primary.withValues(alpha: 0.08), blurRadius: 48, spreadRadius: 2),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mini logo inside card for narrow
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF0A9A3F)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.fitness_center, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('Sign in to continue', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(20)),
                        child: const Text('v1.0', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: AppTheme.inputDecoration('Email or username', icon: Icons.email_outlined),
                    validator: (v) => (v?.trim().isNotEmpty ?? false) ? null : 'Required',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: AppTheme.inputDecoration('Password', icon: Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textMuted, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Min 6 characters',
                  ),
                  const SizedBox(height: 10),
                  // Hint
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: const [
                        Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 14),
                        SizedBox(width: 6),
                        Expanded(
                            child: Text('Demo: admin / admin123  →  admin@gorillagym.com',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 11))),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.redDim,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.red.withValues(alpha: 0.28)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.red, fontSize: 13, height: 1.3))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        shadowColor: AppTheme.primaryDim,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text('Gorilla Gym Management System • Dark Green Premium',
                        style: AppTheme.caption.copyWith(fontSize: 10), textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryLight, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
