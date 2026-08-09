import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../models/user_model.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/poin_repository.dart';
import '../../../repositories/laporan_repository.dart';
import '../../../models/laporan_model.dart';
import '../../poin/pages/detail_poin_page.dart';
import '../../poin/pages/tukar_poin_page.dart';
import '../../poin/pages/poin_history_dialog.dart';
import '../../riwayat/pages/riwayat_page.dart';
import '../../../core/app_tokens.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _shimmerController;
  late AnimationController _rankPulseController;

  late Animation<double> _pointsCount;

  int _currentQuote = 0;
  UserModel? _user;
  List<Map<String, String>> _quotes = [];
  bool _loading = true;
  Timer? _quoteTimer;

  int _totalUsers = 2;
  int _userRank = 1;
  List<LaporanModel> _recentLaporans = [];

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _cardsController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _shimmerController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this)
          ..repeat();

    // FIX #1: jangan langsung repeat() di initState.
    // Controller diinit tanpa animasi dulu, repeat() dipanggil di _loadData()
    // setelah data siap, dan dihentikan otomatis setelah beberapa siklus.
    _rankPulseController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _pointsCount = Tween<double>(begin: 0, end: 2850).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    final user = await UserRepository.instance.getCurrentUser();
    
    final results = await Future.wait([
      UserRepository.instance.getTotalUsers(),
      UserRepository.instance.getUserRank(user.uid),
      PoinRepository.instance.getQuotes(),
      LaporanRepository.instance.getRecentLaporans(limit: 5),
    ]);

    if (!mounted) return;
    final totalUsers = results[0] as int;
    final userRank = results[1] as int;
    final quotes = results[2] as List<Map<String, String>>;
    final recentLaporans = results[3] as List<LaporanModel>;

    _pointsCount = Tween<double>(begin: 0, end: user.totalPoin.toDouble())
        .animate(CurvedAnimation(
            parent: _headerController, curve: Curves.easeOutCubic));

    setState(() {
      _user = user;
      _quotes = quotes;
      _totalUsers = totalUsers;
      _userRank = userRank;
      _recentLaporans = recentLaporans;
      _loading = false;
    });

    // Stop shimmer — skeleton sudah tidak tampil
    _shimmerController.stop();

    _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _cardsController.forward();

    // FIX #1 (lanjutan): mulai pulse setelah UI siap, stop otomatis setelah
    // 8 detik (= 4 siklus) supaya engine bisa benar-benar idle.
    _rankPulseController.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) _rankPulseController.stop();
    });

    // Auto-rotate quotes pakai Timer supaya bisa di-cancel saat dispose
    if (_quotes.length > 1) {
      _quoteTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        setState(() => _currentQuote = (_currentQuote + 1) % _quotes.length);
      });
    }
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _headerController.dispose();
    _cardsController.dispose();
    _shimmerController.dispose();
    _rankPulseController.dispose();
    super.dispose();
  }

  void _handleMenuTap(String menu) {
    switch (menu) {
      case 'Detail Poin':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DetailPoinPage()));
        break;
      case 'Poin Masuk':
        _showPoinDialog('masuk');
        break;
      case 'Poin Keluar':
        _showPoinDialog('keluar');
        break;
      case 'Tukar Poin':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TukarPoinPage()));
        break;
    }
  }

  Future<void> _showPoinDialog(String type) async {
    final history = type == 'masuk'
        ? await PoinRepository.instance.getPoinMasukHistory()
        : await PoinRepository.instance.getPoinKeluarHistory();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => PoinHistoryDialog(
        title: type == 'masuk' ? 'Poin Masuk' : 'Poin Keluar',
        type: type,
        history: history,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _loading
          ? _buildSkeleton()
          : RefreshIndicator(
              onRefresh: () async {
                UserRepository.instance.invalidateCache();
                await _loadData();
              },
              color: SibersihColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  _buildHeader(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildPointsCard(),
                        const SizedBox(height: 18),
                        _buildMenuGrid(),
                        const SizedBox(height: 20),
                        _buildRankCard(),
                        const SizedBox(height: 20),
                        _buildQuotesCard(),
                        const SizedBox(height: 20),
                        _buildHowItWorks(),
                        const SizedBox(height: 20),
                        _buildRecentActivity(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── Skeleton loading ─────────────────────────────────────

  // FIX #2: AnimatedBuilder TIDAK lagi membungkus seluruh CustomScrollView.
  // Setiap _skeletonBlock punya AnimatedBuilder sendiri → hanya blok itu
  // yang di-rebuild per frame, bukan seluruh scroll view.
  Widget _buildSkeleton() {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: const Color(0xFF1007BA),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A05A0), Color(0xFF2519D4)],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              List.generate(5, (i) => _skeletonBlock(i)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _skeletonBlock(int i) {
    final heights = [120.0, 80.0, 140.0, 100.0, 60.0];
    // FIX #2 (lanjutan): AnimatedBuilder di dalam tiap blok.
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        final t = (_shimmerController.value + i * 0.2) % 1.0;
        final opacity = 0.3 + 0.3 * math.sin(t * math.pi);
        return Container(
          height: heights[i],
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  // ─── Header ──────────────────────────────────────────────

  Widget _buildHeader() {
    final user = _user!;
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: SibersihColors.primaryDeep,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Mesh gradient background
            Positioned.fill(
              child: CustomPaint(
                painter: _HeaderBgPainter(),
              ),
            ),
            // Decorative SVG-like rings
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -60,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SibersihColors.primaryGlow.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Content
            AnimatedBuilder(
              animation: _headerController,
              builder: (_, __) => Opacity(
                opacity: _headerController.value.clamp(0.0, 1.0),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: SibersihColors.accentCyan
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                              SibersihRadius.xs),
                                          border: Border.all(
                                            color: SibersihColors.accentCyan
                                                .withValues(alpha: 0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Text(
                                          '👋 Selamat Datang',
                                          style: TextStyle(
                                            color: SibersihColors.accentCyan,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    user.nama,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${user.nim} · ${user.jurusan}',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Avatar with ring
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: SibersihColors.accentCyan
                                            .withValues(alpha: 0.6),
                                        width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SibersihColors.accentCyan
                                            .withValues(alpha: 0.25),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                  child: user.fotoUrl != null
                                      ? ClipOval(
                                          child: Image.network(user.fotoUrl!,
                                              fit: BoxFit.cover))
                                      : const Center(
                                          child: Text('🙋',
                                              style:
                                                  TextStyle(fontSize: 28))),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Stat chips row
                        Row(
                          children: [
                            _statChip(
                                Icons.recycling_rounded,
                                '${user.jumlahLaporan}',
                                'Laporan',
                                SibersihColors.accentMint),
                            const SizedBox(width: 8),
                            _statChip(
                                Icons.military_tech_rounded,
                                user.level,
                                'Level',
                                SibersihColors.warning),
                            const SizedBox(width: 8),
                            _statChip(
                                Icons.leaderboard_rounded,
                                '#$_userRank',
                                'Peringkat',
                                SibersihColors.accentCyan),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(SibersihRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55), fontSize: 9.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─── Points card ─────────────────────────────────────────

  Widget _buildPointsCard() {
    final user = _user!;
    return AnimatedBuilder(
      animation: _headerController,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, (1 - _headerController.value) * 30),
        child: Opacity(
          opacity: _headerController.value,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SibersihColors.primaryDeep,
                  SibersihColors.primary,
                  SibersihColors.primaryGlow,
                ],
              ),
              borderRadius: BorderRadius.circular(SibersihRadius.xl),
              boxShadow: SibersihColors.primaryGlowShadow,
            ),
            child: Stack(
              children: [
                // Decorative SVG-like bg pattern
                Positioned(
                  right: -10,
                  top: -10,
                  child: CustomPaint(
                    painter: _CardDecorPainter(),
                    size: const Size(100, 100),
                  ),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Poin Saya',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            AnimatedBuilder(
                              animation: _pointsCount,
                              builder: (_, __) => Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_pointsCount.value.toInt()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 44,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.5,
                                      height: 1.1,
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(bottom: 7, left: 5),
                                    child: Text(
                                      'poin',
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(SibersihRadius.sm),
                          ),
                          child: const Text('⭐',
                              style: TextStyle(fontSize: 26)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Divider
                    Divider(
                        color: Colors.white.withValues(alpha: 0.15), height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _pointChipCard(
                            '+${user.poinMasuk}',
                            'Masuk',
                            SibersihColors.accentMint,
                            Icons.arrow_downward_rounded,
                            () => _handleMenuTap('Poin Masuk')),
                        const SizedBox(width: 8),
                        _pointChipCard(
                            '-${user.poinKeluar}',
                            'Keluar',
                            SibersihColors.warning,
                            Icons.arrow_upward_rounded,
                            () => _handleMenuTap('Poin Keluar')),
                        const SizedBox(width: 8),
                        _pointChipCard(
                            'Tukar',
                            'Reward',
                            SibersihColors.accentCyan,
                            Icons.card_giftcard_rounded,
                            () => _handleMenuTap('Tukar Poin')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pointChipCard(String value, String label, Color color, IconData icon,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(SibersihRadius.sm),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(height: 5),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55), fontSize: 9.5,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Menu grid ───────────────────────────────────────────

  Widget _buildMenuGrid() {
    final menus = [
      _MenuItem('Detail Poin', Icons.bar_chart_rounded,
          SibersihColors.primary, SibersihColors.accentCyan),
      _MenuItem('Poin Masuk', Icons.trending_up_rounded,
          const Color(0xFF00C896), const Color(0xFF00E5B0)),
      _MenuItem('Poin Keluar', Icons.trending_down_rounded,
          SibersihColors.warning, const Color(0xFFFFCC55)),
      _MenuItem('Tukar Poin', Icons.card_giftcard_rounded,
          const Color(0xFF9B59B6), const Color(0xFFBD7BFF)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Menu Poin'),
        const SizedBox(height: 12),
        Row(
          children: menus
              .map((m) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: m == menus.last ? 0 : 10),
                      child: _buildMenuCard(m),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMenuCard(_MenuItem item) {
    return _HoverCard(
      onTap: () {
        HapticFeedback.selectionClick();
        _handleMenuTap(item.label);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withValues(alpha: 0.18),
                    item.color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(SibersihRadius.sm),
                border: Border.all(
                  color: item.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(item.icon, color: item.accentColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {String? action, VoidCallback? onAction}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [SibersihColors.primaryGlow, SibersihColors.primary],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action,
              style: const TextStyle(
                color: SibersihColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Rank card ───────────────────────────────────────────

  Widget _buildRankCard() {
    final user = _user!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankColor = _levelColor(user.level);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showLeaderboardSheet();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? SibersihColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(SibersihRadius.xl),
          boxShadow: SibersihColors.cardShadow,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : SibersihColors.primary.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            // Trophy with pulse
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _rankPulseController,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFCC00), Color(0xFFFF8C00)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 28))),
                ),
                builder: (_, child) => Transform.scale(
                  scale: 1.0 + _rankPulseController.value * 0.06,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(
                              alpha: 0.35 + _rankPulseController.value * 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peringkat Kamu',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#$_userRank dari $_totalUsers mahasiswa',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15.5),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SibersihRadius.pill),
                    child: LinearProgressIndicator(
                      value: _totalUsers > 0
                          ? (_totalUsers - _userRank + 1) / _totalUsers
                          : 1.0,
                      minHeight: 7,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation(
                          SibersihColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    rankColor.withValues(alpha: 0.18),
                    rankColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(SibersihRadius.sm),
                border: Border.all(color: rankColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Text(_levelEmoji(user.level),
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(
                    user.level,
                    style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaderboardSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SibersihRadius.xl)),
      ),
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDark ? SibersihColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(SibersihRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🏆 Leaderboard 10 Besar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mahasiswa paling aktif menjaga kebersihan UPI Cibiru',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: UserRepository.instance.getLeaderboard(limit: 10),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: SibersihColors.primary),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('😔', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal memuat peringkat',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  final list = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final name = item['nama'] as String? ?? 'User';
                      final points = (item['total_poin'] as num? ?? 0).toInt();
                      final fotoUrl = item['foto_url'] as String?;
                      final level = item['level'] as String? ?? 'Pemula';
                      final uid = item['id'] as String?;
                      
                      final isCurrentUser = uid == _user?.uid;
                      final rank = index + 1;

                      String rankBadge = '';
                      if (rank == 1) {
                        rankBadge = '🥇';
                      } else if (rank == 2) {
                        rankBadge = '🥈';
                      } else if (rank == 3) {
                        rankBadge = '🥉';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? SibersihColors.primary.withValues(alpha: 0.08)
                              : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(SibersihRadius.md),
                          border: Border.all(
                            color: isCurrentUser
                                ? SibersihColors.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                alignment: Alignment.center,
                                child: rankBadge.isNotEmpty
                                    ? Text(rankBadge, style: const TextStyle(fontSize: 20))
                                    : Text(
                                        '#$rank',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: SibersihColors.primary.withValues(alpha: 0.1),
                                backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                                    ? NetworkImage(fotoUrl)
                                    : null,
                                child: fotoUrl == null || fotoUrl.isEmpty
                                    ? const Text('🙋', style: TextStyle(fontSize: 16))
                                    : null,
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: isCurrentUser ? FontWeight.w900 : FontWeight.w700,
                                    fontSize: 13.5,
                                    color: isCurrentUser ? SibersihColors.primary : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: SibersihColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Kamu',
                                    style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            level,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? SibersihColors.primary.withValues(alpha: 0.15)
                                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(SibersihRadius.sm),
                            ),
                            child: Text(
                              '⭐ $points pts',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isCurrentUser ? SibersihColors.primary : (isDark ? Colors.white70 : Colors.black87),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Platinum':
        return Colors.cyan;
      case 'Emas':
        return Colors.amber;
      case 'Aktif':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _levelEmoji(String level) {
    switch (level) {
      case 'Platinum':
        return '💎';
      case 'Emas':
        return '🥇';
      case 'Aktif':
        return '🌱';
      default:
        return '🌱';
    }
  }

  // ─── Quotes ──────────────────────────────────────────────

  Widget _buildQuotesCard() {
    if (_quotes.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Motivasi Hari Ini 💬'),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0.08, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(_currentQuote),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? SibersihColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(SibersihRadius.xl),
              boxShadow: SibersihColors.cardShadow,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : SibersihColors.primary.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                // Quote icon with gradient bg
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [SibersihColors.primaryGlow,
                          SibersihColors.primary],
                    ),
                    borderRadius:
                        BorderRadius.circular(SibersihRadius.sm),
                  ),
                  child: const Center(
                      child: Text('💬', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(height: 16),
                Text(
                  '"${_quotes[_currentQuote]['text'] ?? ''}"',
                  style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.7),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: SibersihColors.primary.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(SibersihRadius.pill),
                  ),
                  child: Text(
                    '— ${_quotes[_currentQuote]['author'] ?? ''}',
                    style: const TextStyle(
                        color: SibersihColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _quotes.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentQuote ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: i == _currentQuote
                            ? const LinearGradient(
                                colors: [SibersihColors.primaryGlow,
                                    SibersihColors.primary])
                            : null,
                        color: i == _currentQuote
                            ? null
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── How it works ─────────────────────────────────────────

  Widget _buildHowItWorks() {
    final steps = [
      _Step('1', '📱', 'Buka App', 'Login ke Sibersih'),
      _Step('2', '🥤', 'Siapkan Botol', 'Kumpulkan botol plastik'),
      _Step('3', '📸', 'Foto & AI Scan', 'AI verifikasi otomatis'),
      _Step('4', '⭐', 'Dapat Poin', 'Poin masuk setelah verifikasi'),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Cara Kerja Sibersih'),
        const SizedBox(height: 4),
        Text('Mudah, cepat, dan menguntungkan! 🌟',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12.5,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 14),
        // Horizontal step cards
        Row(
          children: steps.asMap().entries.map((e) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: e.key < steps.length - 1 ? 8 : 0),
                child: _buildStepCard(e.value, isDark),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepCard(_Step step, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? SibersihColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(SibersihRadius.md),
        boxShadow: SibersihColors.softShadow,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : SibersihColors.primary.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          // Step number badge
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [SibersihColors.primaryGlow, SibersihColors.primary],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              step.number,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          Text(step.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            step.title,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            step.subtitle,
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 9.5),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ─── Recent activity ─────────────────────────────────────

  Widget _buildRecentActivity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Aktivitas Terbaru',
          action: 'Lihat Semua',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RiwayatPage()),
          ),
        ),
        const SizedBox(height: 12),
        if (_recentLaporans.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: isDark ? SibersihColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(SibersihRadius.md),
              boxShadow: SibersihColors.softShadow,
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_rounded,
                    size: 40,
                    color: Colors.grey.shade300),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada aktivitas laporan',
                  style:
                      TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ..._recentLaporans
              .map((laporan) => _ActivityTile(
                  laporan: laporan, isDark: isDark)),
      ],
    );
  }
}

// ─── Auxiliary widgets ────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final LaporanModel laporan;
  final bool isDark;

  const _ActivityTile({required this.laporan, required this.isDark});

  String _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'plastik':
        return '🥤';
      case 'kertas':
        return '📄';
      case 'logam':
        return '🪙';
      default:
        return '🗑️';
    }
  }

  String _getCategoryLabel(String cat) {
    switch (cat.toLowerCase()) {
      case 'plastik':
        return 'Sampah Plastik';
      case 'kertas':
        return 'Sampah Kertas';
      case 'logam':
        return 'Sampah Logam';
      default:
        return 'Sampah Lainnya';
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${dateTime.day} ${_monthName(dateTime.month)} ${dateTime.year}';
    }
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = laporan.status == StatusLaporan.diverifikasi;
    final isPending = laporan.status == StatusLaporan.pending;
    
    final statusColor = isVerified
        ? SibersihColors.success
        : (isPending ? SibersihColors.warning : SibersihColors.error);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? SibersihColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(SibersihRadius.md),
        boxShadow: SibersihColors.softShadow,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SibersihColors.primary.withValues(alpha: 0.12),
                  SibersihColors.primary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(SibersihRadius.sm),
            ),
            child: Center(
                child: Text(_getCategoryIcon(laporan.kategori),
                    style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCategoryLabel(laporan.kategori),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  _getRelativeTime(laporan.tanggal),
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(SibersihRadius.xs),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  isVerified
                      ? '+${laporan.poinDiterima} poin'
                      : (isPending ? 'Pending' : 'Ditolak'),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                laporan.statusLabel,
                style: TextStyle(
                  color: statusColor.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverCard({required this.child, required this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        transform: Matrix4.identity()
          // ignore: deprecated_member_use
          ..scale(_pressed ? 0.94 : 1.0)
          // ignore: deprecated_member_use
          ..translate(_pressed ? 1.0 : 0.0, _pressed ? 1.0 : 0.0),
        decoration: BoxDecoration(
          color: isDark ? SibersihColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(SibersihRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressed ? 0.03 : 0.07),
              blurRadius: _pressed ? 4 : 14,
              offset: Offset(0, _pressed ? 2 : 5),
            ),
            if (!_pressed)
              BoxShadow(
                color: SibersihColors.primary.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : SibersihColors.primary.withValues(alpha: 0.07),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final Color accentColor;

  _MenuItem(this.label, this.icon, this.color, this.accentColor);
}

class _Step {
  final String number, emoji, title, subtitle;

  _Step(this.number, this.emoji, this.title, this.subtitle);
}

// ── Custom painters for dashboard ─────────────────────────────────────────

class _HeaderBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF050280),
            Color(0xFF0A05A0),
            Color(0xFF1007BA),
            Color(0xFF2519D4),
          ],
          stops: [0.0, 0.25, 0.6, 1.0],
        ).createShader(rect),
    );
    // Accent spot
    final cx = size.width * 0.82;
    final cy = size.height * 0.25;
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.35,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF4C3FE8).withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
            center: Offset(cx, cy), radius: size.width * 0.35)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _CardDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width, 0), size.width * 0.8, paint);
    canvas.drawCircle(
        Offset(size.width, 0), size.width * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}