import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'detail_poin_page.dart';
import 'tukar_poin_page.dart';
import 'poin_history_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _quoteController;
  late AnimationController _shimmerController;
  late AnimationController _rankPulseController;

  late Animation<double> _pointsCount;

  int _currentQuote = 0;
  UserModel? _user;
  List<Map<String, String>> _quotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _cardsController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _quoteController =
        AnimationController(duration: const Duration(seconds: 5), vsync: this)
          ..repeat();
    _shimmerController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this)
          ..repeat();
    _rankPulseController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this)
          ..repeat(reverse: true);

    _pointsCount = Tween<double>(begin: 0, end: 2850).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      SupabaseService.instance.getCurrentUser(),
      SupabaseService.instance.getQuotes(),
    ]);

    if (!mounted) return;
    final user = results[0] as UserModel;
    final quotes = results[1] as List<Map<String, String>>;

    _pointsCount = Tween<double>(begin: 0, end: user.totalPoin.toDouble())
        .animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic));

    setState(() {
      _user = user;
      _quotes = quotes;
      _loading = false;
    });

    _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _cardsController.forward();

    // Auto-rotate quotes
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted || _quotes.isEmpty) return false;
      setState(() => _currentQuote = (_currentQuote + 1) % _quotes.length);
      return true;
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    _quoteController.dispose();
    _shimmerController.dispose();
    _rankPulseController.dispose();
    super.dispose();
  }

  void _handleMenuTap(String menu) {
    switch (menu) {
      case 'Detail Poin':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailPoinPage()));
        break;
      case 'Poin Masuk':
        _showPoinDialog('masuk');
        break;
      case 'Poin Keluar':
        _showPoinDialog('keluar');
        break;
      case 'Tukar Poin':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TukarPoinPage()));
        break;
    }
  }

  Future<void> _showPoinDialog(String type) async {
    final history = type == 'masuk'
        ? await SupabaseService.instance.getPoinMasukHistory()
        : await SupabaseService.instance.getPoinKeluarHistory();

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
      body: _loading
          ? _buildSkeleton()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildPointsCard(),
                      const SizedBox(height: 20),
                      _buildMenuGrid(),
                      const SizedBox(height: 24),
                      _buildRankCard(),
                      const SizedBox(height: 24),
                      _buildQuotesCard(),
                      const SizedBox(height: 24),
                      _buildHowItWorks(),
                      const SizedBox(height: 24),
                      _buildRecentActivity(),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Skeleton loading ─────────────────────────────────────

  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) => CustomScrollView(
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
      ),
    );
  }

  Widget _skeletonBlock(int i) {
    final heights = [120.0, 80.0, 140.0, 100.0, 60.0];
    final t = (_shimmerController.value + i * 0.2) % 1.0;
    final opacity = 0.3 + 0.3 * math.sin(t * math.pi);
    return Container(
      height: heights[i],
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(opacity),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────

  Widget _buildHeader() {
    final user = _user!;
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      backgroundColor: const Color(0xFF1007BA),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A05A0), Color(0xFF1007BA), Color(0xFF2519D4)],
            ),
          ),
          child: Stack(
            children: [
              // BG decoration circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                left: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              // Content
              AnimatedBuilder(
                animation: _headerController,
                builder: (_, __) => Opacity(
                  opacity: _headerController.value.clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
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
                                  const Text('Selamat Datang! 👋',
                                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.nama,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${user.nim} · ${user.jurusan}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Avatar
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(color: Colors.white38, width: 2),
                              ),
                              child: user.fotoUrl != null
                                  ? ClipOval(
                                      child: Image.network(user.fotoUrl!,
                                          fit: BoxFit.cover))
                                  : const Center(
                                      child: Text('🙋', style: TextStyle(fontSize: 26))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _statChip('🥤', '${user.jumlahLaporan}', 'Laporan'),
                            _statChip('🏆', user.level, 'Level'),
                            _statChip('📊', '#${user.rank}', 'Peringkat'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
            ],
          ),
        ],
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
                colors: [Color(0xFF1007BA), Color(0xFF4C3FE8)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1007BA).withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Poin Saya',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${DateTime.now().year}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _pointsCount,
                  builder: (_, __) => Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '⭐ ${_pointsCount.value.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6, left: 4),
                        child: Text('poin', style: TextStyle(color: Colors.white60, fontSize: 15)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _pointChipCard('+${user.poinMasuk}', 'Masuk', Colors.greenAccent, Icons.arrow_downward_rounded, () => _handleMenuTap('Poin Masuk')),
                    const SizedBox(width: 8),
                    _pointChipCard('-${user.poinKeluar}', 'Keluar', Colors.orangeAccent, Icons.arrow_upward_rounded, () => _handleMenuTap('Poin Keluar')),
                    const SizedBox(width: 8),
                    _pointChipCard('Tukar', 'Reward', Colors.lightBlueAccent, Icons.card_giftcard_rounded, () => _handleMenuTap('Tukar Poin')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pointChipCard(String value, String label, Color color, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Menu grid ───────────────────────────────────────────

  Widget _buildMenuGrid() {
    final menus = [
      _MenuItem('Detail Poin', Icons.bar_chart_rounded, const Color(0xFF1007BA)),
      _MenuItem('Poin Masuk', Icons.trending_up_rounded, Colors.green),
      _MenuItem('Poin Keluar', Icons.trending_down_rounded, Colors.orange),
      _MenuItem('Tukar Poin', Icons.card_giftcard_rounded, Colors.purple),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Menu Poin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: menus.map((m) => _buildMenuCard(m)).toList(),
        ),
      ],
    );
  }

  Widget _buildMenuCard(_MenuItem item) {
    return _HoverCard(
      onTap: () => _handleMenuTap(item.label),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 7),
          Text(item.label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ─── Rank card ───────────────────────────────────────────

  Widget _buildRankCard() {
    final user = _user!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _rankPulseController,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Trophy with pulse
            Transform.scale(
              scale: 1.0 + _rankPulseController.value * 0.05,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade400],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3 + _rankPulseController.value * 0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(child: Text('🏆', style: TextStyle(fontSize: 28))),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Peringkat Kamu', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    '#${user.rank} dari 248 mahasiswa',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1 - (user.rank / 248),
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF1007BA)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _levelColor(user.level).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _levelColor(user.level).withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Text(_levelEmoji(user.level), style: const TextStyle(fontSize: 18)),
                  Text(user.level,
                      style: TextStyle(
                          color: _levelColor(user.level),
                          fontWeight: FontWeight.w800,
                          fontSize: 11)),
                ],
              ),
            ),
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
      case 'Platinum': return '💎';
      case 'Emas': return '🥇';
      case 'Aktif': return '🌱';
      default: return '🌱';
    }
  }

  // ─── Quotes ──────────────────────────────────────────────

  Widget _buildQuotesCard() {
    if (_quotes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Motivasi Hari Ini 💬', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(_currentQuote),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1007BA).withOpacity(0.08),
                  const Color(0xFF4C3FE8).withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF1007BA).withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 14),
                Text(
                  _quotes[_currentQuote]['text'] ?? '',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.65),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _quotes[_currentQuote]['author'] ?? '',
                  style: const TextStyle(
                      color: Color(0xFF1007BA), fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _quotes.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentQuote ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _currentQuote
                            ? const Color(0xFF1007BA)
                            : Colors.grey.shade300,
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
        const Text('Cara Kerja Sibersih', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Mudah, cepat, dan menguntungkan! 🌟',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: steps.asMap().entries.map((e) {
              return Column(
                children: [
                  _buildStep(e.value),
                  if (e.key < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Column(
                        children: List.generate(
                          3,
                          (j) => Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                                width: 2,
                                height: 4,
                                color: const Color(0xFF1007BA).withOpacity(0.25)),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(_Step step) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1007BA).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(step.emoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                        color: Color(0xFF1007BA), shape: BoxShape.circle),
                    child: Center(
                      child: Text(step.number,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(step.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 2),
              Text(step.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Recent activity ─────────────────────────────────────

  Widget _buildRecentActivity() {
    final activities = [
      {'icon': '🥤', 'type': 'Botol Plastik', 'weight': '1.2 kg', 'points': '+120', 'time': '2 jam lalu', 'status': 'Terverifikasi'},
      {'icon': '🥤', 'type': 'Botol Plastik', 'weight': '0.8 kg', 'points': '+80', 'time': 'Kemarin', 'status': 'Terverifikasi'},
      {'icon': '🥤', 'type': 'Botol Plastik', 'weight': '2.5 kg', 'points': '0', 'time': '2 hari lalu', 'status': 'Menunggu'},
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Aktivitas Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: () {},
              child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF1007BA), fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...activities.map((act) => _ActivityTile(activity: act, isDark: isDark)),
      ],
    );
  }
}

// ─── Auxiliary widgets ────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final Map<String, String> activity;
  final bool isDark;

  const _ActivityTile({required this.activity, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isVerified = activity['status'] == 'Terverifikasi';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(activity['icon']!, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['type']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('${activity['weight']} · ${activity['time']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isVerified ? '+${activity['points']}' : 'Pending',
                  style: TextStyle(
                    color: isVerified ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(activity['status']!,
                  style: TextStyle(
                    color: isVerified ? Colors.green : Colors.orange,
                    fontSize: 10,
                  )),
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
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.93 : 1.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_pressed ? 0.03 : 0.08),
              blurRadius: _pressed ? 4 : 14,
              offset: const Offset(0, 4),
            ),
          ],
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

  _MenuItem(this.label, this.icon, this.color);
}

class _Step {
  final String number, emoji, title, subtitle;

  _Step(this.number, this.emoji, this.title, this.subtitle);
}
