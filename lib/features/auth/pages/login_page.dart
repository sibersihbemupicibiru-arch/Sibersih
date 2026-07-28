import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../repositories/auth_repository.dart';
import '../../../core/app_tokens.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _bgController;
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMsg;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);
    _bgController = AnimationController(
        duration: const Duration(seconds: 8), vsync: this)
      ..repeat();
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final result = await AuthRepository.instance
        .login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _errorMsg = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Animated background ──
            AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => CustomPaint(
                painter: _LoginBgPainter(_bgController.value),
                size: size,
              ),
            ),

            // ── Smooth wave transition ──
            Positioned(
              top: size.height * 0.34,
              left: 0,
              right: 0,
              child: CustomPaint(
                painter: _SmoothWavePainter(
                    Theme.of(context).scaffoldBackgroundColor),
                size: Size(size.width, 70),
              ),
            ),

            // ── Decorative ring top-right ──
            Positioned(
              top: -size.width * 0.12,
              right: -size.width * 0.15,
              child: Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08), width: 1.5),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Back button
                        _buildBackButton(),
                        const SizedBox(height: 14),

                        // Logo + title
                        Center(
                          child: Column(
                            children: [
                              _buildLogoCircle(),
                              const SizedBox(height: 14),
                              const Text(
                                'Selamat Datang!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Masuk ke akun Sibersih-mu',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Form card ──
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius:
                                BorderRadius.circular(SibersihRadius.xl),
                            boxShadow: [
                              BoxShadow(
                                color: SibersihColors.primary.withValues(alpha: 0.15),
                                blurRadius: 32,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Email / NIM'),
                                const SizedBox(height: 8),
                                _buildField(
                                  controller: _emailController,
                                  hint: 'Masukkan email atau NIM',
                                  icon: Icons.person_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Wajib diisi' : null,
                                ),
                                const SizedBox(height: 20),
                                _label('Kata Sandi'),
                                const SizedBox(height: 8),
                                _buildField(
                                  controller: _passwordController,
                                  hint: 'Masukkan kata sandi',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                  validator: (v) =>
                                      v!.length < 6
                                          ? 'Min 6 karakter'
                                          : null,
                                ),

                                // Error message
                                if (_errorMsg != null) ...[
                                  const SizedBox(height: 12),
                                  _buildErrorBanner(_errorMsg!),
                                ],

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Lupa Kata Sandi?',
                                      style: TextStyle(
                                        color: SibersihColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Submit button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          SibersihColors.primary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          SibersihColors.primary
                                              .withValues(alpha: 0.6),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              SibersihRadius.sm)),
                                      elevation: 8,
                                      shadowColor: SibersihColors.primary
                                          .withValues(alpha: 0.45),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child:
                                                CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5))
                                        : const Text(
                                            'Masuk',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Sign up link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Belum punya akun? ',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13.5),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(
                                    context, '/register'),
                                child: const Text(
                                  'Daftar Sekarang',
                                  style: TextStyle(
                                    color: SibersihColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(SibersihRadius.sm),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildLogoCircle() {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFEEF0FF)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset('assets/logos/sibersih.png', fit: BoxFit.contain),
          )),
    );
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SibersihColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(SibersihRadius.sm),
        border:
            Border.all(color: SibersihColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: SibersihColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                  color: SibersihColors.error, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Colors.grey,
        ),
      );

  Widget _buildField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: SibersihColors.primary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: SibersihColors.primary.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SibersihRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SibersihRadius.sm),
          borderSide:
              const BorderSide(color: SibersihColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SibersihRadius.sm),
          borderSide: const BorderSide(color: SibersihColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SibersihRadius.sm),
          borderSide:
              const BorderSide(color: SibersihColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Login background painter ──────────────────────────────────────────────
class _LoginBgPainter extends CustomPainter {
  final double t;

  _LoginBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Top section: blue gradient header
    final headerRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.42);
    canvas.drawRect(
      headerRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A05A0),
            Color(0xFF1007BA),
            Color(0xFF2519D4),
          ],
        ).createShader(headerRect),
    );

    // Animated accent spot
    final cx = size.width * (0.75 + 0.1 * math.sin(t * 2 * math.pi));
    final cy = size.height * (0.12 + 0.05 * math.cos(t * 2 * math.pi));
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.38,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF4C3FE8).withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
            center: Offset(cx, cy), radius: size.width * 0.38)),
    );
  }

  @override
  bool shouldRepaint(covariant _LoginBgPainter old) => old.t != t;
}

// ── Smooth wave painter ────────────────────────────────────────────────────
class _SmoothWavePainter extends CustomPainter {
  final Color color;

  _SmoothWavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 42)
      ..cubicTo(size.width * 0.25, 10, size.width * 0.75, 10,
          size.width, 42)
      ..lineTo(size.width, 70)
      ..lineTo(0, 70)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
