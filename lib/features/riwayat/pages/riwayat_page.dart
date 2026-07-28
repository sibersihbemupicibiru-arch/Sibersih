import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/laporan_model.dart';
import '../../../repositories/laporan_repository.dart';
import '../../../core/app_tokens.dart';

// ─── Enums untuk sorting ──────────────────────────────────────
enum _SortBy { waktuTerbaru, waktuTerlama, poinTerbesar, poinTerkecil }

// ─── Enum filter jenis ────────────────────────────────────────
enum _JenisFilter { semua, plastik, kaca }

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<LaporanModel> _allItems = [];
  bool _loading = true;

  _SortBy _sortBy = _SortBy.waktuTerbaru;
  _JenisFilter _jenisFilter = _JenisFilter.semua;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await LaporanRepository.instance.getRiwayatLaporan();
    if (mounted) {
      setState(() {
        _allItems = data;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Filter berdasarkan tab ───────────────────────────────
  List<LaporanModel> _filterByTab(List<LaporanModel> items) {
    switch (_tabController.index) {
      case 1:
        return items.where((i) => i.status == StatusLaporan.diverifikasi).toList();
      case 2:
        return items
            .where((i) =>
                i.status == StatusLaporan.pending ||
                i.status == StatusLaporan.ditolak)
            .toList();
      default:
        return items;
    }
  }

  // ─── Filter berdasarkan jenis ─────────────────────────────
  List<LaporanModel> _filterByJenis(List<LaporanModel> items) {
    if (_jenisFilter == _JenisFilter.semua) return items;
    return items.where((i) => i.kategori.toLowerCase() == _jenisFilter.name).toList();
  }

  // ─── Sorting ──────────────────────────────────────────────
  List<LaporanModel> _sort(List<LaporanModel> items) {
    final list = List<LaporanModel>.from(items);
    switch (_sortBy) {
      case _SortBy.waktuTerbaru:
        list.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      case _SortBy.waktuTerlama:
        list.sort((a, b) => a.tanggal.compareTo(b.tanggal));
      case _SortBy.poinTerbesar:
        list.sort((a, b) => b.poinDiterima.compareTo(a.poinDiterima));
      case _SortBy.poinTerkecil:
        list.sort((a, b) => a.poinDiterima.compareTo(b.poinDiterima));
    }
    return list;
  }

  List<LaporanModel> get _displayItems {
    var items = _filterByTab(_allItems);
    items = _filterByJenis(items);
    items = _sort(items);
    return items;
  }

  // Stats
  int get _totalPoin => _allItems
      .where((i) => i.status == StatusLaporan.diverifikasi)
      .map((i) => i.poinDiterima)
      .fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            title: const Text(
              'Riwayat Laporan',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.2),
            ),
            centerTitle: true,
            backgroundColor: SibersihColors.primaryDeep,
            foregroundColor: Colors.white,
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Animated-like dynamic gradient
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF050280),
                            Color(0xFF0A05A0),
                            Color(0xFF1007BA),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Background circular elements
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SibersihColors.primaryGlow.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            _statCard(
                              '📦',
                              '${_allItems.length}',
                              'Total Laporan',
                              SibersihColors.accentCyan,
                              isDark,
                            ),
                            const SizedBox(width: 10),
                            _statCard(
                              '⭐',
                              '$_totalPoin',
                              'Total Poin',
                              SibersihColors.warning,
                              isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 52), // Space for tabbar
                    ],
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
                  indicatorColor: SibersihColors.accentCyan,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Semua'),
                    Tab(text: 'Terverifikasi'),
                    Tab(text: 'Proses'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: SibersihColors.primary))
            : Column(
                children: [
                  // Filter & Sort bar
                  _buildFilterBar(),
                  // List
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: List.generate(3, (_) => _buildList(_displayItems)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of Category Pills
          _buildCategoryPills(),
          const SizedBox(height: 10),
          // Sort Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_displayItems.length} Laporan ditemukan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                  ),
                ),
                PopupMenuButton<_SortBy>(
                  onSelected: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _sortBy = value);
                  },
                  offset: const Offset(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.md)),
                  itemBuilder: (context) => _SortBy.values.map((s) {
                    final isSelected = _sortBy == s;
                    return PopupMenuItem<_SortBy>(
                      value: s,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _sortByLabel(s),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? SibersihColors.primary
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontSize: 13,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: SibersihColors.primary,
                              size: 16,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SibersihColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(SibersihRadius.sm),
                      border: Border.all(
                        color: SibersihColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.swap_vert_rounded,
                          size: 14,
                          color: SibersihColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _sortLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: SibersihColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        children: _JenisFilter.values.map((j) {
          final isSelected = _jenisFilter == j;
          String label = 'Semua';
          String emoji = '🗑️';
          if (j == _JenisFilter.plastik) {
            label = 'Plastik';
            emoji = '🥤';
          } else if (j == _JenisFilter.kaca) {
            label = 'Kaca';
            emoji = '🫙';
          }

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _jenisFilter = j);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [SibersihColors.primary, SibersihColors.primaryGlow],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? SibersihColors.cardDark : Colors.white),
                borderRadius: BorderRadius.circular(SibersihRadius.pill),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : SibersihColors.primary.withValues(alpha: 0.08)),
                  width: 1,
                ),
                boxShadow: isSelected ? SibersihColors.softShadow : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String get _sortLabel {
    switch (_sortBy) {
      case _SortBy.waktuTerbaru:
        return 'Terbaru';
      case _SortBy.waktuTerlama:
        return 'Terlama';
      case _SortBy.poinTerbesar:
        return 'Poin Terbesar';
      case _SortBy.poinTerkecil:
        return 'Poin Terkecil';
    }
  }

  String _sortByLabel(_SortBy s) {
    switch (s) {
      case _SortBy.waktuTerbaru:
        return 'Terbaru';
      case _SortBy.waktuTerlama:
        return 'Terlama';
      case _SortBy.poinTerbesar:
        return 'Poin Terbesar';
      case _SortBy.poinTerkecil:
        return 'Poin Terkecil';
    }
  }

  Widget _statCard(String emoji, String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(SibersihRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<LaporanModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Belum ada riwayat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Mulai buang sampah & dapatkan poin!',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: SibersihColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) => _RiwayatCard(item: items[i]),
      ),
    );
  }
}

