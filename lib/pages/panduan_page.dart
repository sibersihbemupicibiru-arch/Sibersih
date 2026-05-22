import 'package:flutter/material.dart';

class PanduanPage extends StatefulWidget {
  const PanduanPage({super.key});

  @override
  State<PanduanPage> createState() => _PanduanPageState();
}

class _PanduanPageState extends State<PanduanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late PageController _pageController;
  final int _currentPage = 0;

  final List<_GuideStep> _steps = [
    _GuideStep(
      step: '01',
      emoji: '🔐',
      title: 'Daftar & Masuk Akun',
      description:
          'Buat akun menggunakan email kampus dan NIM-mu. Pastikan data yang dimasukkan sesuai agar poinmu aman dan terlindungi.',
      tips: [
        'Gunakan email resmi kampus',
        'NIM harus sesuai KTM',
        'Simpan password dengan aman',
      ],
      color: const Color(0xFF1007BA),
      bgColor: const Color(0xFFE8E6FF),
    ),
    _GuideStep(
      step: '02',
      emoji: '🗑️',
      title: 'Pisahkan Sampah',
      description:
          'Pilah sampah sesuai jenisnya: plastik, kertas, logam, kaca, organik, atau elektronik. Pemilahan yang tepat menghasilkan poin lebih besar!',
      tips: [
        'Pastikan sampah sudah bersih',
        'Pisahkan sesuai kategori',
        'Kumpulkan sampah yang cukup',
      ],
      color: const Color(0xFF00A86B),
      bgColor: const Color(0xFFE8F8F3),
    ),
    _GuideStep(
      step: '03',
      emoji: '📸',
      title: 'Ambil Foto Sampah',
      description:
          'Foto sampah yang akan kamu buang dari jarak yang cukup dekat agar terlihat jelas. Pastikan pencahayaan cukup untuk foto yang berkualitas.',
      tips: [
        'Foto dari sudut yang jelas',
        'Pastikan cahaya cukup',
        'Tampilkan semua sampah',
      ],
      color: const Color(0xFFFF6B35),
      bgColor: const Color(0xFFFFF0EB),
    ),
    _GuideStep(
      step: '04',
      emoji: '⚖️',
      title: 'Timbang & Isi Detail',
      description:
          'Timbang berat sampahmu dan catat dengan benar. Isi juga lokasi pembuangan sampah agar laporan lebih valid dan mudah diverifikasi.',
      tips: [
        'Berat dalam satuan gram/kg',
        'Isi lokasi dengan jelas',
        'Tambahkan catatan jika perlu',
      ],
      color: const Color(0xFF9C27B0),
      bgColor: const Color(0xFFF3E5F5),
    ),
    _GuideStep(
      step: '05',
      emoji: '📤',
      title: 'Kirim Laporan',
      description:
          'Setelah semua data terisi dengan lengkap, tap tombol "Kirim Laporan". Tim Sibersih akan memverifikasi laporanmu dalam 1x24 jam.',
      tips: [
        'Cek kembali sebelum kirim',
        'Pastikan foto sudah upload',
        'Tunggu konfirmasi verifikasi',
      ],
      color: const Color(0xFF2196F3),
      bgColor: const Color(0xFFE3F2FD),
    ),
    _GuideStep(
      step: '06',
      emoji: '⭐',
      title: 'Kumpulkan Poin!',
      description:
          'Setelah diverifikasi, poinmu langsung masuk ke akun! Kumpulkan poin sebanyak-banyaknya dan tukarkan dengan hadiah menarik.',
      tips: [
        'Poin otomatis terkredit',
        'Cek riwayat di menu Riwayat',
        'Tukar poin di menu Dashboard',
      ],
      color: const Color(0xFFFF9800),
      bgColor: const Color(0xFFFFF8E1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            title: const Text(
              'Panduan Sibersih',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF1007BA),
            foregroundColor: Colors.white,
            floating: true,
            snap: true,
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
              delegate: SliverChildListDelegate([
                // Header
                _buildHeader(),
                const SizedBox(height: 24),
                // Guide cards
                ..._steps.asMap().entries.map(
                      (entry) => _GuideCard(
                        step: entry.value,
                        index: entry.key,
                      ),
                    ),
                const SizedBox(height: 16),
                // FAQ Section
                _buildFAQ(),
                const SizedBox(height: 24),
                // CTA
                _buildCTA(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1007BA), Color(0xFF4C3FE8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1007BA).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📚 Panduan Lengkap',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cara Menggunakan\nSibersih',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '6 langkah mudah untuk mulai\nmengumpulkan poin dari sampahmu!',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Text('🌿', style: TextStyle(fontSize: 64)),
        ],
      ),
    );
  }

  Widget _buildFAQ() {
    final faqs = [
      {
        'q': 'Berapa lama verifikasi laporan?',
        'a': 'Tim kami akan memverifikasi dalam 1x24 jam. Kamu akan mendapat notifikasi setelah selesai.',
      },
      {
        'q': 'Sampah apa saja yang bisa dilaporkan?',
        'a': 'Plastik, kertas, logam, kaca, organik, elektronik, dan kain. Semua jenis sampah yang dipilah dengan benar bisa dilaporkan.',
      },
      {
        'q': 'Bagaimana cara menukar poin?',
        'a': 'Kunjungi menu Dashboard > Tukar Poin. Pilih hadiah yang tersedia sesuai jumlah poinmu.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pertanyaan Umum',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...faqs.map((faq) => _FAQTile(q: faq['q']!, a: faq['a']!)),
      ],
    );
  }

  Widget _buildCTA() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00A86B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00A86B).withOpacity(0.3),
        ),
      ),
      child: const Column(
        children: [
          Text('🎯', style: TextStyle(fontSize: 36)),
          SizedBox(height: 10),
          Text(
            'Siap Mulai?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Sekarang giliran kamu untuk berkontribusi!\nBuat laporan pertamamu sekarang.',
            style:
                TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatefulWidget {
  final _GuideStep step;
  final int index;

  const _GuideCard({required this.step, required this.index});

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<_GuideCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandController;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _expanded
                ? widget.step.color.withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Step number + emoji
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark
                              ? widget.step.color.withOpacity(0.2)
                              : widget.step.bgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(widget.step.emoji,
                              style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: widget.step.color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.step.step,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.step.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.step.description,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12, height: 1.4),
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.step.color,
                    ),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: CurvedAnimation(
                  parent: _expandController, curve: Curves.easeInOut),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? widget.step.color.withOpacity(0.1)
                        : widget.step.bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded,
                              color: widget.step.color, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Tips Penting',
                            style: TextStyle(
                              color: widget.step.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...widget.step.tips.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: widget.step.color, size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

class _FAQTile extends StatefulWidget {
  final String q, a;

  const _FAQTile({required this.q, required this.a});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  final bool _open = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          widget.q,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        iconColor: const Color(0xFF1007BA),
        collapsedIconColor: Colors.grey,
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.a,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep {
  final String step, emoji, title, description;
  final List<String> tips;
  final Color color, bgColor;

  _GuideStep({
    required this.step,
    required this.emoji,
    required this.title,
    required this.description,
    required this.tips,
    required this.color,
    required this.bgColor,
  });
}
