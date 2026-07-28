import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../repositories/auth_repository.dart';
import '../../../core/app_tokens.dart';
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
  late AnimationController _waveController;

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
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _bgController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _waveController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _logoEntry = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _titleEntry = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );
    _subtitleEntry = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );
    _buttonsEntry = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatController.dispose();
    _bgController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _googleLoading = true);
    final result = await AuthRepository.instance.loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Login Google gagal'),
          backgroundColor: SibersihColors.error,
        ),
      );
    }
  }

  void _showTermsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => const _TermsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topSpace = size.height * 0.07;
    final midSpace = size.height * 0.04;

    return Scaffold(
      body: Stack(
        children: [
          // ── Mesh animated gradient background ──
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => CustomPaint(
              painter: _LandingBgPainter(_bgController.value),
              size: size,
            ),
          ),

          // ── Animated SVG wave at bottom ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (_, __) => CustomPaint(
                painter: _WavePainter(_waveController.value),
                size: Size(size.width, 180),
              ),
            ),
          ),

          // ── Geometric circles decorations ──
          Positioned(
            top: -size.width * 0.18,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.55,
              height: size.width * 0.55,
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
            bottom: size.height * 0.12,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.5,
              height: size.width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 26),
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

                      const SizedBox(height: 26),

                      // ── Title & subtitle ──
                      AnimatedBuilder(
                        animation: _entryController,
                        builder: (_, __) => Opacity(
                          opacity: _titleEntry.value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - _titleEntry.value) * 24),
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Color(0xFFB8C4FF),
                                    ],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'SIBERSIH',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 7,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Opacity(
                                  opacity: _subtitleEntry.value,
                                  child: const Text(
                                    'Platform Pelaporan Sampah Kampus',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13.5,
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Feature pills ──
                      AnimatedBuilder(
                        animation: _entryController,
                        builder: (_, __) => Opacity(
                          opacity: _subtitleEntry.value,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _featurePill('🌿', 'Eco-Friendly',
                                  const Color(0xFF00C896)),
                              const SizedBox(width: 10),
                              _featurePill('⭐', 'Poin Reward',
                                  const Color(0xFFFFAA22)),
                              const SizedBox(width: 10),
                              _featurePill('📊', 'Tracking',
                                  const Color(0xFF00D4FF)),
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
                                // Masuk — solid primary
                                _buildPrimaryButton(
                                  label: 'Masuk',
                                  onTap: () => Navigator.pushNamed(
                                      context, '/login'),
                                  icon: Icons.login_rounded,
                                ),
                                const SizedBox(height: 12),

                                // Daftar — outlined
                                _buildOutlinedButton(
                                  label: 'Daftar Akun Baru',
                                  onTap: () => Navigator.pushNamed(
                                      context, '/register'),
                                  icon: Icons.person_add_rounded,
                                ),
                                const SizedBox(height: 22),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color:
                                                Colors.white.withValues(alpha: 0.2),
                                            height: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      child: Text('atau',
                                          style: TextStyle(
                                              color:
                                                  Colors.white.withValues(alpha: 0.4),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color:
                                                Colors.white.withValues(alpha: 0.2),
                                            height: 1)),
                                  ],
                                ),
                                const SizedBox(height: 22),

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

                      const SizedBox(height: 28),

                      // ── Partner logos ──
                      _buildPartnerLogos(),

                      const SizedBox(height: 18),

                      // ── S&K ──
                      _buildTermsText(),

                      const SizedBox(height: 28),
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

  // ── Primary button ──────────────────────────────────────────────────────
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return _PressableButton(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SibersihRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: SibersihColors.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: SibersihColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Outlined button ─────────────────────────────────────────────────────
  Widget _buildOutlinedButton({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return _PressableButton(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(SibersihRadius.md),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Logo circle
        Container(
          width: 98,
          height: 98,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFEEF0FF)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: SibersihColors.primary.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset('assets/logos/sibersih.png', fit: BoxFit.contain),
              )),
        ),
      ],
    );
  }

  // ── Feature pill ────────────────────────────────────────────────────────
  Widget _featurePill(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(SibersihRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 3),
          Text(
            text,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Partner logos ────────────────────────────────────────────────────────
  Widget _buildPartnerLogos() {
    final logoPaths = [
      'assets/logos/upi.svg',
      'assets/logos/bem.svg',
      'assets/logos/arunika.svg',
    ];

    return Column(
      children: [
        Text(
          'Didukung oleh',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.09),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(SibersihRadius.pill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(logoPaths.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withValues(alpha: 0.12),
                );
              }
              final path = logoPaths[i ~/ 2];
              return SizedBox(
                width: 54,
                height: 44,
                child: SvgPicture.asset(
                  path,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
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

  Widget _buildTermsText() {
    return GestureDetector(
      onTap: _showTermsSheet,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 11,
            height: 1.6,
          ),
          children: [
            const TextSpan(text: 'Dengan masuk, kamu setuju dengan\n'),
            TextSpan(
              text: 'Ketentuan Layanan',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white38,
              ),
            ),
            const TextSpan(text: ' & '),
            TextSpan(
              text: 'Kebijakan Privasi',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
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
}

// ── Pressable button with scale effect ───────────────────────────────────
class _PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableButton({required this.child, required this.onTap});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// ── Landing background painter ─────────────────────────────────────────
class _LandingBgPainter extends CustomPainter {
  final double t;

  _LandingBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Base
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
            Color(0xFF1E10C8),
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ).createShader(rect),
    );

    // Dynamic spot 1 — blue-cyan
    final c1 = Offset(
      size.width * (0.15 + 0.12 * math.sin(t * 2 * math.pi)),
      size.height * (0.25 + 0.08 * math.cos(t * 2 * math.pi)),
    );
    canvas.drawCircle(
      c1,
      size.width * 0.6,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFF4C3FE8).withValues(alpha: 0.3),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: c1, radius: size.width * 0.6)),
    );

    // Dynamic spot 2 — cyan accent
    final c2 = Offset(
      size.width * (0.85 + 0.08 * math.cos(t * 2 * math.pi + 1)),
      size.height * (0.65 + 0.1 * math.sin(t * 2 * math.pi + 1)),
    );
    canvas.drawCircle(
      c2,
      size.width * 0.45,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFF00D4FF).withValues(alpha: 0.1),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: c2, radius: size.width * 0.45)),
    );
  }

  @override
  bool shouldRepaint(covariant _LandingBgPainter old) => old.t != t;
}

