import 'package:flutter/material.dart';
import '../../app_tokens.dart';
import '../../services/supabase_service.dart';

/// Shell SB Admin 2 — sidebar gelap, topbar putih, area konten terang.
class AdminLayout extends StatefulWidget {
  const AdminLayout({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.onRefresh,
  });

  final String title;
  final String currentRoute;
  final Widget child;
  final VoidCallback? onRefresh;

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _navItems = [
    _NavItem(
      route: '/admin/dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
    ),
    _NavItem(
      route: '/admin/laporan',
      label: 'Laporan',
      icon: Icons.report_problem_rounded,
    ),
    _NavItem(
      route: '/admin/users',
      label: 'Pengguna',
      icon: Icons.people_alt_rounded,
    ),
    _NavItem(
      route: '/admin/rewards',
      label: 'Reward',
      icon: Icons.card_giftcard_rounded,
    ),
    _NavItem(
      route: '/admin/quotes',
      label: 'Quotes',
      icon: Icons.format_quote_rounded,
    ),
    _NavItem(
      route: '/admin/faqs',
      label: 'FAQ',
      icon: Icons.help_outline_rounded,
    ),
    _NavItem(
      route: '/admin/panduan',
      label: 'Panduan',
      icon: Icons.menu_book_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SupabaseService.instance.isAdminLoggedIn && mounted) {
        Navigator.pushReplacementNamed(context, '/admin-login');
      }
    });
  }

  void _navigate(String route) {
    if (route == widget.currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }

  void _logout() {
    SupabaseService.instance.logoutAdmin();
    Navigator.pushReplacementNamed(context, '/admin-login');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 992;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: SibersihColors.surfaceLight,
      body: Row(
        children: [
          if (isWide) _buildSidebar(isWide: true),
          Expanded(
            child: Column(
              children: [
                _buildTopbar(isWide),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: widget.child,
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              width: 240,
              child: _buildSidebar(isWide: false),
            ),
    );
  }

  Widget _buildSidebar({required bool isWide}) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SibersihColors.primaryDeep,
            SibersihColors.primary,
            Color(0xFF1A12C8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🌿', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SIBERSIH',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1, indent: 16, endIndent: 16),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'MENU UTAMA',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ..._navItems.map((item) => _sidebarItem(item)),
            const Spacer(),
            const Divider(color: Colors.white24, height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
              title: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              onTap: _logout,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(_NavItem item) {
    final active = widget.currentRoute == item.route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            final isWide = MediaQuery.of(context).size.width >= 992;
            if (!isWide) _scaffoldKey.currentState?.closeDrawer();
            _navigate(item.route);
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopbar(bool isWide) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              if (!isWide)
                IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  color: SibersihColors.primary,
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E2E4A),
                  ),
                ),
              ),
              if (widget.onRefresh != null)
                IconButton(
                  tooltip: 'Muat ulang',
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh_rounded, color: SibersihColors.primary),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SibersihColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded,
                        size: 18, color: SibersihColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'admin',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: SibersihColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        color: Colors.white,
      ),
      child: const Center(
        child: Text(
          'Copyright © Sibersih Admin 2026',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}

/// Kartu statistik gaya SB Admin 2 — border kiri berwarna.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E2E4A),
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.grey.shade300, size: 36),
        ],
      ),
    );
  }
}

/// Panel konten putih dengan header.
class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: SibersihColors.primary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}
