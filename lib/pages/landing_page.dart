import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/supabase_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _floatController;
  late AnimationController _bgController;

  late Animation<double> _logoEntry;
  late Animation<double> _titleEntry;
  late Animation<double> _subtitleEntry;
  late Animation<double> _buttonsEntry;
  late Animation<double> _floatAnim;

  bool _googleLoading = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _logoEntry = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );
    _titleEntry = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _subtitleEntry = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );
    _buttonsEntry = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _googleLoading = true);
    final result = await SupabaseService.instance.loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Login Google gagal'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showTermsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => const _TermsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topSpace = size.height * 0.09;
    final midSpace = size.height * 0.06;

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient background ──
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    math.cos(_bgController.value * 2 * math.pi) * 0.5,
                    math.sin(_bgController.value * 2 * math.pi) * 0.5,
                  ),
                  end: Alignment(
                    -math.cos(_bgController.value * 2 * math.pi) * 0.5,
                    -math.sin(_bgController.value * 2 * math.pi) * 0.5,
                  ),
                  colors: const [
                    Color(0xFF0A05A0),
                    Color(0xFF1007BA),
                    Color(0xFF2A1ED0),
                    Color(0xFF0E0890),
                  ],
                ),
              ),
            ),
          ),

          // ── Decorative circles ──
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(height: topSpace),

                      // ── Logo ──
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_entryController, _floatController]),
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, _floatAnim.value),
                          child: Transform.scale(
                            scale: _logoEntry.value,
                            child: Opacity(
                              opacity: _logoEntry.value.clamp(0.0, 1.0),
                              child: _buildLogo(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Title & subtitle ──
                      AnimatedBuilder(
                        animation: _entryController,
                        builder: (_, __) => Opacity(
                          opacity: _titleEntry.value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - _titleEntry.value) * 20),
                            child: Column(
                              children: [
                                const Text(
                                  'SIBERSIH',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Opacity(
                                  opacity: _subtitleEntry.value,
                                  child: const Text(
                                    'Platform Pelaporan Sampah Kampus',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Feature pills ──
                      AnimatedBuilder(
                        animation: _entryController,
                        builder: (_, __) => Opacity(
                          opacity: _subtitleEntry.value,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _pill('Eco-Friendly', 'assets/icons/leaf.png'),
                              _pill('Poin Reward', 'assets/icons/piala.png'),
                              _pill('Tracking', 'assets/icons/bar.webp'),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: midSpace),

                      // ── Buttons ──
                      AnimatedBuilder(
                        animation: _entryController,
                        builder: (_, __) => Opacity(
                          opacity: _buttonsEntry.value,
                          child: Transform.translate(
                            offset:
                                Offset(0, (1 - _buttonsEntry.value) * 40),
                            child: Column(
                              children: [
                                // Masuk
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pushNamed(context, '/login'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor:
                                          const Color(0xFF1007BA),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                      shadowColor: Colors.black38,
                                    ),
                                    child: const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Daftar
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context, '/register'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.white54, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Daftar Akun Baru',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Divider
                                const Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color: Colors.white24,
                                            height: 1)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 14),
                                      child: Text('atau',
                                          style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 13)),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: Colors.white24,
                                            height: 1)),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Google login
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: _GoogleButton(
                                    loading: _googleLoading,
                                    onPressed: _googleLoading
                                        ? null
                                        : _handleGoogleLogin,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Partner logos ──
                      _buildPartnerLogos(),

                      const SizedBox(height: 20),

                      // ── S&K ──
                      _buildTermsText(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Partner logos — satu pill lonjong ──
  Widget _buildPartnerLogos() {
    // Ganti path di bawah dengan path asset gambar logo masing-masing mitra.
    // Pastikan sudah didaftarkan di pubspec.yaml under flutter > assets.
    // Contoh: assets/logos/logo_kampus.png
    final logoPaths = [
      'logos/upi.svg',
      'logos/bem.svg',
      'logos/arunika.svg',
    ];

    return Column(
      children: [
        const Text(
          'Didukung oleh',
          style: TextStyle(
            color: Colors.white24,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(logoPaths.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Divider tipis antar logo
                return Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: Colors.white12,
                );
              }
              final path = logoPaths[i ~/ 2];
              return SizedBox(
                width: 56,
                height: 48,
                child: SvgPicture.asset(
                  path,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    
                    child: const Center(
                      child: Icon(Icons.image_outlined,
                          color: Colors.white24, size: 18),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── S&K text with tappable links ──
  Widget _buildTermsText() {
    return GestureDetector(
      onTap: _showTermsSheet,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 11,
            height: 1.6,
          ),
          children: [
            const TextSpan(text: 'Dengan masuk, kamu setuju dengan\n'),
            TextSpan(
              text: 'Ketentuan Layanan',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white38,
              ),
              // tap handled by parent GestureDetector
            ),
            const TextSpan(text: ' & '),
            TextSpan(
              text: 'Kebijakan Privasi',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.25),
            blurRadius: 30,
            spreadRadius: 8,
          ),
        ],
      ),
      child: const Center(child: Text('🌿', style: TextStyle(fontSize: 48))),
    );
  }

Widget _pill(String text, String imagePath) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 7,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imagePath,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),

        const SizedBox(width: 6),

        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
}

// ─────────────────────────────────────────────
// Terms & Conditions Bottom Sheet (popup page)
// ─────────────────────────────────────────────
class _TermsSheet extends StatelessWidget {
  const _TermsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D0A9E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                          child:
                              Text('📋', style: TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Syarat & Ketentuan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.white.withOpacity(0.1), height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  children: const [
                    _TermsSection(
                      title: '1. Penerimaan Ketentuan',
                      body:
                          'Dengan mengakses atau menggunakan aplikasi SIBERSIH, kamu menyatakan telah membaca, memahami, dan menyetujui Syarat & Ketentuan serta Kebijakan Privasi ini. Jika kamu tidak menyetujui ketentuan ini, harap tidak menggunakan aplikasi.',
                    ),
                    _TermsSection(
                      title: '2. Penggunaan Layanan',
                      body:
                          'SIBERSIH adalah platform pelaporan sampah berbasis komunitas kampus. Kamu dapat melaporkan lokasi sampah, mengumpulkan poin reward, dan memantau progres kebersihan lingkungan. Layanan ini hanya untuk penggunaan pribadi dan non-komersial.',
                    ),
                    _TermsSection(
                      title: '3. Akun Pengguna',
                      body:
                          'Kamu bertanggung jawab menjaga keamanan akun dan kata sandi. Segala aktivitas yang terjadi melalui akunmu menjadi tanggung jawabmu. Segera hubungi kami jika mendeteksi penggunaan akun yang tidak sah.',
                    ),
                    _TermsSection(
                      title: '4. Pelaporan Konten',
                      body:
                          'Kamu setuju untuk hanya mengirimkan laporan yang akurat dan relevan. Laporan palsu, konten yang menyesatkan, atau penyalahgunaan fitur poin dapat mengakibatkan penangguhan akun tanpa pemberitahuan sebelumnya.',
                    ),
                    _TermsSection(
                      title: '5. Kebijakan Privasi',
                      body:
                          'Kami mengumpulkan data yang diperlukan untuk menjalankan layanan, termasuk informasi akun, lokasi laporan, dan aktivitas penggunaan. Data ini tidak akan dijual kepada pihak ketiga. Selengkapnya dapat dibaca di halaman Kebijakan Privasi.',
                    ),
                    _TermsSection(
                      title: '6. Hak Kekayaan Intelektual',
                      body:
                          'Seluruh konten, logo, tampilan, dan kode dalam aplikasi SIBERSIH adalah milik tim pengembang. Penggandaan atau distribusi tanpa izin tertulis dilarang keras.',
                    ),
                    _TermsSection(
                      title: '7. Perubahan Ketentuan',
                      body:
                          'Kami berhak mengubah ketentuan ini sewaktu-waktu. Perubahan signifikan akan diberitahukan melalui notifikasi aplikasi. Penggunaan berkelanjutan setelah perubahan dianggap sebagai persetujuan terhadap ketentuan baru.',
                    ),
                    _TermsSection(
                      title: '8. Hubungi Kami',
                      body:
                          'Jika ada pertanyaan terkait Syarat & Ketentuan ini, silakan hubungi tim SIBERSIH melalui menu Bantuan di dalam aplikasi atau melalui email resmi yang tersedia di halaman profil.',
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Terakhir diperbarui: Juni 2025',
                      style:
                          TextStyle(color: Colors.white24, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Accept button
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1007BA),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Saya Mengerti',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String body;

  const _TermsSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Google Button
// ─────────────────────────────────────────────
class _GoogleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const _GoogleButton({required this.onPressed, this.loading = false});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _hovered
              ? Colors.white.withOpacity(0.18)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white30, width: 1.5),
        ),
        child: TextButton(
          onPressed: widget.onPressed,
          style: TextButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('G',
                            style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontWeight: FontWeight.w900,
                                fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Lanjutkan dengan Google',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}