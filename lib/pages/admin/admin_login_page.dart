import 'package:flutter/material.dart';
import '../../app_tokens.dart';
import '../../services/supabase_service.dart';

/// Halaman login admin terpisah — gaya SB Admin 2 split-screen.
/// Akses langsung via `/#/admin-login` (tidak terhubung ke landing user).
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (SupabaseService.instance.isAdminLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await SupabaseService.instance.loginAdmin(
      _usernameCtrl.text,
      _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/admin/dashboard');
    } else {
      setState(() => _error = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      body: isWide ? _buildSplitLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildSplitLayout() {
    return Row(
      children: [
        Expanded(child: _buildBrandPanel()),
        SizedBox(
          width: 480,
          child: _buildLoginForm(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 220, child: _buildBrandPanel(compact: true)),
          _buildLoginForm(),
        ],
      ),
    );
  }

  Widget _buildBrandPanel({bool compact = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SibersihColors.primaryDeep,
            SibersihColors.primary,
            Color(0xFF2519D4),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: compact ? 72 : 96,
                    height: compact ? 72 : 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('🌿', style: TextStyle(fontSize: compact ? 36 : 48)),
                    ),
                  ),
                  SizedBox(height: compact ? 16 : 28),
                  Text(
                    'SIBERSIH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 28 : 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Panel Administrasi',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Kelola laporan, pengguna, dan reward kampus',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Selamat Datang!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E2E4A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masuk ke panel admin Sibersih',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: _inputDecoration('Username', Icons.person_outline_rounded),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Username wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: _inputDecoration('Password', Icons.lock_outline_rounded).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SibersihColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Masuk Admin',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: SibersihColors.primary, size: 20),
      filled: true,
      fillColor: SibersihColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: SibersihColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
