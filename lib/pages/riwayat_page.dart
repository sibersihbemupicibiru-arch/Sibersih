import 'package:flutter/material.dart';

// ============================================================
//  RIWAYAT PAGE  –  Botol Plastik & Botol Kaca
//  Poin = 0 sampai foto bukti diverifikasi admin
// ============================================================

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Data dummy (akan diganti dengan getRiwayatLaporan() dari SupabaseService) ──
  final List<_RiwayatItem> _allItems = [
    // Status 'Menunggu' → poin 0  (belum diverifikasi)
    const _RiwayatItem(
      emoji: '🍶',
      jenis: 'Botol Plastik',
      ukuran: 'Kecil',
      jumlah: 5,
      poin: 0,
      tanggal: '20 Apr 2025',
      waktu: '08:10',
      status: 'Menunggu',
      lokasi: 'Depan Gedung A',
      fotoBukti: null,
    ),
    // Status 'Terverifikasi' → poin sudah diberikan
    const _RiwayatItem(
      emoji: '🍶',
      jenis: 'Botol Plastik',
      ukuran: 'Sedang',
      jumlah: 3,
      poin: 90,
      tanggal: '18 Apr 2025',
      waktu: '13:45',
      status: 'Terverifikasi',
      lokasi: 'Kantin Kampus',
      fotoBukti: 'bukti_18apr.jpg',
    ),
    const _RiwayatItem(
      emoji: '🍶',
      jenis: 'Botol Plastik',
      ukuran: 'Besar',
      jumlah: 2,
      poin: 100,
      tanggal: '15 Apr 2025',
      waktu: '10:00',
      status: 'Terverifikasi',
      lokasi: 'Perpustakaan',
      fotoBukti: 'bukti_15apr.jpg',
    ),
    const _RiwayatItem(
      emoji: '🫙',
      jenis: 'Botol Kaca',
      ukuran: 'Kecil',
      jumlah: 4,
      poin: 0,
      tanggal: '10 Apr 2025',
      waktu: '09:00',
      status: 'Menunggu',
      lokasi: 'Lab Kimia',
      fotoBukti: null,
    ),
    const _RiwayatItem(
      emoji: '🫙',
      jenis: 'Botol Kaca',
      ukuran: 'Besar',
      jumlah: 1,
      poin: 80,
      tanggal: '5 Apr 2025',
      waktu: '15:30',
      status: 'Terverifikasi',
      lokasi: 'Taman Kampus',
      fotoBukti: 'bukti_05apr.jpg',
    ),
    const _RiwayatItem(
      emoji: '🍶',
      jenis: 'Botol Plastik',
      ukuran: 'Kecil',
      jumlah: 10,
      poin: 0,
      tanggal: '1 Apr 2025',
      waktu: '11:20',
      status: 'Ditolak',
      lokasi: 'Ruang IT',
      fotoBukti: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalBotol = _allItems
        .where((i) => i.status == 'Terverifikasi')
        .fold(0, (sum, i) => sum + i.jumlah);

    final totalPoin = _allItems
        .where((i) => i.status == 'Terverifikasi')
        .fold(0, (sum, i) => sum + i.poin);

    return Scaffold(
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            title: const Text(
              'Riwayat Laporan',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF1007BA),
            foregroundColor: Colors.white,
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A05A0), Color(0xFF2519D4)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        children: [
                          _statCard('📦', '${_allItems.length}',
                              'Total Laporan', Colors.blue.shade200),
                          const SizedBox(width: 12),
                          _statCard('🍶', '$totalBotol',
                              'Total Botol', Colors.cyan.shade200),
                          const SizedBox(width: 12),
                          _statCard('⭐', '$totalPoin',
                              'Total Poin', Colors.amber.shade200),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Terverifikasi'),
                Tab(text: 'Proses'),
              ],
              onTap: (_) => setState(() {}),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildList(_allItems),
            _buildList(_allItems
                .where((i) => i.status == 'Terverifikasi')
                .toList()),
            _buildList(_allItems
                .where((i) =>
                    i.status == 'Menunggu' || i.status == 'Ditolak')
                .toList()),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15),
            ),
            Text(
              label,
              style:
                  const TextStyle(color: Colors.white60, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<_RiwayatItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📭', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'Belum ada riwayat',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'Upload bukti foto untuk mendapatkan poin!',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, i) =>
          _RiwayatCard(item: items[i], index: i),
    );
  }
}

// ============================================================
//  CARD
// ============================================================

class _RiwayatCard extends StatefulWidget {
  final _RiwayatItem item;
  final int index;

