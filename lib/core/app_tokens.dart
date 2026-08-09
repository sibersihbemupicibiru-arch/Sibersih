import 'package:flutter/material.dart';

/// Warna dan nilai konsisten untuk UI Sibersih.
abstract final class SibersihColors {
  // ── Primary blue palette ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF1007BA);
  static const Color primaryDeep = Color(0xFF0A05A0);
  static const Color primaryLight = Color(0xFF2519D4);
  static const Color primaryGlow = Color(0xFF4C3FE8);
  static const Color primaryMid = Color(0xFF3729E0);

  // ── Accent / complementary ────────────────────────────────────────────────
  static const Color accent = Color(0xFF4C3FE8);
  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentMint = Color(0xFF00E5C0);
  static const Color accentPurple = Color(0xFF7B6FFF);

  // ── Surface ───────────────────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF0F2FF);
  static const Color surfaceDark = Color(0xFF0B0B1E);
  static const Color cardDark = Color(0xFF13132A);
  static const Color cardDark2 = Color(0xFF1A1A35);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFAA22);
  static const Color error = Color(0xFFFF4D6A);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeep, primary, primaryLight],
  );

  static const LinearGradient heroGradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A05A0), Color(0xFF1007BA), Color(0xFF2519D4), Color(0xFF4C3FE8)],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryGlow],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A35), Color(0xFF13132A)],
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get primaryGlowShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.45),
          blurRadius: 28,
          spreadRadius: 0,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Border radius tokens
abstract final class SibersihRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double pill = 100;
}

/// Spacing tokens
abstract final class SibersihSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
