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
import '../features/auth/pages/forgot_password_page.dart';
import '../features/auth/pages/reset_password_page.dart';
import '../features/dashboard/pages/main_page.dart';

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
      case '/forgot-password':
        return _slide(const ForgotPasswordPage());
      case '/reset-password':
        return _slide(const ResetPasswordPage());
      case '/home':
        return _fade(MainPage(
          onToggleTheme: onToggleTheme,
        ));
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