  const _RiwayatCard({required this.item, required this.index});

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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnim = CurvedAnimation(
        parent: _expandController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.item.status) {
      case 'Terverifikasi':
        return Colors.green;
      case 'Menunggu':
        return Colors.orange;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get _statusEmoji {
    switch (widget.item.status) {
      case 'Terverifikasi':
        return '✅';
      case 'Menunggu':
        return '⏳';
      case 'Ditolak':
        return '❌';
      default:
        return '❓';
    }
  }

  /// Label poin yang ditampilkan:
  /// - Terverifikasi → tampilkan jumlah poin
  /// - Menunggu, belum ada foto → "Upload Bukti Foto"
  /// - Menunggu, sudah ada foto → "Menunggu Verifikasi"
  /// - Ditolak → "Ditolak"
  String get _poinLabel {
    if (widget.item.status == 'Terverifikasi') {
      return '⭐ +${widget.item.poin} Poin';
    }
    if (widget.item.status == 'Ditolak') return '❌ Ditolak';
    if (widget.item.fotoBukti == null) return '📸 Upload Bukti Foto';
    return '⏳ Menunggu Verifikasi';
  }

  Color get _poinBgColor {
    if (widget.item.status == 'Terverifikasi') return const Color(0xFF1007BA);
    if (widget.item.status == 'Ditolak') return Colors.red.shade700;
    if (widget.item.fotoBukti == null) return Colors.orange.shade700;
    return Colors.blueGrey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() => _expanded = !_expanded);
        if (_expanded) {
          _expandController.forward();
        } else {
          _expandController.reverse();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _expanded
                ? const Color(0xFF1007BA).withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ikon botol
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF1007BA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(widget.item.emoji,
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
                            // Nama jenis + ukuran
                            Expanded(
                              child: Text(
                                '${widget.item.jenis} – ${widget.item.ukuran}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            // Badge status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_statusEmoji ${widget.item.status}',
                                style: TextStyle(
                                  color: _statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Jumlah botol
                            Icon(Icons.inventory_2_outlined,
                                size: 13,
                                color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.item.jumlah} botol',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time_rounded,
                                size: 13,
                                color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.item.tanggal} · ${widget.item.waktu}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Baris bawah: label poin + chevron
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Tombol/label poin
                  // Jika belum upload foto, tap bisa diarahkan ke halaman upload
                  GestureDetector(
                    onTap: widget.item.fotoBukti == null &&
                            widget.item.status == 'Menunggu'
                        ? () {
                            // TODO: navigasi ke halaman upload bukti foto
                            // Navigator.pushNamed(context, '/upload-bukti',
                            //     arguments: widget.item.id);
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _poinBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _poinLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Detail yang bisa di-expand
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF1007BA).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _detailRow(Icons.location_on_outlined,
                          'Lokasi', widget.item.lokasi),
                      const Divider(height: 16),
                      _detailRow(Icons.recycling_rounded, 'Jenis',
                          widget.item.jenis),
                      const Divider(height: 16),
                      _detailRow(Icons.straighten_rounded, 'Ukuran',
                          widget.item.ukuran),
                      const Divider(height: 16),
                      _detailRow(Icons.inventory_2_outlined,
                          'Jumlah', '${widget.item.jumlah} botol'),
                      const Divider(height: 16),
                      _detailRow(
                        Icons.photo_camera_outlined,
                        'Bukti Foto',
                        widget.item.fotoBukti != null
                            ? '✅ Sudah diunggah'
                            : '❌ Belum diunggah',
                      ),
                      const Divider(height: 16),
                      _detailRow(Icons.verified_rounded, 'Status',
                          widget.item.status),
                      // Baris poin hanya muncul jika terverifikasi
                      if (widget.item.status == 'Terverifikasi') ...[
                        const Divider(height: 16),
                        _detailRow(Icons.star_rounded, 'Poin',
                            '+${widget.item.poin} Poin'),
                      ],
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1007BA)),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style:
              const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ============================================================
//  MODEL
// ============================================================

class _RiwayatItem {
  /// Emoji representasi jenis botol (🍶 plastik, 🫙 kaca)
  final String emoji;

  /// 'Botol Plastik' atau 'Botol Kaca'
  final String jenis;

  /// 'Kecil' | 'Sedang' | 'Besar'
  final String ukuran;

  /// Jumlah botol yang dilaporkan
  final int jumlah;

  /// Poin yang didapat — selalu 0 sampai admin memverifikasi
  final int poin;

  final String tanggal;
  final String waktu;

  /// 'Terverifikasi' | 'Menunggu' | 'Ditolak'
  final String status;

  final String lokasi;

  /// Path / nama file bukti foto; null jika belum diupload
  final String? fotoBukti;

  const _RiwayatItem({
    required this.emoji,
    required this.jenis,
    required this.ukuran,
    required this.jumlah,
    required this.poin,
    required this.tanggal,
    required this.waktu,
    required this.status,
    required this.lokasi,
    required this.fotoBukti,
  });
}