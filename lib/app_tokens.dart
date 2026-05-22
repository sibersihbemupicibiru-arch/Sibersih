import 'package:flutter/material.dart';

/// Warna dan nilai konsisten untuk UI Sibersih.
abstract final class SibersihColors {
  static const Color primary = Color(0xFF1007BA);
  static const Color primaryDeep = Color(0xFF0A05A0);
  static const Color accent = Color(0xFF4C3FE8);
  static const Color surfaceLight = Color(0xFFF4F6FF);
  static const Color surfaceDark = Color(0xFF0F0F23);
  static const Color cardDark = Color(0xFF1A1A2E);

  static LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDeep, primary, Color(0xFF2519D4)],
      );
}

abstract final class AppTokens {
  static const String supabaseUrl = 'https://YOUR-PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
}
