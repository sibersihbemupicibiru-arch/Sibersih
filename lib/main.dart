import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_tokens.dart';
import 'pages/splash_page.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/main_page.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ciaykezzojnksqlsioqh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw',
    authCallbackUrlHostname: kIsWeb ? null : 'login-callback',
    authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
  );

  final uri = Uri.base;
  if (uri.queryParameters.containsKey('access_token') ||
      uri.queryParameters.containsKey('code') ||
      uri.queryParameters.containsKey('session') ||
      uri.queryParameters.containsKey('error')) {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (_) {
      // Ignore no-code callback when there is no auth session.
    }
  }
  runApp(const SibersihApp());
}

class SibersihApp extends StatefulWidget {
  const SibersihApp({super.key});

  @override
  State<SibersihApp> createState() => _SibersihAppState();
}

class _SibersihAppState extends State<SibersihApp> {
  bool _isDarkMode = false;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // ── Listener auth state ──────────────────────────────────
    // Menangkap event setelah Google OAuth redirect kembali ke app.
    // Ketika Supabase detect sesi baru (signedIn), kita:
    //   1. Pastikan record user ada di tabel users (buat kalau baru)
    //   2. Navigate ke /home
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // Buat user record di Supabase jika belum ada (Google user baru)
        await SupabaseService.instance.ensureUserRecord();

        // Navigate ke home, replace semua route sebelumnya
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      } else if (event == AuthChangeEvent.signedOut) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/landing',
          (route) => false,
        );
      }
    });
  }

  void toggleTheme(bool val) => setState(() => _isDarkMode = val);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: true,
      navigatorKey: _navigatorKey,
      title: 'Sibersih',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      initialRoute: '/',
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _fade(const SplashPage());
          case '/landing':
            return _slide(const LandingPage());
          case '/login':
            return _slide(const LoginPage());
          case '/register':
            return _slide(const RegisterPage());
          case '/home':
            return _fade(MainPage(
              onToggleTheme: toggleTheme,
              isDarkMode: _isDarkMode,
            ));
          default:
            return _fade(const SplashPage());
        }
      },
    );
  }

  ThemeData _buildLightTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SibersihColors.primary,
          primary: SibersihColors.primary,
          secondary: SibersihColors.accent,
          surface: Colors.white,
        ),
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: SibersihColors.surfaceLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: SibersihColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SibersihColors.primary.withOpacity(0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: SibersihColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return Colors.grey.shade400;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return SibersihColors.primary;
            return Colors.grey.shade300;
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  ThemeData _buildDarkTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SibersihColors.primary,
          brightness: Brightness.dark,
          primary: const Color(0xFF4C3FE8),
          secondary: const Color(0xFF7B6FFF),
          surface: SibersihColors.cardDark,
        ),
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: SibersihColors.surfaceDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: SibersihColors.cardDark,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: SibersihColors.cardDark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF7B6FFF), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return Colors.grey.shade600;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const Color(0xFF4C3FE8);
            return Colors.grey.shade800;
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      );

  PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 450),
      );
}
