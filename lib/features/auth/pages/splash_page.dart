import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import '../../../core/app_tokens.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _bgController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bgController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      ),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();
    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Jika SplashPage bukan lagi route yang aktif (misal user masuk lewat deep link /admin-login), batalkan redirect.
    if (!ModalRoute.of(context)!.isCurrent) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/landing');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bgController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // ── Animated mesh gradient background ──
            AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => CustomPaint(
                painter: _MeshGradientPainter(_bgController.value),
                size: size,
              ),
            ),

            // ── Geometric SVG decorations ──
            Positioned(
              top: -size.height * 0.05,
              right: -size.width * 0.2,
              child: _GeometricDecor(size: size.width * 0.65, opacity: 0.08),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              left: -size.width * 0.25,
              child: _GeometricDecor(size: size.width * 0.75, opacity: 0.06),
            ),

            // ── Ripple rings around logo ──
            Center(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (_, __) => CustomPaint(
                  painter: _RipplePainter(_bgController.value * 0.5),
                  size: const Size(320, 320),
                ),
              ),
            ),

            // ── Floating particles ──
            AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(_bgController.value),
                size: size,
              ),
            ),

            // ── Main content ──
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) => Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: _buildLogo(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Text
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => SlideTransition(
                      position: _textSlide,
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            // SIBERSIH wordmark
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Color(0xFFB8C4FF)],
                              ).createShader(bounds),
                              child: const Text(
                                'SIBERSIH',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Tagline pill
                            Opacity(
                              opacity: _taglineOpacity.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 7),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.12),
                                      Colors.white.withValues(alpha: 0.06),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      SibersihRadius.pill),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'Platform Kebersihan Kampus 🌿',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Progress bar
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(SibersihRadius.pill),
                            child: LinearProgressIndicator(
                              value: _progressController.value,
                              minHeight: 3,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Memuat...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
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
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 114,
      height: 114,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFEEF0FF)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: 50,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: SibersihColors.primary.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Image.asset('assets/logos/sibersih.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// ── Geometric decoration (hexagonal rings) ────────────────────────────────
class _GeometricDecor extends StatelessWidget {
  final double size;
  final double opacity;

  const _GeometricDecor({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HexPainter(opacity),
      size: Size(size, size),
    );
  }
}

class _HexPainter extends CustomPainter {
  final double opacity;

  _HexPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int i = 1; i <= 3; i++) {
      final r = size.width * 0.15 * i;
      final path = Path();
      for (int j = 0; j < 6; j++) {
        final angle = j * math.pi / 3 - math.pi / 6;
        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Mesh gradient background ─────────────────────────────────────────────
class _MeshGradientPainter extends CustomPainter {
  final double t;

  _MeshGradientPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Base gradient
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF050380),
          Color(0xFF0A05A0),
          Color(0xFF1007BA),
          Color(0xFF2519D4),
        ],
        stops: [0.0, 0.3, 0.65, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // Animated radial overlay
    final cx1 = size.width * (0.2 + 0.15 * math.sin(t * 2 * math.pi));
    final cy1 = size.height * (0.3 + 0.1 * math.cos(t * 2 * math.pi));
    final radialPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4C3FE8).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(cx1, cy1), radius: size.width * 0.5));
    canvas.drawCircle(Offset(cx1, cy1), size.width * 0.5, radialPaint1);

    final cx2 = size.width * (0.8 + 0.1 * math.cos(t * 2 * math.pi));
    final cy2 = size.height * (0.7 + 0.12 * math.sin(t * 2 * math.pi));
    final radialPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00D4FF).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(cx2, cy2), radius: size.width * 0.45));
    canvas.drawCircle(Offset(cx2, cy2), size.width * 0.45, radialPaint2);
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter old) => old.t != t;
}

// ── Ripple rings ─────────────────────────────────────────────────────────
class _RipplePainter extends CustomPainter {
  final double progress;

  _RipplePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 4; i++) {
      final p = ((progress + i * 0.25) % 1.0);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: (1 - p) * 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, p * 150, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => old.progress != progress;
}

// ── Floating particles ────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  static final List<_ParticleDot> _particles =
      List.generate(24, (i) => _ParticleDot(i));

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.12);
    for (final p in _particles) {
      final x = (p.x * size.width + progress * p.speed * 40) % size.width;
      final y = (p.y * size.height - progress * p.speed * 70) % size.height;
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}

class _ParticleDot {
  late double x, y, radius, speed;

  _ParticleDot(int seed) {
    final rng = math.Random(seed * 13337);
    x = rng.nextDouble();
    y = rng.nextDouble();
    radius = rng.nextDouble() * 2.5 + 0.8;
    speed = rng.nextDouble() * 0.5 + 0.3;
  }
}
