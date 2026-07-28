import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'repositories/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugProfileBuildsEnabled = true;

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authCallbackUrlHostname: kIsWeb ? null : AppConfig.authCallbackHost,
    authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
  );

  // Tangani callback URL saat web OAuth redirect kembali ke app
  final uri = Uri.base;
  if (uri.queryParameters.containsKey('access_token') ||
      uri.queryParameters.containsKey('code') ||
      uri.queryParameters.containsKey('session') ||
      uri.queryParameters.containsKey('error')) {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (_) {
      // Abaikan jika tidak ada auth session.
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
    //
    // PENTING: Listener ini HANYA menangani Google OAuth.
    // Register manual (email+password) punya flow sendiri:
    //   register_page → /email-confirmation → user verify → login manual.
    // Kalau listener ini ikut campur flow manual, user akan ter-redirect
    // ke /register lagi (Google mode) karena profil belum sempat diinsert,
    // sehingga user harus isi data dua kali.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        final user = Supabase.instance.client.auth.currentUser!;

        // Cek apakah login via Google OAuth
        final identities = user.identities ?? [];
        final isGoogleUser = user.appMetadata['provider'] == 'google' ||
            identities.any((i) => i.provider == 'google');

        // ── Kalau bukan Google (email/password biasa), SKIP ──
        // Flow manual diurus sendiri oleh register_page & login_page.
        // Jangan redirect paksa di sini agar konfirmasi email bisa jalan.
        if (!isGoogleUser) return;

        // Kalau email belum verified (seharusnya tidak terjadi di Google,
        // tapi dijaga untuk keamanan)
        if (user.emailConfirmedAt == null) return;

        // Cek apakah profil (nim, nama, jurusan) sudah ada di tabel users
        final hasProfile =
            await AuthRepository.instance.isProfileComplete(user.id);

        if (hasProfile) {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        } else {
          // First-time Google login → isi profil dulu
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/register',
            (route) => false,
            arguments: user.email,
          );
        }
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
      navigatorKey: _navigatorKey,
      title: 'Sibersih',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      initialRoute: '/',
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      onGenerateRoute: (settings) => AppRouter.generateRoute(
        settings,
        onToggleTheme: toggleTheme,
      ),
    );
  }
}