// ── Animated wave painter ──────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double t;

  _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    _drawWave(canvas, size, paint1, t, 0.6);
    _drawWave(canvas, size, paint2, t + 0.3, 0.75);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, double phase,
      double heightFactor) {
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * heightFactor +
          20 * math.sin((x / size.width * 2 * math.pi) + phase * 2 * math.pi);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.t != t;
}

// ─────────────────────────────────────────────
// Terms & Conditions Bottom Sheet
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D0A9E), Color(0xFF0A05A0)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child:
                              Text('📋', style: TextStyle(fontSize: 19))),
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
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  children: const [
                    _TermsSection(
                      title: '1. Penerimaan Ketentuan',
                      body:
                          'Dengan mengakses atau menggunakan aplikasi SIBERSIH, kamu menyatakan telah membaca, memahami, dan menyetujui Syarat & Ketentuan serta Kebijakan Privasi ini.',
                    ),
                    _TermsSection(
                      title: '2. Penggunaan Layanan',
                      body:
                          'SIBERSIH adalah platform pelaporan sampah berbasis komunitas kampus. Kamu dapat melaporkan lokasi sampah, mengumpulkan poin reward, dan memantau progres kebersihan lingkungan.',
                    ),
                    _TermsSection(
                      title: '3. Akun Pengguna',
                      body:
                          'Kamu bertanggung jawab menjaga keamanan akun dan kata sandi. Segala aktivitas yang terjadi melalui akunmu menjadi tanggung jawabmu.',
                    ),
                    _TermsSection(
                      title: '4. Pelaporan Konten',
                      body:
                          'Kamu setuju untuk hanya mengirimkan laporan yang akurat dan relevan. Laporan palsu atau penyalahgunaan fitur poin dapat mengakibatkan penangguhan akun.',
                    ),
                    _TermsSection(
                      title: '5. Kebijakan Privasi',
                      body:
                          'Kami mengumpulkan data yang diperlukan untuk menjalankan layanan, termasuk informasi akun dan aktivitas penggunaan. Data ini tidak akan dijual kepada pihak ketiga.',
                    ),
                    _TermsSection(
                      title: '6. Hak Kekayaan Intelektual',
                      body:
                          'Seluruh konten, logo, tampilan, dan kode dalam aplikasi SIBERSIH adalah milik tim pengembang. Penggandaan tanpa izin dilarang keras.',
                    ),
                    _TermsSection(
                      title: '7. Perubahan Ketentuan',
                      body:
                          'Kami berhak mengubah ketentuan ini sewaktu-waktu. Perubahan signifikan akan diberitahukan melalui notifikasi aplikasi.',
                    ),
                    _TermsSection(
                      title: '8. Hubungi Kami',
                      body:
                          'Jika ada pertanyaan terkait Syarat & Ketentuan ini, silakan hubungi tim SIBERSIH melalui menu Bantuan di dalam aplikasi.',
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Terakhir diperbarui: Juni 2025',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
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
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: SibersihColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Saya Mengerti',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _pressed
                  ? [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.14),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.13),
                      Colors.white.withValues(alpha: 0.07),
                    ],
            ),
            borderRadius: BorderRadius.circular(SibersihRadius.md),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.35), width: 1.5),
          ),
          child: widget.loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google "G" SVG inline
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(painter: _GoogleGPainter()),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Lanjutkan dengan Google',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Google "G" logo painted directly (no asset needed) ────────────────────
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // White circle background
    canvas.drawCircle(c, r, Paint()..color = Colors.white);

    // "G" path approximation with four coloured arcs + horizontal bar
    final colors = [
      const Color(0xFF4285F4), // blue  — top right
      const Color(0xFF34A853), // green — bottom right
      const Color(0xFFFBBC05), // yellow— bottom left
      const Color(0xFFEA4335), // red   — top left
    ];
    const sweeps = [math.pi / 2, math.pi / 2, math.pi / 2, math.pi / 2];
    const starts = [-math.pi / 4, math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4];

    final arcR = r * 0.72;
    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.28
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: arcR),
        starts[i],
        sweeps[i],
        false,
        paint,
      );
    }

    // Horizontal bar (right half)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = r * 0.28
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + arcR, c.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}