// ─── RiwayatCard ──────────────────────────────────────────────

class _RiwayatCard extends StatefulWidget {
  final LaporanModel item;

  const _RiwayatCard({required this.item});

  @override
  State<_RiwayatCard> createState() => _RiwayatCardState();
}

class _RiwayatCardState extends State<_RiwayatCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnim = CurvedAnimation(
        parent: _expandController, curve: Curves.fastOutSlowIn);
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  // ─── Status styling ───────────────────────────────────────

  Color get _statusColor {
    switch (widget.item.status) {
      case StatusLaporan.diverifikasi:
        return SibersihColors.success;
      case StatusLaporan.pending:
        return SibersihColors.warning;
      case StatusLaporan.ditolak:
        return SibersihColors.error;
    }
  }

  String get _statusEmoji {
    switch (widget.item.status) {
      case StatusLaporan.diverifikasi:
        return '✅';
      case StatusLaporan.pending:
        return '⏳';
      case StatusLaporan.ditolak:
        return '❌';
    }
  }

  String get _statusLabel {
    switch (widget.item.status) {
      case StatusLaporan.diverifikasi:
        return 'Terverifikasi';
      case StatusLaporan.pending:
        return 'Menunggu';
      case StatusLaporan.ditolak:
        return 'Ditolak';
    }
  }

  // ─── Poin badge gradient by status ───────────────────────

  List<Color> get _poinGradient {
    switch (widget.item.status) {
      case StatusLaporan.pending:
        return [SibersihColors.warning, const Color(0xFFE28A00)];
      case StatusLaporan.ditolak:
        return [SibersihColors.error, const Color(0xFFD63050)];
      case StatusLaporan.diverifikasi:
        return [SibersihColors.primary, SibersihColors.primaryGlow];
    }
  }

  // ─── Title: kategori + ukuran ─────────────────────────────

  String get _title {
    final kat = widget.item.kategori;
    final uk = widget.item.ukuran;
    final katCap = kat.isNotEmpty ? kat[0].toUpperCase() + kat.substring(1) : kat;
    final ukCap = uk.isNotEmpty ? uk[0].toUpperCase() + uk.substring(1) : uk;
    return 'Botol $katCap $ukCap';
  }

  String get _emoji {
    switch (widget.item.kategori.toLowerCase()) {
      case 'plastik':  return '🥤';
      case 'kaca':     return '🫙';
      default:         return '🗑️';
    }
  }

  String _formatTanggal(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _formatWaktu(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _expanded = !_expanded);
        _expanded
            ? _expandController.forward()
            : _expandController.reverse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? SibersihColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(SibersihRadius.lg),
          border: Border.all(
            color: _expanded
                ? _statusColor.withValues(alpha: 0.3)
                : (isDark ? Colors.white.withValues(alpha: 0.05) : SibersihColors.primary.withValues(alpha: 0.05)),
            width: 1.2,
          ),
          boxShadow: SibersihColors.softShadow,
        ),
        child: Column(
          children: [
            // ── Header row ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Emoji icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(SibersihRadius.md),
                    ),
                    child: Center(
                      child: Text(_emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(SibersihRadius.xs),
                              ),
                              child: Text(
                                '$_statusEmoji $_statusLabel',
                                style: TextStyle(
                                  color: _statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatTanggal(item.tanggal)} · ${_formatWaktu(item.tanggal)}',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Poin badge + expand arrow ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _poinGradient),
                      borderRadius: BorderRadius.circular(SibersihRadius.sm),
                    ),
                    child: Text(
                      item.status == StatusLaporan.diverifikasi
                          ? '⭐ +${item.poinDiterima} Poin'
                          : item.status == StatusLaporan.pending
                              ? '⏳ Poin Pending'
                              : '❌ Laporan Ditolak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // ── Expanded detail ───────────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(SibersihRadius.md),
                    border: Border.all(
                        color: _statusColor.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    children: [
                      _detailRow(Icons.straighten_rounded, 'Ukuran',
                          _capitalize(item.ukuran)),
                      const Divider(height: 16),
                      _detailRow(Icons.category_outlined, 'Jenis',
                          _capitalize(item.kategori)),
                      const Divider(height: 16),
                      _detailRow(Icons.scale_rounded, 'Berat',
                          item.beratFormatted),
                      if (item.catatan.isNotEmpty) ...[
                        const Divider(height: 16),
                        _detailRow(Icons.notes_rounded, 'Catatan',
                            item.catatan),
                      ],
                      const Divider(height: 16),
                      _detailRow(Icons.verified_rounded, 'Status',
                          _statusLabel),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _statusColor),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
