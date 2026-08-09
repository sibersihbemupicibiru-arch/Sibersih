// ============================================================
// APP ROUTER
// Dipindah dari _SibersihAppState di main.dart.
// Semua route dan transisi halaman dikumpulkan di sini.
// ============================================================

import 'package:flutter/material.dart';
import '../features/auth/pages/splash_page.dart';
import '../features/auth/pages/landing_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/auth/pages/email_confirmation_page.dart';
import '../features/dashboard/pages/main_page.dart';

// Admin pages
import '../pages/admin/admin_login_page.dart';
import '../pages/admin/admin_dashboard_page.dart';
import '../pages/admin/admin_laporan_page.dart';
import '../pages/admin/admin_users_page.dart';
import '../pages/admin/admin_rewards_page.dart';
import '../pages/admin/admin_quotes_page.dart';
import '../pages/admin/admin_faqs_page.dart';
import '../pages/admin/admin_panduan_page.dart';

abstract final class AppRouter {
  /// Callback untuk toggle theme — dikirim dari [SibersihApp] ke [MainPage].
  static Route<dynamic>? generateRoute(
    RouteSettings settings, {
    required void Function(bool) onToggleTheme,
  }) {
    switch (settings.name) {
      case '/':
        return _fade(const SplashPage());
      case '/landing':
        return _slide(const LandingPage());
      case '/login':
        return _slide(const LoginPage());
      case '/register':
        final email = settings.arguments as String?;
        return _slide(RegisterPage(googleEmail: email));
      case '/email-confirmation':
        final email = settings.arguments as String;
        return _slide(EmailConfirmationPage(email: email));
      case '/home':
        return _fade(MainPage(
          onToggleTheme: onToggleTheme,
        ));
        
      // Admin routes
      case '/admin-login':
        return _fade(const AdminLoginPage());
      case '/admin/dashboard':
        return _fade(const AdminDashboardPage());
      case '/admin/laporan':
        return _fade(const AdminLaporanPage());
      case '/admin/users':
        return _fade(const AdminUsersPage());
      case '/admin/rewards':
        return _fade(const AdminRewardsPage());
      case '/admin/quotes':
        return _fade(const AdminQuotesPage());
      case '/admin/faqs':
        return _fade(const AdminFaqsPage());
      case '/admin/panduan':
        return _fade(const AdminPanduanPage());
        
      default:
        return _fade(const SplashPage());
    }
  }

  static PageRouteBuilder<dynamic> _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      );

  static PageRouteBuilder<dynamic> _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 450),
      );
}
