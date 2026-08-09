import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/ai_scan_service.dart';
import '../../../repositories/laporan_repository.dart';
import '../../../core/result.dart';
import '../../../core/app_tokens.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class _PickedPhoto {
  final Uint8List bytes;
  final String name;
  AiScanResult? scanResult;

  _PickedPhoto(this.bytes, this.name);
}

// ─── Poin table (DISPLAY ONLY) ───────────────────────────────
const Map<String, Map<String, int>> _poinTable = {
  'plastik': {'kecil': 50, 'sedang': 100, 'besar': 150},
  'kaca': {'kecil': 150, 'besar': 200},
};

int _hitungPoin(String? kategori, String? ukuran) {
  if (kategori == null || ukuran == null) return 0;
  return _poinTable[kategori]?[ukuran] ?? 0;
}

class LaporanSampahPage extends StatefulWidget {
  const LaporanSampahPage({super.key});

  @override
  State<LaporanSampahPage> createState() => _LaporanSampahPageState();
}

class _LaporanSampahPageState extends State<LaporanSampahPage>
    with TickerProviderStateMixin {
  DateTime? _lastSubmitTime;
  final ImagePicker _picker = ImagePicker();
  final List<_PickedPhoto> _photos = [];

  final List<String> _fotoHashes = [];
  List<String>? _dbHashes;

  late PageController _carouselController;
  int _carouselIndex = 0;

  bool _isSubmitting = false;
  bool _picking = false;
  bool _isScanning = false;

  String? _kategoriBottle;
  String? _ukuran;

  final _catatanController = TextEditingController();

  late AnimationController _headerController;
  late AnimationController _scanLineController;
  late AnimationController _pulseController;

  static const String _lokasiDefault = 'Samping Ruang Sekre Bersama';

  // ─── Image helpers ───────────────────────────────────────

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 70,
      minWidth: 1280,
      minHeight: 1280,
    );
    return Uint8List.fromList(result);
  }

  bool _isImageTooLarge(Uint8List bytes) {
    const maxSize = 5 * 1024 * 1024; // 5 MB
    return bytes.length > maxSize;
  }

  bool _isValidImage(Uint8List bytes) {
    if (bytes.length < 4) return false;
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    AiScanService.preload();
    _carouselController = PageController(viewportFraction: 0.88);
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _headerController.addStatusListener(_onHeaderDone);
  }

  void _onHeaderDone(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _headerController.removeStatusListener(_onHeaderDone);
      if (!mounted) return;
      _pulseController.repeat(reverse: true);
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) _pulseController.stop();
      });
    }
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _catatanController.dispose();
    _headerController.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Photo picking ───────────────────────────────────────

  Future<void> _pickFromCamera() async {
    if (_picking) return;
    HapticFeedback.lightImpact();
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      await _validateAndProcess(bytes, file.name);
    } on PlatformException catch (e) {
      if (mounted) {
        _showSnack('Kamera tidak bisa dibuka: ${e.message ?? "coba Galeri"}');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_picking) return;
    HapticFeedback.lightImpact();
    setState(() => _picking = true);
    try {
      final files =
          await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1280);
      for (final f in files) {
        if (_photos.length >= 5) {
          _showSnack('Maksimal 5 foto');
          break;
        }
        final bytes = await f.readAsBytes();
        await _validateAndProcess(bytes, f.name);
      }
      if (files.isEmpty) {
        final one = await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 70);
        if (one != null) {
          final bytes = await one.readAsBytes();
          await _validateAndProcess(bytes, one.name);
        }
      }
    } catch (_) {
      if (mounted) _showSnack('Gagal memilih gambar.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _validateAndProcess(Uint8List bytes, String name) async {
    if (!mounted) return;
    if (bytes.isEmpty) return;

    if (_photos.length >= 5) {
      _showSnack('Maksimal 5 foto');
      return;
    }

    if (_isImageTooLarge(bytes)) {
      _showSnack('Ukuran gambar terlalu besar 😭');
      return;
    }

    if (!_isValidImage(bytes)) {
      _showSnack('Format gambar tidak valid');
      return;
    }

    final compressed = await _compressImage(bytes);
    await _addPhotoWithWorkflow(compressed, name);
  }

  Future<void> _addPhotoWithWorkflow(Uint8List bytes, String name) async {
    final hash = LaporanRepository.instance.hashImage(bytes);
    _dbHashes ??= await LaporanRepository.instance.getUserFotoHashes();

    if (hash.isNotEmpty &&
        LaporanRepository.instance.isDuplicateHash(hash, _dbHashes!)) {
      if (mounted) _showSnack('Foto ini sepertinya sudah pernah dikirim 🔄');
      return;
    }

    setState(() {
      _photos.add(_PickedPhoto(bytes, name));
      _fotoHashes.add(hash);
      _carouselIndex = _photos.length - 1;
      _isScanning = true;
    });
    _jumpCarouselTo(_carouselIndex);
    _scanLineController.repeat();

    final result = await AiScanService.analyzeImage(bytes, sourceName: name);

    if (mounted) {
      setState(() {
        _photos.last.scanResult = result;
        _isScanning = false;

        if (_photos.length == 1 || _kategoriBottle == null) {
          if (result.type == BottleType.plasticBottle) {
            _kategoriBottle = 'plastik';
          } else if (result.type == BottleType.glassBottle) {
            _kategoriBottle = 'kaca';
            if (_ukuran == 'sedang') _ukuran = null;
          }
        }
      });
      _scanLineController.stop();
      _showScanResultSnack(result);
    }
  }

  void _showScanResultSnack(AiScanResult result) {
    final isBottle = result.type == BottleType.plasticBottle ||
        result.type == BottleType.glassBottle;
    final color = result.type == BottleType.plasticBottle
        ? SibersihColors.success
        : result.type == BottleType.glassBottle
            ? SibersihColors.accentCyan
            : SibersihColors.error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(result.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(result.label,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(
                    isBottle
                        ? result.message
                        : 'Bukan botol, hapus dan ganti foto.',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(SibersihRadius.xs),
              ),
              child: Text('${result.confidencePercent}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.md)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _jumpCarouselTo(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_carouselController.hasClients) return;
      _carouselController.animateToPage(i,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic);
    });
  }

  void _removePhotoAt(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _photos.removeAt(index);
      _fotoHashes.removeAt(index);
      _carouselIndex =
          _photos.isEmpty ? 0 : (_carouselIndex).clamp(0, _photos.length - 1);
      if (_photos.isEmpty) {
        _kategoriBottle = null;
        _ukuran = null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _photos.isNotEmpty && _carouselController.hasClients) {
        _carouselController.jumpToPage(_carouselIndex);
      }
    });
  }

  // ─── Submit ──────────────────────────────────────────────

  Future<void> _submitLaporan() async {
    // ── Client-side fast check (cegah double-tap) ──────────
    final now = DateTime.now();
    if (_lastSubmitTime != null &&
        now.difference(_lastSubmitTime!).inSeconds < 10) {
      _showSnack('Tunggu beberapa detik sebelum kirim lagi 😭');
      return;
    }

    if (_photos.isEmpty) {
      _showSnack('Tambah minimal satu foto botol 📸');
      return;
    }

    final rejected = _photos
        .where((p) =>
            p.scanResult != null &&
            p.scanResult!.type != BottleType.plasticBottle &&
            p.scanResult!.type != BottleType.glassBottle)
        .toList();
    if (rejected.isNotEmpty) {
      HapticFeedback.heavyImpact();
      _showRejectedDialog(rejected.first.scanResult!);
      return;
    }

    if (_kategoriBottle == null) {
      _showSnack('Pilih kategori botol terlebih dahulu 🥤');
      return;
    }
    if (_ukuran == null) {
      _showSnack('Pilih ukuran botol terlebih dahulu 📏');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ── Server-side rate limit: batas harian ───────────────
      final withinDailyLimit =
          await LaporanRepository.instance.checkDailyLimit(maxPerDay: 10);
      if (!withinDailyLimit) {
        if (mounted) {
          _showSnack(
              '⛔ Batas 10 laporan per hari tercapai. Coba lagi besok!');
        }
        return;
      }

      // ── Server-side rate limit: cooldown 5 menit ───────────
      final cooldownSecs = await LaporanRepository.instance
          .checkSubmitCooldown(cooldownMinutes: 5);
      if (cooldownSecs != null) {
        final mins = (cooldownSecs / 60).ceil();
        if (mounted) {
          _showSnack(
              '⏳ Tunggu $mins menit lagi sebelum bisa kirim laporan.');
        }
        return;
      }

      // ── Submit ─────────────────────────────────────────────
      final submitResult = await LaporanRepository.instance.submitLaporan(
        fotoBytes: _photos.map((p) => p.bytes).toList(),
        fotoHashes: List<String>.from(_fotoHashes),
        kategori: _kategoriBottle!,
        ukuran: _ukuran!,
        catatan: _catatanController.text,
      );

      if (!mounted) return;

      if (submitResult.status == SubmitStatus.duplicate) {
        _showSnack('Foto ini sudah pernah dikirim sebelumnya 🔄');
        return;
      }

      if (submitResult.status == SubmitStatus.success) {
        _lastSubmitTime = DateTime.now();
      }

      _showResultDialog(
        submitResult.status == SubmitStatus.success,
        submitResult.poin,
      );
    } catch (e) {
      debugPrint('Submit error: $e');
      if (mounted) _showSnack('Gagal mengirim laporan 😭');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showRejectedDialog(AiScanResult result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.lg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: SibersihColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('⚠️', style: TextStyle(fontSize: 40))),
            ),
            const SizedBox(height: 16),
            const Text('Objek Tidak Valid',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
            const SizedBox(height: 8),
            Text(result.message,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Foto tidak menunjukkan botol. Pastikan foto adalah botol plastik atau botol kaca.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: SibersihColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SibersihRadius.sm)),
            ),
            child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.sm)),
        backgroundColor: SibersihColors.primary,
      ),
    );
  }

  void _showResultDialog(bool success, int points) {
    showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (_, anim, __, ___) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: _ResultDialog(
          success: success,
          points: points,
          onDismiss: () {
            Navigator.pop(context);
            if (success) {
              setState(() {
                _photos.clear();
                _fotoHashes.clear();
                _dbHashes = null;
                _carouselIndex = 0;
                _kategoriBottle = null;
                _ukuran = null;
                _catatanController.clear();
              });
            }
          },
        ),
      ),
      transitionDuration: const Duration(milliseconds: 500),
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
    );
  }

  // ─── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoBanner(isDark),
                const SizedBox(height: 20),
                _buildKategoriSection(isDark),
                const SizedBox(height: 24),
                _sectionTitle('Foto Botol', Icons.photo_library_rounded),
                const SizedBox(height: 12),
                _buildPickButtons(),
                const SizedBox(height: 16),
                _buildPhotoCarousel(isDark),
                if (_isScanning) ...[
                  const SizedBox(height: 12),
                  _buildScanningIndicator(),
                ],
                const SizedBox(height: 24),
                _sectionTitle('Detail Laporan', Icons.info_outline_rounded),
                const SizedBox(height: 12),
                _buildDetailSection(isDark),
                const SizedBox(height: 28),
                _buildSubmitButton(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      title: const Text('Laporan Sampah',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.2)),
      centerTitle: true,
      backgroundColor: SibersihColors.primaryDeep,
      foregroundColor: Colors.white,
      floating: true,
      snap: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF050280), Color(0xFF0A05A0), Color(0xFF1007BA)]),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return AnimatedBuilder(
      animation: _headerController,
      child: const Padding(
        padding: EdgeInsets.only(left: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verifikasi AI Aktif',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            SizedBox(height: 2),
            Text(
              'AI mendeteksi jenis botol dari foto. Kamu bisa ubah hasilnya & pilih ukuran sendiri.',
              style:
                  TextStyle(color: Colors.grey, fontSize: 12, height: 1.45, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      builder: (_, staticChild) => Opacity(
        opacity: _headerController.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _headerController.value) * 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                SibersihColors.primary.withValues(alpha: 0.12),
                SibersihColors.primary.withValues(alpha: 0.06),
              ]),
              borderRadius: BorderRadius.circular(SibersihRadius.lg),
              border: Border.all(
                  color: SibersihColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    child: const Text('🤖', style: TextStyle(fontSize: 28)),
                    builder: (_, child) => Transform.scale(
                      scale: 1.0 + _pulseController.value * 0.08,
                      child: child,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: staticChild!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Kategori + Ukuran Section ───────────────────────────

  Widget _buildKategoriSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? SibersihColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(SibersihRadius.lg),
        border: Border.all(color: SibersihColors.primary.withValues(alpha: isDark ? 0.08 : 0.05)),
        boxShadow: SibersihColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('Kategori Botol', Icons.category_rounded),
              const Spacer(),
              if (_kategoriBottle != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SibersihColors.accentCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(SibersihRadius.xs),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: SibersihColors.accentCyan, size: 12),
                      SizedBox(width: 4),
                      Text('Dari AI',
                          style: TextStyle(
                              color: SibersihColors.accentCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _kategoriChip('plastik', '🥤', 'Botol Plastik')),
              const SizedBox(width: 10),
              Expanded(child: _kategoriChip('kaca', '🍶', 'Botol Kaca')),
            ],
          ),
          const SizedBox(height: 20),

          _sectionTitle('Ukuran Botol', Icons.straighten_rounded),
          const SizedBox(height: 10),
          _buildUkuranSelector(),
          const SizedBox(height: 16),

          _buildPoinTable(),
        ],
      ),
    );
  }

  Widget _kategoriChip(String value, String emoji, String label) {
    final selected = _kategoriBottle == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _kategoriBottle = value;
          if (value == 'kaca' && _ukuran == 'sedang') _ukuran = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? SibersihColors.primary
              : SibersihColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(SibersihRadius.md),
          border: Border.all(
            color: selected
                ? SibersihColors.primary
                : SibersihColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: selected ? Colors.white : null)),
          ],
        ),
      ),
    );
  }

  Widget _buildUkuranSelector() {
    final ukuranList = _kategoriBottle == 'kaca'
        ? ['kecil', 'besar']
        : ['kecil', 'sedang', 'besar'];
    final labelMap = {
      'kecil': '🔹 Kecil',
      'sedang': '🔶 Sedang',
      'besar': '🔴 Besar'
    };

    if (_kategoriBottle == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(SibersihRadius.md),
        ),
        child: const Center(
          child: Text('Pilih kategori botol dulu',
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Row(
      children: ukuranList.map((u) {
        final selected = _ukuran == u;
        final poin = _hitungPoin(_kategoriBottle, u);
        final isLast = u == ukuranList.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _ukuran = u);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? SibersihColors.success.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(SibersihRadius.md),
                  border: Border.all(
                    color: selected
                        ? SibersihColors.success
                        : Colors.grey.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(labelMap[u] ?? u,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: selected ? SibersihColors.success : null)),
                    const SizedBox(height: 4),
                    Text('+$poin pts',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: selected
                                ? SibersihColors.success
                                : Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPoinTable() {
    if (_kategoriBottle == null) return const SizedBox.shrink();

    final isPlastik = _kategoriBottle == 'plastik';
    final entries = _poinTable[_kategoriBottle]!.entries.toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isPlastik ? SibersihColors.primary : Colors.brown).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(SibersihRadius.md),
        border: Border.all(
            color:
                (isPlastik ? SibersihColors.primary : Colors.brown).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPlastik
                ? '🥤 Tabel Poin Botol Plastik'
                : '🍶 Tabel Poin Botol Kaca',
            style:
                const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          ...entries.map((e) {
            final isSelected = _ukuran == e.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                      '${e.key[0].toUpperCase()}${e.key.substring(1)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected ? SibersihColors.success : Colors.grey.shade500)),
                  const Spacer(),
                  Text('+${e.value} poin',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? SibersihColors.success : Colors.grey.shade500)),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle_rounded,
                        color: SibersihColors.success, size: 14),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPickButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _picking ? null : _pickFromCamera,
            icon: _picking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.photo_camera_rounded, size: 20),
            label: const Text('Kamera', style: TextStyle(fontWeight: FontWeight.w800)),
            style: FilledButton.styleFrom(
              backgroundColor: SibersihColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SibersihRadius.md)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _picking ? null : _pickFromGallery,
            icon: const Icon(Icons.folder_open_rounded, size: 20),
            label: const Text(kIsWeb ? 'File' : 'Galeri', style: TextStyle(fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              foregroundColor: SibersihColors.primary,
              side: const BorderSide(color: SibersihColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SibersihRadius.md)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: SibersihColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(SibersihRadius.md),
        border:
            Border.all(color: SibersihColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation(SibersihColors.primary)),
          ),
          SizedBox(width: 12),
          Text('AI sedang menganalisis foto…',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(bool isDark) {
    if (_photos.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? SibersihColors.cardDark : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(SibersihRadius.lg),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text('Belum ada foto',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('Kamera atau Galeri di atas',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _photos.length,
            onPageChanged: (i) => setState(() => _carouselIndex = i),
            itemBuilder: (ctx, index) {
              final p = _photos[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(SibersihRadius.lg),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(SibersihRadius.lg),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(p.bytes,
                            fit: BoxFit.cover, gaplessPlayback: true),
                        if (_isScanning && index == _photos.length - 1)
                          _ScanOverlay(controller: _scanLineController),
                        if (p.scanResult != null)
                          _ScanResultBadge(result: p.scanResult!),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(SibersihRadius.pill)),
                            child: Text('${index + 1}/${_photos.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () => _removePhotoAt(index),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _photos.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _carouselIndex == i ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _carouselIndex == i
                    ? SibersihColors.primary
                    : (isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: SibersihColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9)),
          child:
              Icon(icon, color: SibersihColors.primary, size: 17),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildDetailSection(bool isDark) {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lokasi Pembuangan',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(SibersihRadius.md),
                border:
                    Border.all(color: Colors.grey.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      color: Colors.grey.shade500, size: 20),
                  const SizedBox(width: 12),
                  Text(_lokasiDefault,
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(Icons.lock_outline_rounded,
                      color: Colors.grey.shade400, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_kategoriBottle != null && _ukuran != null) ...[
          _buildEstimasi(),
          const SizedBox(height: 14),
        ],

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catatan (opsional)',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _catatanController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ada yang ingin ditambahkan?',
                hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                prefixIcon: const Icon(Icons.notes_rounded,
                    color: SibersihColors.primary, size: 20),
                filled: true,
                fillColor:
                    SibersihColors.primary.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SibersihRadius.md),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SibersihRadius.md),
                  borderSide: const BorderSide(
                      color: SibersihColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstimasi() {
    final poin = _hitungPoin(_kategoriBottle, _ukuran);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SibersihColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SibersihRadius.md),
        border: Border.all(color: SibersihColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estimasi poin',
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('+$poin poin',
                  style: const TextStyle(
                      color: SibersihColors.success,
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
            ],
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: SibersihColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('Setelah verifikasi',
                style: TextStyle(
                    color: SibersihColors.success, fontSize: 10, height: 1.4, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final hasInvalid = _photos.any((p) =>
        p.scanResult != null &&
        p.scanResult!.type != BottleType.plasticBottle &&
        p.scanResult!.type != BottleType.glassBottle);

    final canSubmit = !_isSubmitting &&
        !hasInvalid &&
        _kategoriBottle != null &&
        _ukuran != null &&
        _photos.isNotEmpty;

    return Column(
      children: [
        if (hasInvalid)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SibersihRadius.md),
              border:
                  Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Ada foto yang bukan botol. Hapus dan ganti.',
                      style:
                          TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: canSubmit ? _submitLaporan : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: SibersihColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SibersihRadius.md)),
              elevation: 8,
              shadowColor:
                  SibersihColors.primary.withValues(alpha: 0.4),
            ),
            child: _isSubmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5)),
                      SizedBox(width: 12),
                      Text('Mengirim…',
                          style: TextStyle(fontSize: 16)),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Kirim Laporan',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Verifikasi ± 1×24 jam · AI pre-screening aktif',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Scan overlay widget ─────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  final AnimationController controller;
  const _ScanOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      child: Stack(
        children: [
          ..._corners(),
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final y = controller.value * 200.0;
              return Positioned(
                top: y,
                left: 20,
                right: 20,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      SibersihColors.primaryGlow.withValues(alpha: 0.8),
                      Colors.transparent,
                    ]),
                  ),
                ),
              );
            },
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 80),
                Text('🤖', style: TextStyle(fontSize: 36)),
                SizedBox(height: 8),
                Text('Menganalisis…',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const size = 24.0;
    const thick = 3.0;
    const color = SibersihColors.primaryGlow;
    return [
      const Positioned(
          top: 16,
          left: 16,
          child: _Corner(
              size: size,
              thick: thick,
              color: color,
              top: true,
              left: true)),
      const Positioned(
          top: 16,
          right: 16,
          child: _Corner(
              size: size,
              thick: thick,
              color: color,
              top: true,
              left: false)),
      const Positioned(
          bottom: 16,
          left: 16,
          child: _Corner(
              size: size,
              thick: thick,
              color: color,
              top: false,
              left: true)),
      const Positioned(
          bottom: 16,
          right: 16,
          child: _Corner(
              size: size,
              thick: thick,
              color: color,
              top: false,
              left: false)),
    ];
  }
}

class _Corner extends StatelessWidget {
  final double size, thick;
  final Color color;
  final bool top, left;
  const _Corner(
      {required this.size,
      required this.thick,
      required this.color,
      required this.top,
      required this.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
          painter: _CornerPainter(
              color: color, thick: thick, top: top, left: left)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool top, left;
  _CornerPainter(
      {required this.color,
      required this.thick,
      required this.top,
      required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    canvas.drawLine(
        Offset(x, y),
        Offset(x + (left ? 1 : -1) * size.width * 0.6, y),
        paint);
    canvas.drawLine(
        Offset(x, y),
        Offset(x, y + (top ? 1 : -1) * size.height * 0.6),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Scan result badge ───────────────────────────────────────

class _ScanResultBadge extends StatelessWidget {
  final AiScanResult result;
  const _ScanResultBadge({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.type == BottleType.plasticBottle
        ? SibersihColors.success
        : result.type == BottleType.glassBottle
            ? SibersihColors.accentCyan
            : SibersihColors.error;

    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(SibersihRadius.sm)),
        child: Row(
          children: [
            Text(result.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(result.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
            ),
            Text('${result.confidencePercent}%',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ─── Result dialog ───────────────────────────────────────────

class _ResultDialog extends StatelessWidget {
  final bool success;
  final int points;
  final VoidCallback onDismiss;

  const _ResultDialog(
      {required this.success,
      required this.points,
      required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(SibersihRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: success
                    ? SibersihColors.success.withValues(alpha: 0.12)
                    : SibersihColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                  child: Text(success ? '🎉' : '😔',
                       style: const TextStyle(fontSize: 46))),
            ),
            const SizedBox(height: 20),
            Text(
              success ? 'Laporan Terkirim!' : 'Laporan Gagal',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: success ? SibersihColors.success : SibersihColors.error,
                  letterSpacing: -0.2),
            ),
            const SizedBox(height: 8),
            Text(
              success
                  ? 'Botolmu berhasil dilaporkan.\nTim kami akan verifikasi dalam 1×24 jam.'
                  : 'Terjadi kesalahan. Coba lagi ya!',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (success) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    color: SibersihColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(SibersihRadius.md)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐',
                        style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimasi poin',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('+$points poin',
                            style: const TextStyle(
                                color: SibersihColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 22)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      success ? SibersihColors.primary : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SibersihRadius.md)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                    success ? 'Sip, terima kasih! 🌿' : 'Coba Lagi',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}