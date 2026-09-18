import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../admin/admin_dashboard.dart';
import '../services/auth_service.dart';
import '../app_theme.dart';
import '../user/member_dashboard.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    try {
      final role = await AuthService()
          .getUserRole(user.uid)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'admin'
              ? const AdminDashboard()
              : const MemberDashboard(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gym image background
          Image.asset(
            'assets/images/gym_hero.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppTheme.bg),
          ),
          // Dark + green gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  AppTheme.bg.withValues(alpha: 0.78),
                  AppTheme.bg.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
          // Subtle green vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  AppTheme.primary.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
          // Content
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.primaryDim,
                              blurRadius: 40,
                              spreadRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.fitness_center,
                          color: Colors.white, size: 56),
                    ),
                    const SizedBox(height: 28),
                    const Text('GORILLA GYM',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 5,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 2))
                          ],
                        )),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryDim,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: const Text('STRENGTH  •  FOCUS  •  DISCIPLINE',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            letterSpacing: 2.2,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    const SizedBox(height: 10),
                    const Text('Management System',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          letterSpacing: 3,
                        )),
                    const SizedBox(height: 56),
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
