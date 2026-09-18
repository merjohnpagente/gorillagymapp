import 'package:flutter/material.dart';

class AppTheme {
  // ── Core Dark + Green Palette ─────────────────────────────────────────────
  static const Color bg = Color(0xFF070A08);
  static const Color bgCard = Color(0xFF111816);
  static const Color bgCardAlt = Color(0xFF19211E);
  static const Color border = Color(0xFF1E2E28);

  // Primary — Emerald (replaces orange)
  static const Color primary = Color(0xFF00C950);
  static const Color primaryLight = Color(0xFF22D96A);
  static const Color primaryDim = Color(0x3300C950);
  static const Color primaryGlow = Color(0x1A00C950);
  static const Color primaryMuted = Color(0xFF0F2A1A);

  // Aliases — keep orange working for incremental migration (deprecated)
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

  // Text Styles
  static const TextStyle displayLg = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: white,
    letterSpacing: -1,
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

  // Decoration
  static BoxDecoration card({Color? color, bool glowOrange = false, bool glowPrimary = false}) =>
      BoxDecoration(
        color: color ?? bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: (glowOrange || glowPrimary)
            ? [const BoxShadow(color: primaryDim, blurRadius: 24, spreadRadius: 2)]
            : null,
      );

  static InputDecoration inputDecoration(String label, {IconData? icon}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        prefixIcon:
            icon != null ? Icon(icon, color: textMuted, size: 20) : null,
        filled: true,
        fillColor: bgCardAlt,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}
