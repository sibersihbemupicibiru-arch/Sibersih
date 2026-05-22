import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/supabase_service.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    // Jika sukses: browser redirect ke Google → balik ke app → 
    // onAuthStateChange di main.dart yang handle navigasi ke /home
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
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
          // Decorative circles
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
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Floating logo
                  AnimatedBuilder(
                    animation: Listenable.merge([_entryController, _floatController]),
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
                  const SizedBox(height: 32),
                  // Title
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
                  // Feature pills
                  AnimatedBuilder(
                    animation: _entryController,
                    builder: (_, __) => Opacity(
                      opacity: _subtitleEntry.value,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          _pill('🌿 Eco-Friendly'),
                          _pill('🏆 Poin Reward'),
                          _pill('📊 Tracking'),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Buttons
                  AnimatedBuilder(
                    animation: _entryController,
                    builder: (_, __) => Opacity(
                      opacity: _buttonsEntry.value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - _buttonsEntry.value) * 40),
                        child: Column(
                          children: [
                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/login'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1007BA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
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
                            // Register button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
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
                                Expanded(child: Divider(color: Colors.white24, height: 1)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Text('atau',
                                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                                ),
                                Expanded(child: Divider(color: Colors.white24, height: 1)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Google login — now wired to real auth
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: _GoogleButton(
                                loading: _googleLoading,
                                onPressed: _googleLoading ? null : _handleGoogleLogin,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Dengan masuk, kamu setuju dengan\nKetentuan Layanan & Kebijakan Privasi',
                    style: TextStyle(color: Colors.white30, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
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

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }
}

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
