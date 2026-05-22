import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class ProfilPage extends StatefulWidget {
  final void Function(bool) onToggleTheme;
  final bool isDarkMode;

  const ProfilPage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _notifEnabled = true;
  bool _biometricEnabled = false;
  bool _isUploadingPhoto = false;
  UserModel? _user;
  bool _loading = true;
  String? _localPhotoPath; // Local photo bytes URL after upload

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this)
      ..forward();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await SupabaseService.instance.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSourceSheet(picker: picker),
    );
    if (file == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await SupabaseService.instance.uploadFotoProfile(bytes);
      if (mounted && url != null) {
        setState(() {
          _user = _user?.copyWith(fotoUrl: url);
          _localPhotoPath = file.path;
        });
        _showSnack('Foto profil berhasil diperbarui! 📸');
      }
    } catch (_) {
      if (mounted) _showSnack('Gagal mengunggah foto. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user!;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(user),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPointsSummary(user),
                const SizedBox(height: 24),
                _sectionLabel('Informasi Pribadi'),
                const SizedBox(height: 12),
                _buildInfoSection(user),
                const SizedBox(height: 24),
                _sectionLabel('Pengaturan'),
                const SizedBox(height: 12),
                _buildSettingsSection(),
                const SizedBox(height: 24),
                _sectionLabel('Tentang Aplikasi'),
                const SizedBox(height: 12),
                _buildAboutSection(),
                const SizedBox(height: 24),
                _buildLogoutButton(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return SliverAppBar(
      expandedHeight: 290,
      collapsedHeight: 56,
      pinned: true,
      backgroundColor: const Color(0xFF1007BA),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A05A0), Color(0xFF2519D4)],
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
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              const Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Text('Profil Saya',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          // Avatar
                          GestureDetector(
                            onTap: _pickAndUploadPhoto,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _isUploadingPhoto
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : _localPhotoPath != null
                                        // TODO: use Image.network(user.fotoUrl!) when Firebase Storage connected
                                        ? const Center(
                                            child: Text('😎',
                                                style: TextStyle(fontSize: 46)))
                                        : const Center(
                                            child: Text('🙋',
                                                style: TextStyle(fontSize: 46))),
                              ),
                            ),
                          ),
                          // Camera badge
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadPhoto,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4)
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.camera_alt_rounded,
                                      size: 15, color: Color(0xFF1007BA)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(user.nama,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      Text('${user.nim} · ${user.jurusan}',
                          style:
                              const TextStyle(color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          '${_levelEmoji(user.level)} Level ${user.level}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  String _levelEmoji(String level) {
    switch (level) {
      case 'Platinum': return '💎';
      case 'Emas': return '🥇';
      case 'Aktif': return '🌱';
      default: return '🌱';
    }
  }

  Widget _buildPointsSummary(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1007BA), Color(0xFF4C3FE8)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1007BA).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _pointStat('⭐', '${user.totalPoin}', 'Total Poin'),
          _divider(),
          _pointStat('📦', '${user.jumlahLaporan}', 'Laporan'),
          _divider(),
          _pointStat('📊', '#${user.rank}', 'Peringkat'),
        ],
      ),
    );
  }

  Widget _pointStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _divider() => Container(height: 36, width: 1, color: Colors.white24);

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF1007BA),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildInfoSection(UserModel user) {
    return _card(children: [
      _infoTile(Icons.person_outline_rounded, 'Nama Lengkap', user.nama,
          () => _showEditDialog('Nama Lengkap', user.nama, onSave: (val) async {
                await SupabaseService.instance.updateUserProfile(nama: val);
                _loadUser();
              })),
      _divLine(),
      _infoTile(Icons.school_outlined, 'NIM', user.nim, null),
      _divLine(),
      _infoTile(Icons.business_outlined, 'Jurusan', user.jurusan,
          () => _showEditDialog('Jurusan', user.jurusan, onSave: (val) async {
                await SupabaseService.instance.updateUserProfile(jurusan: val);
                _loadUser();
              })),
      _divLine(),
      _infoTile(Icons.email_outlined, 'Email', user.email,
          () => _showEditDialog('Email', user.email, onSave: (val) async {
                await SupabaseService.instance.updateUserProfile(email: val);
                _loadUser();
              })),
      _divLine(),
      _infoTile(Icons.lock_outline_rounded, 'Kata Sandi', '••••••••',
          () => _showChangePassword()),
    ]);
  }

  Widget _buildSettingsSection() {
    return _card(children: [
      _switchTile(Icons.dark_mode_rounded, 'Mode Gelap', 'Tampilan gelap untuk mata',
          widget.isDarkMode, widget.onToggleTheme, const Color(0xFF1007BA)),
      _divLine(),
      _switchTile(Icons.notifications_outlined, 'Notifikasi', 'Info poin & laporan',
          _notifEnabled, (v) => setState(() => _notifEnabled = v), Colors.orange),
      _divLine(),
      _switchTile(Icons.fingerprint_rounded, 'Biometrik', 'Login sidik jari',
          _biometricEnabled,
          (v) => setState(() => _biometricEnabled = v), Colors.green),
      _divLine(),
      _navTile(Icons.language_rounded, 'Bahasa', 'Indonesia', Colors.blue),
    ]);
  }

  Widget _buildAboutSection() {
    return _card(children: [
      _navTile(Icons.help_outline_rounded, 'Bantuan & FAQ', null, Colors.purple),
      _divLine(),
      _navTile(Icons.policy_outlined, 'Kebijakan Privasi', null, Colors.teal),
      _divLine(),
      _navTile(Icons.star_outline_rounded, 'Beri Penilaian', null, Colors.amber),
      _divLine(),
      _navTile(Icons.info_outline_rounded, 'Versi Aplikasi', '1.0.0', Colors.grey),
    ]);
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: _showLogoutDialog,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20),
            SizedBox(width: 10),
            Text('Keluar dari Akun',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, VoidCallback? onTap) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1007BA).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1007BA), size: 18),
      ),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      trailing: onTap != null
          ? const Icon(Icons.edit_outlined, size: 16, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }

  Widget _switchTile(IconData icon, String title, String subtitle, bool value,
      void Function(bool) onChanged, Color color) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration:
            BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeColor: const Color(0xFF1007BA)),
    );
  }

  Widget _navTile(IconData icon, String title, String? value, Color color) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration:
            BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) Text(value, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
      onTap: () {},
    );
  }

  Widget _divLine() => const Divider(height: 0, indent: 68, endIndent: 16);

  void _showEditDialog(String field, String current,
      {required Future<void> Function(String) onSave}) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Ubah $field', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: '$field baru',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1007BA)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await onSave(ctrl.text.trim());
              if (mounted) _showSnack('$field berhasil diperbarui ✓');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1007BA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _passField('Kata sandi lama', oldCtrl),
            const SizedBox(height: 12),
            _passField('Kata sandi baru', newCtrl),
            const SizedBox(height: 12),
            _passField('Konfirmasi kata sandi baru', confirmCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService.instance
                  .changePassword(oldCtrl.text, newCtrl.text);
              if (mounted) _showSnack('Kata sandi berhasil diubah ✓');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1007BA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _passField(String hint, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1007BA), size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1007BA)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👋', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Yakin mau keluar?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Text(
              'Sampai jumpa lagi!\nJangan lupa terus jaga kebersihan. 🌿',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.instance.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/landing');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Photo source bottom sheet ────────────────────────────────

class _PhotoSourceSheet extends StatelessWidget {
  final ImagePicker picker;

  const _PhotoSourceSheet({required this.picker});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Ubah Foto Profil',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _sourceButton(
                  context,
                  icon: Icons.photo_camera_rounded,
                  label: 'Kamera',
                  color: const Color(0xFF1007BA),
                  onTap: () async {
                    final f = await picker.pickImage(
                        source: ImageSource.camera, imageQuality: 80);
                    if (context.mounted) Navigator.pop(context, f);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sourceButton(
                  context,
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  color: Colors.purple,
                  onTap: () async {
                    final f = await picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 80);
                    if (context.mounted) Navigator.pop(context, f);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sourceButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
