import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../repositories/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  // Jika dari Google login → googleEmail diisi, mode "lengkapi profil"
  // Jika register biasa      → googleEmail null
  final String? googleEmail;

  const RegisterPage({super.key, this.googleEmail});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _selectedJurusan;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreeTerms = false;

  // true  → dari Google, sembunyikan password & lock email
  bool get _isGoogleMode => widget.googleEmail != null;

  static const List<String> _jurusanList = [
    'Teknik Komputer',
    'Pendidikan Multimedia',
    'Rekayasa Perangkat Lunak',
    'Pendidikan Guru Sekolah Dasar (PGSD)',
    'Pendidikan Guru Pendidikan Anak Usia Dini (PGPAUD)'
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(milliseconds: 800), vsync: this)
          ..forward();

    // Prefill email dari akun Google
    if (_isGoogleMode) {
      _emailController.text = widget.googleEmail!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJurusan == null) {
      _showSnack('Pilih jurusan kamu terlebih dahulu 🎓');
      return;
    }
    if (!_agreeTerms) {
      _showSnack('Centang persetujuan Syarat & Ketentuan dulu ya.');
      return;
    }

    setState(() => _isLoading = true);

    if (_isGoogleMode) {
      // ── Mode Google: user sudah ter-auth, tinggal simpan profil ──
      final result = await AuthRepository.instance.completeGoogleProfile(
        nama: _nameController.text.trim(),
        nim: _nimController.text.trim(),
        jurusan: _selectedJurusan!,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success) {
        // Google mode: langsung ke home karena email sudah terverifikasi Google
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showSnack(result.errorMessage ?? 'Gagal menyimpan data. Coba lagi.');
      }
    } else {
      // ── Mode Manual: register biasa, tunggu konfirmasi email ──
      final result = await AuthRepository.instance.register(
        nama: _nameController.text.trim(),
        nim: _nimController.text.trim(),
        jurusan: _selectedJurusan!,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success) {
        // FIX: Jangan langsung ke /home — arahkan ke halaman konfirmasi email
        Navigator.pushReplacementNamed(
          context,
          '/email-confirmation',
          arguments: _emailController.text.trim(),
        );
      } else {
        _showSnack(result.errorMessage ?? 'Gagal mendaftar. Coba lagi.');
      }
    }
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
    final waveTop = mq.size.height * 0.26;

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
            Container(
              height: mq.size.height * 0.32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A05A0), Color(0xFF2519D4)],
                ),
              ),
            ),
            Positioned(
              top: waveTop,
              left: 0,
              right: 0,
              child: CustomPaint(
                painter: _WavePainter(Theme.of(context).scaffoldBackgroundColor),
                child: SizedBox(width: mq.size.width, height: 52),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isGoogleMode ? 'Lengkapi Profil' : 'Buat Akun Baru',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isGoogleMode
                            ? 'Isi data diri kamu untuk mulai 🌿'
                            : 'Bergabung dan mulai kumpulkan poin! 🥤',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      if (_isGoogleMode) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                    color: Colors.white, shape: BoxShape.circle),
                                child: const Center(
                                  child: Text('G',
                                      style: TextStyle(
                                          color: Color(0xFF4285F4),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.googleEmail!,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Container(
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Nama Lengkap'),
                              const SizedBox(height: 8),
                              _field(
                                controller: _nameController,
                                hint: 'Nama lengkap kamu',
                                icon: Icons.badge_outlined,
                                validator: (v) =>
                                    (v == null || v.trim().length < 2)
                                        ? 'Minimal 2 karakter'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              _label('NIM'),
                              const SizedBox(height: 8),
                              _field(
                                controller: _nimController,
                                hint: 'Nomor Induk Mahasiswa',
                                icon: Icons.school_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (v == null || v.trim().length < 6)
                                        ? 'NIM minimal 6 digit'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              _label('Jurusan'),
                              const SizedBox(height: 8),
                              _buildJurusanDropdown(),
                              const SizedBox(height: 16),

                              // ── Email: disabled & prefilled jika Google mode ──
                              _label('Email Kampus'),
                              const SizedBox(height: 8),
                              _field(
                                controller: _emailController,
                                hint: 'email@kampus.ac.id',
                                icon: _isGoogleMode
                                    ? Icons.verified_outlined
                                    : Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_isGoogleMode,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                                  if (!v.contains('@')) return 'Format email tidak valid';
                                  return null;
                                },
                              ),

                              // ── Password: HANYA tampil jika bukan Google mode ──
                              if (!_isGoogleMode) ...[
                                const SizedBox(height: 16),
                                _label('Kata Sandi'),
                                const SizedBox(height: 8),
                                _field(
                                  controller: _passwordController,
                                  hint: 'Min. 8 karakter',
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
                                    onPressed: () =>
                                        setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.length < 8) ? 'Minimal 8 karakter' : null,
                                ),
                                const SizedBox(height: 16),
                                _label('Konfirmasi Kata Sandi'),
                                const SizedBox(height: 8),
                                _field(
                                  controller: _confirmController,
                                  hint: 'Ulangi kata sandi',
                                  icon: Icons.lock_reset_outlined,
                                  obscure: _obscureConfirm,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscureConfirm = !_obscureConfirm),
                                  ),
                                  validator: (v) {
                                    if (v != _passwordController.text) {
                                      return 'Kata sandi tidak sama';
                                    }
                                    return null;
                                  },
                                ),
                              ],

                              const SizedBox(height: 20),
                              // Terms checkbox
                              Material(
                                color: const Color(0xFF1007BA).withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value: _agreeTerms,
                                          onChanged: (v) =>
                                              setState(() => _agreeTerms = v ?? false),
                                          fillColor:
                                              WidgetStateProperty.resolveWith((states) {
                                            if (states.contains(WidgetState.selected)) {
                                              return const Color(0xFF1007BA);
                                            }
                                            return null;
                                          }),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5)),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 10),
                                            child: Text(
                                              'Saya setuju dengan Syarat & Ketentuan serta Kebijakan Privasi Sibersih',
                                              style: TextStyle(
                                                fontSize: 12,
                                                height: 1.4,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1007BA),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                    elevation: 6,
                                    shadowColor:
                                        const Color(0xFF1007BA).withValues(alpha: 0.4),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2.5))
                                      : Text(
                                          _isGoogleMode
                                              ? 'Simpan & Mulai'
                                              : 'Daftar Sekarang',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_isGoogleMode)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Sudah punya akun? ',
                                style: TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushReplacementNamed(context, '/login'),
                              child: const Text('Masuk',
                                  style: TextStyle(
                                      color: Color(0xFF1007BA),
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),
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

  Widget _buildJurusanDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedJurusan,
      onChanged: (val) => setState(() => _selectedJurusan = val),
      decoration: InputDecoration(
        hintText: 'Pilih jurusan',
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon:
            const Icon(Icons.business_outlined, color: Color(0xFF1007BA), size: 20),
        filled: true,
        fillColor: const Color(0xFF1007BA).withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1007BA), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (_) => _selectedJurusan == null ? 'Pilih jurusan' : null,
      items: _jurusanList
          .map((j) =>
              DropdownMenuItem(value: j, child: Text(j, style: const TextStyle(fontSize: 14))))
          .toList(),
      dropdownColor: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1007BA)),
    );
  }

  Widget _label(String text) => Text(
        text,
        style:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey),
      );

  Widget _field({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool obscure = false,
    bool enabled = true,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      style: TextStyle(
        color: enabled
            ? Theme.of(context).textTheme.bodyMedium?.color
            : Colors.grey,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF1007BA), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: enabled
            ? const Color(0xFF1007BA).withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1007BA), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

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