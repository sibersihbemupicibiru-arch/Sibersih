import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../repositories/auth_repository.dart';

/// Halaman konfirmasi email — muncul setelah register manual berhasil.
/// User harus klik link di email sebelum bisa login.
///
/// Cara pakai di routes (main.dart / app_router.dart):
///   '/email-confirmation': (context) {
///     final email = ModalRoute.of(context)!.settings.arguments as String;
///     return EmailConfirmationPage(email: email);
///   },
class EmailConfirmationPage extends StatefulWidget {
  final String email;

  const EmailConfirmationPage({super.key, required this.email});

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isResending = false;
  int _resendCooldown = 0; // detik cooldown sebelum boleh kirim ulang

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    if (_isResending || _resendCooldown > 0) return;

    setState(() {
      _isResending = true;
    });

    final result = await AuthRepository.instance.resendConfirmationEmail(
      email: widget.email,
    );

    if (!mounted) return;
    setState(() {
      _isResending = false;
    });

    if (result.success) {
      // Cooldown 60 detik agar tidak spam
      _startCooldown(60);
      _showSnack('Email konfirmasi sudah dikirim ulang! 📬');
    } else {
      _showSnack(result.errorMessage ?? 'Gagal mengirim ulang email. Coba lagi.');
    }
  }

  void _startCooldown(int seconds) {
    setState(() => _resendCooldown = seconds);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
        _startCooldown(_resendCooldown);
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1007BA),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // ── Gradient header ──
            Container(
              height: mq.size.height * 0.45,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A05A0), Color(0xFF2519D4)],
                ),
              ),
            ),

            // ── Wave separator ──
            Positioned(
              top: mq.size.height * 0.40,
              left: 0,
              right: 0,
              child: CustomPaint(
                painter: _WavePainter(Theme.of(context).scaffoldBackgroundColor),
                child: SizedBox(width: mq.size.width, height: 52),
              ),
            ),

            // ── Konten utama ──
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 20),
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/login'),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Ilustrasi envelope ──
                        _EnvelopeIllustration(),

                        const SizedBox(height: 24),

                        // ── Judul ──
                        const Text(
                          'Cek Email Kamu! 📬',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kami sudah mengirim link konfirmasi ke',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 36),

                        // ── Card instruksi ──
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Langkah selanjutnya:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _Step(
                                number: '1',
                                text: 'Buka aplikasi email kamu',
                              ),
                              const SizedBox(height: 12),
                              const _Step(
                                number: '2',
                                text: 'Cari email dari Sibersih (cek juga folder Spam)',
                              ),
                              const SizedBox(height: 12),
                              const _Step(
                                number: '3',
                                text: 'Klik tombol "Konfirmasi Email" di dalam email',
                              ),
                              const SizedBox(height: 12),
                              const _Step(
                                number: '4',
                                text: 'Kembali ke sini dan login dengan akun kamu',
                              ),
                              const SizedBox(height: 24),

                              // ── Tombol ke Login ──
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(context, '/login'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1007BA),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                    elevation: 4,
                                    shadowColor:
                                        const Color(0xFF1007BA).withValues(alpha: 0.4),
                                  ),
                                  child: const Text(
                                    'Ke Halaman Login',
                                    style: TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Kirim ulang email ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tidak menerima email? ',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: (_isResending || _resendCooldown > 0)
                                  ? null
                                  : _resendEmail,
                              child: _isResending
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF1007BA)),
                                    )
                                  : Text(
                                      _resendCooldown > 0
                                          ? 'Kirim ulang (${_resendCooldown}s)'
                                          : 'Kirim ulang',
                                      style: TextStyle(
                                        color: (_resendCooldown > 0)
                                            ? Colors.grey
                                            : const Color(0xFF1007BA),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
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
}

// ── Widget Ilustrasi Amplop ──
class _EnvelopeIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 2),
      ),
      child: const Center(
        child: Icon(
          Icons.mark_email_unread_outlined,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Widget Step instruksi ──
class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF1007BA).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF1007BA),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Wave painter (sama seperti di register_page.dart) ──
class _WavePainter extends CustomPainter {
  final Color color;

  _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.45)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width, h * 0.45)
      ..lineTo(size.width, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}