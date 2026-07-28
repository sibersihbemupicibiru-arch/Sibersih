import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_routes.dart';

import 'app_tokens.dart';

import 'pages/splash_page.dart';

import 'pages/landing_page.dart';

import 'pages/login_page.dart';

import 'pages/register_page.dart';

import 'pages/main_page.dart';

import 'pages/admin/admin_login_page.dart';

import 'pages/admin/admin_dashboard_page.dart';

import 'pages/admin/admin_laporan_page.dart';

import 'pages/admin/admin_users_page.dart';

import 'pages/admin/admin_rewards_page.dart';
import 'pages/admin/admin_quotes_page.dart';
import 'pages/admin/admin_faqs_page.dart';
import 'pages/admin/admin_panduan_page.dart';

import 'services/supabase_service.dart';



Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(

    url: 'https://ciaykezzojnksqlsioqh.supabase.co',

    anonKey:

        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw',

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

  String _currentRoute = resolveInitialRoute();



  bool get _onAdminRoute =>

      isAdminRoute(_currentRoute) || isAdminRoute(readWebHashRoute());



  @override

  void initState() {

    super.initState();



    // Listener auth hanya untuk alur user — jangan ganggu route admin.

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {

      if (_onAdminRoute) return;



      final event = data.event;

      if (event == AuthChangeEvent.signedIn && data.session != null) {

        await SupabaseService.instance.ensureUserRecord();

        _navigatorKey.currentState?.pushNamedAndRemoveUntil(

          '/home',

          (route) => false,

        );

      } else if (event == AuthChangeEvent.signedOut &&

          _currentRoute == '/home') {

        _navigatorKey.currentState?.pushNamedAndRemoveUntil(

          '/landing',

          (route) => false,

        );

      }

    });

  }



  void toggleTheme(bool val) => setState(() => _isDarkMode = val);



  Route<dynamic> _buildRoute(RouteSettings settings) {

    final name = settings.name ?? '/';



    switch (name) {

      case '/':

        if (isAdminRoute(readWebHashRoute())) {

          return _fade(const AdminLoginPage(), RouteSettings(name: '/admin-login'));

        }

        return _fade(const SplashPage(), settings);

      case '/landing':

        return _slide(const LandingPage(), settings);

      case '/login':

        return _slide(const LoginPage(), settings);

      case '/register':

        return _slide(const RegisterPage(), settings);

      case '/home':

        return _fade(

          MainPage(onToggleTheme: toggleTheme, isDarkMode: _isDarkMode),

          settings,

        );

      case '/admin-login':

        return _fade(const AdminLoginPage(), settings);

      case '/admin':

      case '/admin/dashboard':

        return _fade(const AdminDashboardPage(), settings);

      case '/admin/laporan':

        return _fade(const AdminLaporanPage(), settings);

      case '/admin/users':

        return _fade(const AdminUsersPage(), settings);

      case '/admin/rewards':

        return _fade(const AdminRewardsPage(), settings);

      case '/admin/quotes':

        return _fade(const AdminQuotesPage(), settings);

      case '/admin/faqs':

        return _fade(const AdminFaqsPage(), settings);

      case '/admin/panduan':

        return _fade(const AdminPanduanPage(), settings);

      default:

        if (name.startsWith('/admin')) {

          return _fade(const AdminLoginPage(), RouteSettings(name: '/admin-login'));

        }

        return _fade(const SplashPage(), settings);

    }

  }



  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      navigatorKey: _navigatorKey,

      title: 'Sibersih',

      debugShowCheckedModeBanner: false,

      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: _buildLightTheme(),

      darkTheme: _buildDarkTheme(),

      onGenerateInitialRoutes: (String platformRoute) {

        final route = resolveInitialRoute(platformRoute);

        return [_buildRoute(RouteSettings(name: route))];

      },

      onGenerateRoute: _buildRoute,

      navigatorObservers: [

        _RouteTracker((route) => _currentRoute = route),

      ],

      builder: (context, child) {

        final theme = Theme.of(context);

        final isDark = theme.brightness == Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(

          value: SystemUiOverlayStyle(

            statusBarColor: Colors.transparent,

            statusBarIconBrightness:

                isDark ? Brightness.light : Brightness.dark,

            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,

            systemNavigationBarColor: theme.scaffoldBackgroundColor,

            systemNavigationBarIconBrightness:

                isDark ? Brightness.light : Brightness.dark,

          ),

          child: child ?? const SizedBox.shrink(),

        );

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

        cardTheme: CardThemeData(

          elevation: 0,

          shape:

              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

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

            borderSide:

                const BorderSide(color: SibersihColors.primary, width: 1.5),

          ),

          contentPadding:

              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        ),

        elevatedButtonTheme: ElevatedButtonThemeData(

          style: ElevatedButton.styleFrom(

            elevation: 4,

            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),

            shape:

                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

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

          shape:

              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

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

        cardTheme: CardThemeData(

          elevation: 0,

          shape:

              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

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

          contentPadding:

              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        ),

        elevatedButtonTheme: ElevatedButtonThemeData(

          style: ElevatedButton.styleFrom(

            elevation: 4,

            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),

            shape:

                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

          ),

        ),

        switchTheme: SwitchThemeData(

          thumbColor: WidgetStateProperty.resolveWith((states) {

            if (states.contains(WidgetState.selected)) return Colors.white;

            return Colors.grey.shade600;

          }),

          trackColor: WidgetStateProperty.resolveWith((states) {

            if (states.contains(WidgetState.selected)) {

              return const Color(0xFF4C3FE8);

            }

            return Colors.grey.shade800;

          }),

        ),

        snackBarTheme: SnackBarThemeData(

          behavior: SnackBarBehavior.floating,

          shape:

              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        ),

      );



  PageRouteBuilder<dynamic> _fade(Widget page, RouteSettings settings) =>

      PageRouteBuilder(

        settings: settings,

        pageBuilder: (_, a, __) => page,

        transitionsBuilder: (_, a, __, child) =>

            FadeTransition(opacity: a, child: child),

        transitionDuration: const Duration(milliseconds: 600),

      );



  PageRouteBuilder<dynamic> _slide(Widget page, RouteSettings settings) =>

      PageRouteBuilder(

        settings: settings,

        pageBuilder: (_, a, __) => page,

        transitionsBuilder: (_, a, __, child) => SlideTransition(

          position: Tween(begin: const Offset(1, 0), end: Offset.zero)

              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),

          child: child,

        ),

        transitionDuration: const Duration(milliseconds: 450),

      );

}



class _RouteTracker extends NavigatorObserver {

  _RouteTracker(this.onRouteChanged);



  final ValueChanged<String> onRouteChanged;



  void _track(Route<dynamic>? route) {

    final name = route?.settings.name;

    if (name != null) onRouteChanged(name);

  }



  @override

  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {

    _track(route);

  }



  @override

  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {

    _track(newRoute);

  }



  @override

  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {

    _track(previousRoute);

  }

}


