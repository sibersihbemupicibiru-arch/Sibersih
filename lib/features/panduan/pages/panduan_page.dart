import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/panduan_model.dart';
import '../../../models/faq_model.dart';
import '../../../repositories/panduan_repository.dart';
import '../../../core/app_tokens.dart';

// Harmonious step color pool matching Sibersih tokens
const List<Color> _kStepColors = [
  SibersihColors.primary,
  SibersihColors.success,
  SibersihColors.warning,
  SibersihColors.accentPurple,
  SibersihColors.accentCyan,
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  SibersihColors.accentMint,
];

class PanduanPage extends StatefulWidget {
  const PanduanPage({super.key});

  @override
  State<PanduanPage> createState() => _PanduanPageState();
}

class _PanduanPageState extends State<PanduanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<PanduanModel> _panduan = [];
  List<FaqModel> _faqs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      PanduanRepository.instance.fetchPanduan(),
      PanduanRepository.instance.fetchFAQ(),
    ]);
    if (mounted) {
      setState(() {
        _panduan = results[0] as List<PanduanModel>;
        _faqs = results[1] as List<FaqModel>;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.2),
            ),
            centerTitle: true,
            backgroundColor: SibersihColors.primaryDeep,
            foregroundColor: Colors.white,
            floating: true,
            snap: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF050280), Color(0xFF0A05A0), Color(0xFF1007BA)],
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: SibersihColors.primary)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),
                  // Guide cards
                  if (_panduan.isEmpty)
                    _buildEmptyState(
                      icon: Icons.menu_book_rounded,
                      message: 'Panduan belum tersedia.',
                    )
                  else
                    ..._panduan.asMap().entries.map((entry) {
                      final color = _kStepColors[entry.key % _kStepColors.length];
                      return _GuideCard(
                        panduan: entry.value,
                        color: color,
                      );
                    }),
                  const SizedBox(height: 24),
                  // FAQ Section
                  _buildFAQ(),
                  const SizedBox(height: 24),
                  // CTA
                  _buildCTA(),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final count = _panduan.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SibersihColors.primary, SibersihColors.primaryGlow],
        ),
        borderRadius: BorderRadius.circular(SibersihRadius.lg),
        boxShadow: SibersihColors.primaryGlowShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(SibersihRadius.xs),
                  ),
                  child: const Text(
                    '📚 Panduan Lengkap',
                    style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cara Menggunakan\nSibersih',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  count > 0
                      ? '$count langkah mudah untuk mulai\nmengumpulkan poin dari sampahmu!'
                      : 'Ikuti panduan untuk mulai\nmengumpulkan poin dari sampahmu!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            height: 64,
            child: Image.asset('assets/logos/sibersih.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Pertanyaan Umum FAQ'),
        const SizedBox(height: 14),
        if (_faqs.isEmpty)
          _buildEmptyState(
            icon: Icons.help_outline_rounded,
            message: 'Belum ada pertanyaan umum.',
          )
        else
          ..._faqs.map((faq) => _FAQTile(faq: faq)),
      ],
    );
  }

  Widget _sectionHeader(String title) {
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
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? SibersihColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(SibersihRadius.md),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : SibersihColors.primary.withValues(alpha: 0.06),
        ),
        boxShadow: SibersihColors.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 10),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCTA() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? SibersihColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(SibersihRadius.lg),
        border: Border.all(color: SibersihColors.success.withValues(alpha: 0.25)),
        boxShadow: SibersihColors.cardShadow,
      ),
      child: Column(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 10),
          const Text(
            'Siap Mulai?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.2),
          ),
          const SizedBox(height: 6),
          Text(
            'Sekarang giliran kamu untuk berkontribusi!\nBuat laporan pertamamu sekarang.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Guide Card ───────────────────────────────────────────────

class _GuideCard extends StatefulWidget {
  final PanduanModel panduan;
  final Color color;

  const _GuideCard({
    required this.panduan,
    required this.color,
  });

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
      duration: const Duration(milliseconds: 250),
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
    final panduan = widget.panduan;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _expanded = !_expanded);
        if (_expanded) {
          _expandController.forward();
        } else {
          _expandController.reverse();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? SibersihColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(SibersihRadius.lg),
          border: Border.all(
            color: _expanded
                ? widget.color.withValues(alpha: 0.35)
                : (isDark ? Colors.white.withValues(alpha: 0.05) : SibersihColors.primary.withValues(alpha: 0.06)),
            width: 1.2,
          ),
          boxShadow: SibersihColors.softShadow,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Step number badge + emoji
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(SibersihRadius.md),
                        ),
                        child: Center(
                          child: Text(panduan.emoji,
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
                            color: widget.color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              panduan.nomorStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
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
                          panduan.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          panduan.description,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12, height: 1.45, fontWeight: FontWeight.w600),
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
            ),
            // Expanded content: tips + gambar
            SizeTransition(
              sizeFactor: CurvedAnimation(
                  parent: _expandController, curve: Curves.fastOutSlowIn),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar horizontal jika ada
                    if (panduan.gambarUrls.isNotEmpty) ...[
                      _buildImageCarousel(panduan.gambarUrls),
                      const SizedBox(height: 12),
                    ],
                    // Tips box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(SibersihRadius.md),
                        border: Border.all(color: widget.color.withValues(alpha: 0.18)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline_rounded,
                                  color: widget.color, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Tips Penting',
                                style: TextStyle(
                                  color: widget.color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (panduan.tips.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Tidak ada tips tambahan.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            )
                          else ...[
                            const SizedBox(height: 10),
                            ...panduan.tips.map(
                              (tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(Icons.check_circle_rounded,
                                          color: widget.color, size: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> urls) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(SibersihRadius.md),
            child: Image.network(
              urls[i],
              height: 180,
              width: 260,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 260,
                height: 180,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(SibersihRadius.md),
                ),
                child: Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: widget.color, size: 40),
                ),
              ),
              loadingBuilder: (_, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 260,
                  height: 180,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(SibersihRadius.md),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: widget.color,
                      strokeWidth: 2.5,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── FAQ Tile ─────────────────────────────────────────────────

class _FAQTile extends StatelessWidget {
  final FaqModel faq;

  const _FAQTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? SibersihColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(SibersihRadius.md),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : SibersihColors.primary.withValues(alpha: 0.05),
        ),
        boxShadow: SibersihColors.softShadow,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          faq.pertanyaan,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
        iconColor: SibersihColors.primary,
        collapsedIconColor: Colors.grey.shade500,
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq.jawaban,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
