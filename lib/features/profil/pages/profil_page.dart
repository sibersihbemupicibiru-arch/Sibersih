import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/user_model.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/auth_repository.dart';
import '../../../core/app_tokens.dart';
import '../../../widgets/image_cropper_page.dart';

class ProfilPage extends StatefulWidget {
  final void Function(bool) onToggleTheme;

  const ProfilPage({
    super.key,
    required this.onToggleTheme,
  });

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isUploadingPhoto = false;
  UserModel? _user;
  bool _loading = true;
  // ignore: unused_field
  String? _localPhotoPath;

  static const List<String> _jurusanList = [
    'Teknik Komputer',
    'Pendidikan Multimedia',
    'Rekayasa Perangkat Lunak',
    'Pendidikan Guru Sekolah Dasar (PGSD)',
    'Pendidikan Guru Pendidikan Anak Usia Dini (PGPAUD)',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this)
      ..forward();
    _loadUser();
  }

  Future<void> _loadUser({bool forceRefresh = false}) async {
    // Paralel: getUserRank bisa jalan bersamaan setelah kita tahu uid user
    final user = await UserRepository.instance.getCurrentUser(forceRefresh: forceRefresh);
    final userRank = await UserRepository.instance.getUserRank(user.uid);
    if (mounted) {
      setState(() {
        _user = user.copyWith(rank: userRank);
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

    // Arahkan ke halaman edit/potong foto (ImageCropperPage) sebelum diunggah
    final Uint8List? croppedBytes = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageCropperPage(imagePath: file.path),
      ),
    );

    if (croppedBytes == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final url = await UserRepository.instance.uploadFotoProfile(croppedBytes);
      if (mounted && url != null) {
        setState(() {
          _user = _user?.copyWith(fotoUrl: url);
          _localPhotoPath = file.path;
        });
        _showSnack('Foto profil berhasil diperbarui! 📸');
      } else {
        if (mounted) _showSnack('Gagal memperbarui foto profil.');
      }
    } catch (e) {
      if (mounted) _showSnack('Gagal mengunggah foto: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.sm)),
        backgroundColor: SibersihColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: SibersihColors.primary)),
      );
    }

    final user = _user!;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(user),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
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
                _buildHelpBanner(),
                const SizedBox(height: 24),
                _buildLogoutButton(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return SliverAppBar(
      expandedHeight: 280,
      collapsedHeight: 56,
      pinned: true,
      backgroundColor: SibersihColors.primaryDeep,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Mesh gradient header background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF050280), Color(0xFF0A05A0), Color(0xFF1007BA), Color(0xFF2519D4)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            const Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Text(
                'Profil Saya',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.2,
                ),
              ),
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
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _pickAndUploadPhoto();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(color: SibersihColors.accentCyan.withValues(alpha: 0.8), width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : (user.fotoUrl != null
                                      ? Image.network(user.fotoUrl!,
                                          fit: BoxFit.cover,
                                          cacheWidth: 300)
                                      : const Center(
                                          child: Text('🙋',
                                              style: TextStyle(fontSize: 46)))),
                            ),
                          ),
                        ),
                        // Camera badge
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _pickAndUploadPhoto();
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.camera_alt_rounded,
                                    size: 16, color: SibersihColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.nama,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.nim} · ${user.jurusan}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(SibersihRadius.pill),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Text(
                        '${_levelEmoji(user.level)} Level ${user.level}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SibersihColors.primary, SibersihColors.primaryGlow],
        ),
        borderRadius: BorderRadius.circular(SibersihRadius.xl),
        boxShadow: SibersihColors.primaryGlowShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _pointStat('⭐', '${user.totalPoin}', 'Total Poin'),
          _divider(),
          _pointStat('📦', '${user.jumlahLaporan}', 'Laporan'),
          _divider(),
          _pointStat(
            '📊',
            '#${user.rank}',
            'Peringkat',
            onTap: () {
              HapticFeedback.mediumImpact();
              _showLeaderboardSheet();
            },
          ),
        ],
      ),
    );
  }

  Widget _pointStat(String emoji, String value, String label, {VoidCallback? onTap}) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10.5, fontWeight: FontWeight.w600)),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }

  void _showLeaderboardSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SibersihRadius.xl)),
      ),
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDark ? SibersihColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(SibersihRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🏆 Leaderboard 10 Besar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mahasiswa paling aktif menjaga kebersihan UPI Cibiru',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: UserRepository.instance.getLeaderboard(limit: 10),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: SibersihColors.primary),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('😔', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal memuat peringkat',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  final list = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final name = item['nama'] as String? ?? 'User';
                      final points = (item['total_poin'] as num? ?? 0).toInt();
                      final fotoUrl = item['foto_url'] as String?;
                      final level = item['level'] as String? ?? 'Pemula';
                      final uid = item['id'] as String?;
                      
                      final isCurrentUser = uid == _user?.uid;
                      final rank = index + 1;

                      String rankBadge = '';
                      if (rank == 1) {
                        rankBadge = '🥇';
                      } else if (rank == 2) {
                        rankBadge = '🥈';
                      } else if (rank == 3) {
                        rankBadge = '🥉';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? SibersihColors.primary.withValues(alpha: 0.08)
                              : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(SibersihRadius.md),
                          border: Border.all(
                            color: isCurrentUser
                                ? SibersihColors.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                alignment: Alignment.center,
                                child: rankBadge.isNotEmpty
                                    ? Text(rankBadge, style: const TextStyle(fontSize: 20))
                                    : Text(
                                        '#$rank',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: SibersihColors.primary.withValues(alpha: 0.1),
                                backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                                    ? NetworkImage(fotoUrl)
                                    : null,
                                child: fotoUrl == null || fotoUrl.isEmpty
                                    ? const Text('🙋', style: TextStyle(fontSize: 16))
                                    : null,
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: isCurrentUser ? FontWeight.w900 : FontWeight.w700,
                                    fontSize: 13.5,
                                    color: isCurrentUser ? SibersihColors.primary : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: SibersihColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Kamu',
                                    style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            level,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? SibersihColors.primary.withValues(alpha: 0.15)
                                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(SibersihRadius.sm),
                            ),
                            child: Text(
                              '⭐ $points pts',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isCurrentUser ? SibersihColors.primary : (isDark ? Colors.white70 : Colors.black87),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
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
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [SibersihColors.primaryGlow, SibersihColors.primary],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildInfoSection(UserModel user) {
    final isGoogle = AuthRepository.instance.isGoogleLoggedIn;
    return _card(children: [
      _infoTile(Icons.person_outline_rounded, 'Nama Lengkap', user.nama,
          () => _showEditDialog('Nama Lengkap', user.nama, onSave: (val) async {
                await UserRepository.instance.updateUserProfile(nama: val);
                _loadUser(forceRefresh: true);
              })),
      _divLine(),
      _infoTile(Icons.school_outlined, 'NIM', user.nim, null),
      _divLine(),
      _infoTile(Icons.business_outlined, 'Jurusan', user.jurusan,
          () => _showJurusanDropdownDialog(user.jurusan)),
      _divLine(),
      _infoTile(Icons.email_outlined, 'Email', user.email,
          () => _showEditDialog('Email', user.email, onSave: (val) async {
                await UserRepository.instance.updateUserProfile(email: val);
                _loadUser(forceRefresh: true);
              })),
      _divLine(),
      _infoTile(
        Icons.lock_outline_rounded,
        'Kata Sandi',
        '••••••••',
        isGoogle ? null : () => _showChangePassword(),
        subtitle: isGoogle ? 'anda login menggunakan Google' : null,
      ),
    ]);
  }

  Widget _buildSettingsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _card(children: [
      _switchTile(Icons.dark_mode_rounded, 'Mode Gelap', 'Tampilan gelap untuk mata',
          isDark, widget.onToggleTheme, SibersihColors.primaryGlow),
    ]);
  }

  Widget _buildAboutSection() {
    return _card(children: [
      ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(SibersihRadius.sm),
          ),
          child: const Icon(Icons.info_outline_rounded, color: Colors.teal, size: 18),
        ),
        title: const Text(
          'Tentang Sibersih',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Sibersih adalah program kerja unggulan dari BEM UPI Cibiru Kabinet Arunika 2026.',
            style: TextStyle(fontSize: 12, height: 1.3),
          ),
        ),
      ),
      _navTile(
        Icons.verified_outlined,
        'Versi Aplikasi',
        '1.0.0',
        Colors.grey,
        onTap: _showChangelogDialog,
      ),
    ]);
  }

  Widget _buildHelpBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showHelpOptions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [SibersihColors.primaryDeep.withValues(alpha: 0.3), SibersihColors.primary.withValues(alpha: 0.15)]
                : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
          ),
          borderRadius: BorderRadius.circular(SibersihRadius.lg),
          border: Border.all(color: SibersihColors.primary.withValues(alpha: isDark ? 0.25 : 0.15)),
          boxShadow: SibersihColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: SibersihColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perlu bantuan lain?',
                    style: TextStyle(
                      color: SibersihColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hubungi tim support kami sekarang',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF3F51B5),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SibersihColors.primary,
                borderRadius: BorderRadius.circular(SibersihRadius.sm),
              ),
              child: const Text(
                'Hubungi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showSnack('Gagal membuka tautan bantuan.');
    }
  }

  Future<void> _launchGmail() async {
    const email = 'sibersihbemcibiru@gmail.com';
    const subject = 'Tanya Sibersih';
    const body = 'Halo Admin Sibersih...';

    // Gmail Web Compose URL (fallback untuk Desktop/Web/emulator tanpa mail client)
    final webGmailUrl = Uri(
      scheme: 'https',
      host: 'mail.google.com',
      path: '/mail/',
      queryParameters: {
        'view': 'cm',
        'fs': '1',
        'to': email,
        'su': subject,
        'body': body,
      },
    );

    // Jika di Web, langsung buka Gmail Web secara sinkron/seketika tanpa await canLaunchUrl
    // untuk mencegah popup blocker mendeteksi pemanggilan async pasca gesture berakhir
    if (kIsWeb) {
      try {
        await launchUrl(webGmailUrl, mode: LaunchMode.platformDefault);
        return;
      } catch (_) {}
    }

    // Gmail App Scheme (iOS / Android)
    final appGmailUrl = Uri(
      scheme: 'googlegmail',
      path: '/co',
      queryParameters: {
        'to': email,
        'subject': subject,
        'body': body,
      },
    );

    // Standard mailto
    final mailtoUrl = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(appGmailUrl)) {
        await launchUrl(appGmailUrl);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(mailtoUrl)) {
        await launchUrl(mailtoUrl);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(webGmailUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack('Gagal membuka Gmail.');
    }
  }

  void _showHelpOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SibersihRadius.xl)),
      ),
      builder: (_) => Material(
        color: isDark ? SibersihColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SibersihRadius.xl)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hubungi Pusat Bantuan 🌿',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Tim support kami siap melayani pertanyaan dan masalah Anda.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              _helpOptionItem(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'WhatsApp Support',
                subtitle: 'Chat cepat tanggap 24/7',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _launchURL('https://wa.me/6287781397197?text=Halo%20Admin%20Sibersih%2C%20saya%20butuh%20bantuan...');
                },
              ),
              const SizedBox(height: 12),
              _helpOptionItem(
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'sibersihbemcibiru@gmail.com',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _launchGmail();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(SibersihRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14.5),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.heavyImpact();
          _showLogoutDialog();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.md)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20),
            SizedBox(width: 10),
            Text('Keluar dari Akun',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        boxShadow: SibersihColors.cardShadow,
      ),
      child: Material(
        color: isDark ? SibersihColors.cardDark : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SibersihRadius.lg),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : SibersihColors.primary.withValues(alpha: 0.06),
          ),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, VoidCallback? onTap, {String? subtitle}) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: SibersihColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(SibersihRadius.sm),
        ),
        child: Icon(icon, color: SibersihColors.primary, size: 18),
      ),
      title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w700)),
          ]
        ],
      ),
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
            BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(SibersihRadius.sm)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: SibersihColors.primary),
    );
  }

  Widget _navTile(IconData icon, String title, String? value, Color color, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration:
            BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(SibersihRadius.sm)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) Text(value, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : () {},
    );
  }

  void _showChangelogDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SibersihRadius.lg),
        ),
        backgroundColor: isDark ? SibersihColors.surfaceDark : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SibersihColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(SibersihRadius.md),
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      color: SibersihColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catatan Rilis',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: SibersihColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(SibersihRadius.xs),
                          ),
                          child: const Text(
                            'Versi 1.0.0 (Terbaru)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: SibersihColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              
              // Content list
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChangelogSection(
                        title: 'Sibersih Versi 1.0.0',
                        items: const [
                          'Pelaporan Sampah Kampus dengan integrasi AI Scan ',
                          'Sistem Poin & Penukaran Reward eksklusif mahasiswa.',
                          'Sistem Otentikasi Supabase & Proteksi NIM/Email terdaftar.',
                          'Semua Baru, Karena Baru Rilis',
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SibersihColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SibersihRadius.sm),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangelogSection({required String title, required List<String> items}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: SibersihColors.primary)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.grey.shade300 : Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _divLine() => const Divider(height: 0, indent: 68, endIndent: 16);

  void _showEditDialog(String field, String current,
      {required Future<void> Function(String) onSave}) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.lg)),
        title: Text('Ubah $field', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.2)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: '$field baru',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(SibersihRadius.sm)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SibersihRadius.sm),
              borderSide: const BorderSide(color: SibersihColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await onSave(ctrl.text.trim());
              if (mounted) _showSnack('$field berhasil diperbarui ✓');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SibersihColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.sm)),
            ),
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showJurusanDropdownDialog(String current) {
    String? selected = _jurusanList.contains(current) ? current : null;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.lg)),
          title: const Text(
            'Ubah Jurusan',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih jurusan kamu',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selected,
                onChanged: (val) => setDialogState(() => selected = val),
                decoration: InputDecoration(
                  hintText: 'Pilih jurusan',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.business_outlined,
                      color: SibersihColors.primary, size: 20),
                  filled: true,
                  fillColor: SibersihColors.primary.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SibersihRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SibersihRadius.sm),
                    borderSide: const BorderSide(color: SibersihColors.primary, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                isExpanded: true,
                items: _jurusanList
                    .map((j) => DropdownMenuItem(
                          value: j,
                          child: Text(j, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                dropdownColor: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: SibersihColors.primary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selected == null) {
                  _showSnack('Pilih jurusan terlebih dahulu 🎓');
                  return;
                }
                Navigator.pop(dialogContext);
                await UserRepository.instance.updateUserProfile(jurusan: selected!);
                _loadUser(forceRefresh: true);
                if (mounted) _showSnack('Jurusan berhasil diperbarui ✓');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SibersihColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SibersihRadius.sm)),
              ),
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.lg)),
        title: const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.2)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthRepository.instance
                  .changePassword(oldCtrl.text, newCtrl.text);
              if (mounted) _showSnack('Kata sandi berhasil diubah ✓');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SibersihColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.sm)),
            ),
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w800)),
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
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: SibersihColors.primary, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(SibersihRadius.sm)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SibersihRadius.sm),
          borderSide: const BorderSide(color: SibersihColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.lg)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👋', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Yakin mau keluar?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
            SizedBox(height: 6),
            Text(
              'Sampai jumpa lagi!\nJangan lupa terus menjaga kebersihan. 🌿',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () async {
              await AuthRepository.instance.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/landing');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.sm)),
            ),
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w800)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? SibersihColors.cardDark : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(SibersihRadius.xl)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Ubah Foto Profil',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sourceButton(
                    context,
                    icon: Icons.photo_camera_rounded,
                    label: 'Kamera',
                    color: SibersihColors.primary,
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
              child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(SibersihRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}
