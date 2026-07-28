import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dashboard_page.dart';
import '../../laporan/pages/laporan_sampah_page.dart';
import '../../riwayat/pages/riwayat_page.dart';
import '../../profil/pages/profil_page.dart';
import '../../panduan/pages/panduan_page.dart';
import '../../../core/app_tokens.dart';

class MainPage extends StatefulWidget {
  final void Function(bool) onToggleTheme;

  const MainPage({
    super.key,
    required this.onToggleTheme,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabController;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();

    _pages = [
      const DashboardPage(),
      const LaporanSampahPage(),
      const RiwayatPage(),
      const PanduanPage(),
      ProfilPage(
        onToggleTheme: widget.onToggleTheme,
      ),
    ];
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.025), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Items: 0=Dashboard, 1=Laporan(center FAB), 2=Riwayat, 3=Panduan, 4=Profil
    // Layout: Dashboard | Riwayat | [FAB Laporan] | Panduan | Profil
    final navItems = [
      _NavItemData(icon: Icons.home_rounded, label: 'Beranda', pageIndex: 0),
      _NavItemData(icon: Icons.history_rounded, label: 'Riwayat', pageIndex: 2),
      _NavItemData(icon: Icons.camera_alt_rounded, label: 'Laporan', pageIndex: 1, isFab: true),
      _NavItemData(icon: Icons.menu_book_rounded, label: 'Panduan', pageIndex: 3),
      _NavItemData(icon: Icons.person_rounded, label: 'Profil', pageIndex: 4),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SibersihRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark
                  ? SibersihColors.cardDark.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(SibersihRadius.xl),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : SibersihColors.primary.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: SibersihColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: navItems.map((item) {
                final isSelected = _selectedIndex == item.pageIndex;
                if (item.isFab) {
                  return _buildFabItem(item, isSelected);
                }
                return _buildNavItem(item, isSelected, isDark);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItemData item, bool isSelected, bool isDark) {
    return Expanded(
      child: _NavItemWidget(
        item: item,
        isSelected: isSelected,
        isDark: isDark,
        onTap: () => _onItemTapped(item.pageIndex),
      ),
    );
  }

  Widget _buildFabItem(_NavItemData item, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _onItemTapped(item.pageIndex);
        },
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            width: isSelected ? 58 : 52,
            height: isSelected ? 58 : 52,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [SibersihColors.primaryGlow, SibersihColors.primary],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [SibersihColors.primary, SibersihColors.primaryDeep],
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SibersihColors.primary.withValues(alpha: isSelected ? 0.6 : 0.4),
                  blurRadius: isSelected ? 20 : 12,
                  spreadRadius: isSelected ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              color: Colors.white,
              size: isSelected ? 26 : 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final int pageIndex;
  final bool isFab;

  _NavItemData({
    required this.icon,
    required this.label,
    required this.pageIndex,
    this.isFab = false,
  });
}

class _NavItemWidget extends StatefulWidget {
  final _NavItemData item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant _NavItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, __) => Transform.scale(
          scale: _scaleAnim.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? SibersihColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(SibersihRadius.md),
                ),
                child: Icon(
                  widget.item.icon,
                  color: widget.isSelected
                      ? SibersihColors.primary
                      : (widget.isDark
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.grey.shade400),
                  size: 22,
                ),
              ),
              const SizedBox(height: 1),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: widget.isSelected
                      ? SibersihColors.primary
                      : (widget.isDark
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.grey.shade400),
                  fontSize: 10,
                  fontWeight: widget.isSelected
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
