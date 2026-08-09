import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Normalisasi path route (selalu diawali `/`, tanpa query).
String normalizeRoute(String raw) {
  var route = raw.trim();
  if (route.isEmpty) return '/';
  if (!route.startsWith('/')) route = '/$route';
  return route.split('?').first;
}

bool isAdminRoute(String? route) {
  if (route == null || route.isEmpty || route == '/') return false;
  return route == '/admin-login' || route.startsWith('/admin');
}

/// Baca route dari hash browser: `/#/admin-login` → `/admin-login`.
String readWebHashRoute() {
  if (!kIsWeb) return '/';
  final hash = Uri.base.fragment.trim();
  if (hash.isNotEmpty) return normalizeRoute(hash);
  return '/';
}

/// Tentukan route awal app — prioritaskan hash / platform route di web.
String resolveInitialRoute([String? platformRoute]) {
  if (kIsWeb) {
    if (platformRoute != null &&
        platformRoute.isNotEmpty &&
        platformRoute != '/') {
      return normalizeRoute(platformRoute);
    }

    final hashRoute = readWebHashRoute();
    if (hashRoute != '/') return hashRoute;

    final defaultName =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (defaultName.isNotEmpty && defaultName != '/') {
      return normalizeRoute(defaultName);
    }
  }

  return '/';
}
