import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  // ── Core Dark + Green Palette ─────────────────────────────────────────────
  static const Color bg = Color(0xFF070A08);
  static const Color bgCard = Color(0xFF111816);
  static const Color bgCardAlt = Color(0xFF19211E);
  static const Color border = Color(0xFF1E2E28);
  static const Color borderLight = Color(0xFF2A3D34);

  // Primary — Emerald
  static const Color primary = Color(0xFF00C950);
  static const Color primaryLight = Color(0xFF22D96A);
  static const Color primaryDim = Color(0x3300C950);
  static const Color primaryGlow = Color(0x1A00C950);
  static const Color primaryMuted = Color(0xFF0F2A1A);
  static const Color primaryDeep = Color(0xFF0A3D1F);

  @Deprecated('Use primary')
  static const Color orange = primary;
  @Deprecated('Use primaryLight')
  static const Color orangeLight = primaryLight;
  @Deprecated('Use primaryDim')
  static const Color orangeDim = primaryDim;

  static const Color white = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8FA99A);
  static const Color textDim = Color(0xFF5A7068);
  static const Color green = primary;
  static const Color greenDim = primaryDim;
  static const Color red = Color(0xFFEF4444);
  static const Color redDim = Color(0x22EF4444);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueDim = Color(0x223B82F6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDim = Color(0x33F59E0B);

  // Text Styles
  static const TextStyle displayLg = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: white,
    letterSpacing: -1,
    height: 1.1,
  );
  static const TextStyle displayMd = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: white,
    letterSpacing: -0.5,
  );
  static const TextStyle heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: white,
  );
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: white,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: white,
  );
  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textMuted,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textMuted,
    letterSpacing: 1.2,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textMuted,
    letterSpacing: 0.8,
  );

  // ── Nindot helpers ────────────────────────────────────────────────────────
  static BoxDecoration card({Color? color, bool glowOrange = false, bool glowPrimary = false, bool glass = false}) {
    if (glass) {
      return BoxDecoration(
        color: (color ?? bgCard).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderLight.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8)),
          if (glowOrange || glowPrimary)
            const BoxShadow(color: primaryDim, blurRadius: 28, spreadRadius: 2),
        ],
      );
    }
    return BoxDecoration(
      color: color ?? bgCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border, width: 1),
      boxShadow: (glowOrange || glowPrimary)
          ? [const BoxShadow(color: primaryDim, blurRadius: 24, spreadRadius: 2)]
          : null,
    );
  }

  static BoxDecoration gradientCard({List<Color>? colors, bool glow = false}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? [const Color(0xFF0F1F15), const Color(0xFF111816)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border, width: 1),
      boxShadow: glow
          ? [const BoxShadow(color: primaryDim, blurRadius: 24, spreadRadius: 2)]
          : [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
    );
  }

  static BoxDecoration premiumBorder({double radius = 20}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderLight.withValues(alpha: 0.6), width: 1),
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static InputDecoration inputDecoration(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, color: textMuted, size: 20) : null,
        filled: true,
        fillColor: bgCardAlt,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: red, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  // Glass container widget helper
  static Widget glass({required Widget child, double radius = 20, EdgeInsets? padding, Color? color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? bgCard).withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
