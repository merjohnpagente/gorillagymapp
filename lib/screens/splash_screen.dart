import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _glow;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _fade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack));
    _enterCtrl.forward();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.96, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _glow = Tween<double>(begin: 18, end: 36).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _rotate = Tween<double>(begin: -0.03, end: 0.03).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine));

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
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
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
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
          // Dark + green gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.52),
                  AppTheme.bg.withValues(alpha: 0.72),
                  AppTheme.bg.withValues(alpha: 0.96),
                ],
              ),
            ),
          ),
          // Green vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.25,
                colors: [
                  Colors.transparent,
                  AppTheme.primary.withValues(alpha: 0.07),
                  Colors.black.withValues(alpha: 0.42),
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
                    // Animated nice icon — replaces plain dumbbell
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseScale.value,
                          child: Transform.rotate(
                            angle: _rotate.value,
                            child: child,
                          ),
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _glow,
                        builder: (context, child) {
                          return Container(
                            width: 118,
                            height: 118,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.primary, Color(0xFF0A9A3F)],
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.45),
                                    blurRadius: _glow.value,
                                    spreadRadius: 6),
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8)),
                              ],
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14), width: 1.2),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Shine sweep
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: Align(
                                      alignment: Alignment(-0.6 + _pulseCtrl.value * 0.3, -0.7),
                                      child: Container(
                                        width: 80,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withValues(alpha: 0.0),
                                              Colors.white.withValues(alpha: 0.18),
                                              Colors.white.withValues(alpha: 0.0),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        transform: Matrix4.rotationZ(-0.35),
                                      ),
                                    ),
                                  ),
                                ),
                                // Animated dumbbell with bolt overlay for "nice" feel
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer dumbbell
                                    Icon(Icons.fitness_center,
                                        color: Colors.white.withValues(alpha: 0.96),
                                        size: 58),
                                    // Inner bolt flash — subtle pulse
                                    Positioned(
                                      bottom: 10,
                                      right: 14,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.25),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2))
                                          ],
                                        ),
                                        child: Icon(Icons.bolt,
                                            color: AppTheme.primary,
                                            size: 18 + math.sin(_pulseCtrl.value * math.pi) * 2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 26),
                    // Floating dots to hint animation
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final t = (_pulseCtrl.value + i * 0.33) % 1.0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 6 + t * 2,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.35 + t * 0.5),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),
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
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDim,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.24)),
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
                    const SizedBox(height: 48),
                    // Loading with animated dots
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: AppTheme.primary.withValues(alpha: 0.22),
                              strokeWidth: 3,
                              value: 1,
                            ),
                          ),
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                              strokeWidth: 3,
                            ),
                          ),
                        ],
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
