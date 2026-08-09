// ============================================================
// APP THEME — Upgraded
// ============================================================

import 'package:flutter/material.dart';
import '../core/app_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SibersihColors.primary,
          primary: SibersihColors.primary,
          secondary: SibersihColors.accent,
          tertiary: SibersihColors.accentCyan,
          surface: Colors.white,
          surfaceContainerHighest: SibersihColors.surfaceLight,
        ),
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: SibersihColors.surfaceLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: SibersihColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SibersihRadius.lg)),
          color: Colors.white,
          shadowColor: Colors.black12,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SibersihColors.primary.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SibersihRadius.sm),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SibersihRadius.sm),
            borderSide: const BorderSide(
                color: SibersihColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SibersihRadius.sm),
            borderSide: const BorderSide(
                color: SibersihColors.error, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIconColor: SibersihColors.primary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 6,
            shadowColor: SibersihColors.primary.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SibersihRadius.md)),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SibersihRadius.md)),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return Colors.grey.shade400;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return SibersihColors.primary;
            }
            return Colors.grey.shade300;
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: SibersihColors.primary,
          contentTextStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SibersihRadius.sm)),
          elevation: 8,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFEEF0FF),
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SibersihColors.primary,
          brightness: Brightness.dark,
          primary: SibersihColors.primaryGlow,
          secondary: SibersihColors.accentPurple,
          tertiary: SibersihColors.accentCyan,
          surface: SibersihColors.cardDark,
          surfaceContainerHighest: SibersihColors.surfaceDark,
        ),
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: SibersihColors.surfaceDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: SibersihColors.cardDark,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SibersihRadius.lg)),
          color: SibersihColors.cardDark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.07),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SibersihRadius.sm),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SibersihRadius.sm),
            borderSide: const BorderSide(
                color: SibersihColors.accentPurple, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIconColor: SibersihColors.accentPurple,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 6,
            shadowColor: SibersihColors.primaryGlow.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SibersihRadius.md)),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return Colors.grey.shade600;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return SibersihColors.primaryGlow;
            }
            return Colors.grey.shade800;
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: SibersihColors.primaryGlow,
          contentTextStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SibersihRadius.sm)),
          elevation: 8,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.08),
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      );
}
