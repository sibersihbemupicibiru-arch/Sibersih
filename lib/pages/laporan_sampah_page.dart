import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_scan_service.dart';
import '../services/supabase_service.dart';

class _PickedPhoto {
  final Uint8List bytes;
  final String name;
  AiScanResult? scanResult;

  _PickedPhoto(this.bytes, this.name);
}

class LaporanSampahPage extends StatefulWidget {
  const LaporanSampahPage({super.key});

  @override
  State<LaporanSampahPage> createState() => _LaporanSampahPageState();
}

class _LaporanSampahPageState extends State<LaporanSampahPage>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final List<_PickedPhoto> _photos = [];
  late PageController _carouselController;
  int _carouselIndex = 0;

  bool _isSubmitting = false;
  bool _picking = false;
  bool _isScanning = false;

  final _catatanController = TextEditingController();

  // Bottle type counters: plastik kecil, sedang, besar, kaca sedang, kaca besar
  final Map<String, int> _bottleCounts = {
    'plastik_kecil': 0,
    'plastik_sedang': 0,
    'plastik_besar': 0,
    'kaca_sedang': 0,
    'kaca_besar': 0,
  };

  int get _totalBottles => _bottleCounts.values.fold(0, (a, b) => a + b);

  late AnimationController _headerController;
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    // Preload model ONNX di background — supaya scan pertama tidak ada delay
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
    )..repeat(reverse: true);
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _catatanController.dispose();
    _headerController.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  // ─── Photo picking ───────────────────────────────────────

  Future<void> _pickFromCamera() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;
      await _addPhotoAndScan(bytes, file.name);
    } on PlatformException catch (e) {
      if (mounted)
        _showSnack('Kamera tidak bisa dibuka: ${e.message ?? "coba Galeri"}');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final files =
          await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1920);
      for (final f in files) {
        final bytes = await f.readAsBytes();
        if (bytes.isNotEmpty) await _addPhotoAndScan(bytes, f.name);
      }
      if (files.isEmpty) {
        final one = await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 85);
        if (one != null) {
          final bytes = await one.readAsBytes();
          if (bytes.isNotEmpty) await _addPhotoAndScan(bytes, one.name);
        }
      }
    } catch (_) {
      if (mounted) _showSnack('Gagal memilih gambar.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _addPhotoAndScan(Uint8List bytes, String name) async {
    // 1. Add photo optimistically
    setState(() {
      _photos.add(_PickedPhoto(bytes, name));
      _carouselIndex = _photos.length - 1;
      _isScanning = true;
    });
    _jumpCarouselTo(_carouselIndex);
    _scanLineController.repeat();

    // 2. Run AI scan
    final result = await AiScanService.analyzeImage(bytes, sourceName: name);

    // 3. Update result on the photo
    if (mounted) {
      setState(() {
        _photos.last.scanResult = result;
        _isScanning = false;
      });
      _scanLineController.stop();

      // Show result overlay briefly
      _showScanResultSnack(result);
    }
  }

  void _showScanResultSnack(AiScanResult result) {
    final color = result.isAccepted
        ? Colors.green
        : result.type == BottleType.glassBottle
            ? Colors.orange
            : Colors.red;

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
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(result.message,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${result.confidencePercent}%',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _jumpCarouselTo(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_carouselController.hasClients) return;
      _carouselController.animateToPage(
        i,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _removePhotoAt(int index) {
    setState(() {
      _photos.removeAt(index);
      _carouselIndex =
          _photos.isEmpty ? 0 : (_carouselIndex).clamp(0, _photos.length - 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _photos.isNotEmpty && _carouselController.hasClients) {
        _carouselController.jumpToPage(_carouselIndex);
      }
    });
  }

  // ─── Submit ──────────────────────────────────────────────

  Future<void> _submitLaporan() async {
    if (_photos.isEmpty) {
      _showSnack('Tambah minimal satu foto botol plastik 📸');
      return;
    }

    // Check if any photo failed AI scan
    final rejected = _photos
        .where((p) => p.scanResult != null && !p.scanResult!.isAccepted)
        .toList();
    if (rejected.isNotEmpty) {
      _showRejectedDialog(rejected.first.scanResult!);
      return;
    }

    if (_totalBottles == 0) {
      _showSnack('Masukkan jumlah botol yang dilaporkan 🍶');
      return;
    }

    setState(() => _isSubmitting = true);

    const lokasiTetap =
        'Sebelum Lorong Sekre UKM & ORMAWA (deket kantin Ma Ai)';

    // Build summary string for berat field
    final bottleSummary =
        _bottleCounts.entries.where((e) => e.value > 0).map((e) {
      final label = {
        'plastik_kecil': 'Plastik Kecil',
        'plastik_sedang': 'Plastik Sedang',
        'plastik_besar': 'Plastik Besar',
        'kaca_sedang': 'Kaca Sedang',
        'kaca_besar': 'Kaca Besar',
      }[e.key]!;
      return '${e.value}x $label';
    }).join(', ');

    final ok = await SupabaseService.instance.submitLaporan(
      fotoBytes: _photos.map((p) => p.bytes).toList(),
      berat: _totalBottles.toDouble(),
      lokasi: lokasiTetap,
      catatan: bottleSummary +
          (_catatanController.text.isNotEmpty
              ? ' | ${_catatanController.text}'
              : ''),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      _showResultDialog(ok, (_totalBottles * 10).clamp(50, 500));
    }
  }

  void _showRejectedDialog(AiScanResult result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('⚠️', style: TextStyle(fontSize: 40))),
            ),
            const SizedBox(height: 16),
            Text(
              result.type == BottleType.glassBottle
                  ? 'Terdeteksi Botol Kaca'
                  : 'Objek Tidak Valid',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              result.type == BottleType.glassBottle
                  ? 'Sibersih hanya menerima laporan botol PLASTIK. Hapus foto ini dan ganti dengan botol plastik.'
                  : 'Foto yang diupload bukan botol. Pastikan foto menunjukkan botol plastik dengan jelas.',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1007BA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Mengerti'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1007BA),
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
                _carouselIndex = 0;
                _bottleCounts.updateAll((key, value) => 0);
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoBanner(isDark),
                const SizedBox(height: 20),
                _buildPlasticBadge(),
                const SizedBox(height: 24),
                _sectionTitle(
                    'Foto Botol Plastik', Icons.photo_library_rounded),
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
                const SizedBox(height: 20),
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
          style: TextStyle(fontWeight: FontWeight.w800)),
      centerTitle: true,
      backgroundColor: const Color(0xFF1007BA),
      foregroundColor: Colors.white,
      floating: true,
      snap: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A05A0), Color(0xFF2519D4)],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (_, __) => Opacity(
        opacity: _headerController.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _headerController.value) * 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1007BA).withOpacity(0.1),
                  const Color(0xFF4C3FE8).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: const Color(0xFF1007BA).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + _pulseController.value * 0.08,
                    child: const Text('🤖', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verifikasi AI Aktif',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13)),
                      SizedBox(height: 2),
                      Text(
                        'Setiap foto akan dianalisis AI untuk memastikan itu botol plastik.',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlasticBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3).withOpacity(0.12),
            const Color(0xFF2196F3).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Text('🥤', style: TextStyle(fontSize: 38)),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plastik Saja',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('100 poin / laporan · verifikasi AI otomatis',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              children: [
                Icon(Icons.verified_rounded, color: Colors.green, size: 18),
                SizedBox(height: 2),
                Text('AI Valid',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
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
            label: const Text('Kamera'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1007BA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _picking ? null : _pickFromGallery,
            icon: const Icon(Icons.folder_open_rounded, size: 20),
            label: const Text(kIsWeb ? 'File' : 'Galeri'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1007BA),
              side: const BorderSide(color: Color(0xFF1007BA), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
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
        color: const Color(0xFF1007BA).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1007BA).withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF1007BA)),
            ),
          ),
          SizedBox(width: 12),
          Text('AI sedang menganalisis foto…',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
          color: isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text('Belum ada foto',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('Kamera atau Galeri di atas',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
                  elevation: 6,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(p.bytes,
                            fit: BoxFit.cover, gaplessPlayback: true),
                        // Scan overlay if currently scanning this photo
                        if (_isScanning && index == _photos.length - 1)
                          _ScanOverlay(controller: _scanLineController),
                        // Result badge
                        if (p.scanResult != null)
                          _ScanResultBadge(result: p.scanResult!),
                        // Counter
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${index + 1}/${_photos.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        // Remove button
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
                                shape: BoxShape.circle,
                              ),
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
                    ? const Color(0xFF1007BA)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
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
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF1007BA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: const Color(0xFF1007BA), size: 17),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildDetailSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBottleTypeSelector(isDark),
        const SizedBox(height: 14),
        _buildLokasiDropdown(isDark),
        const SizedBox(height: 14),
        _buildInputField(
          label: 'Catatan (opsional)',
          hint: 'Ada yang ingin ditambahkan?',
          icon: Icons.notes_rounded,
          controller: _catatanController,
          maxLines: 3,
        ),
        if (_totalBottles > 0) ...[
          const SizedBox(height: 14),
          _buildEstimasi(),
        ],
      ],
    );
  }

  Widget _buildBottleTypeSelector(bool isDark) {
    const items = [
      ('plastik_kecil', '🥤', 'Plastik Kecil', '< 600 ml'),
      ('plastik_sedang', '🧴', 'Plastik Sedang', '600 ml – 1.5 L'),
      ('plastik_besar', '🫙', 'Plastik Besar', '> 1.5 L'),
      ('kaca_sedang', '🍶', 'Kaca Sedang', '< 500 ml'),
      ('kaca_besar', '🍾', 'Kaca Besar', '≥ 500 ml'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Jenis & Jumlah Botol',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 10),
        ...items.map((item) {
          final key = item.$1;
          final emoji = item.$2;
          final name = item.$3;
          final sub = item.$4;
          final count = _bottleCounts[key]!;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: count > 0
                  ? const Color(0xFF1007BA).withOpacity(0.07)
                  : const Color(0xFF1007BA).withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: count > 0
                    ? const Color(0xFF1007BA).withOpacity(0.4)
                    : const Color(0xFF1007BA).withOpacity(0.12),
                width: count > 0 ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(sub,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                // Stepper
                Row(
                  children: [
                    _stepperBtn(
                      icon: Icons.remove_rounded,
                      onTap: count > 0
                          ? () => setState(() => _bottleCounts[key] = count - 1)
                          : null,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        '$count',
                        key: ValueKey('$key$count'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: count > 0
                              ? const Color(0xFF1007BA)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    _stepperBtn(
                      icon: Icons.add_rounded,
                      onTap: () =>
                          setState(() => _bottleCounts[key] = count + 1),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        if (_totalBottles > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Total: $_totalBottles botol',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stepperBtn({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFF1007BA).withOpacity(0.12)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color:
                onTap != null ? const Color(0xFF1007BA) : Colors.grey.shade400),
      ),
    );
  }

  Widget _buildLokasiDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lokasi Pembuangan',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1007BA).withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF1007BA).withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Color(0xFF1007BA), size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sebelum Lorong Sekre UKM & ORMAWA\n(deket kantin Ma Ai)',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Fixed',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF1007BA), size: 20),
            filled: true,
            fillColor: const Color(0xFF1007BA).withOpacity(0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1007BA), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimasi() {
    final pts = (_totalBottles * 10).clamp(10, 500);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estimasi poin',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('~$pts poin',
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('Setelah verifikasi',
                style:
                    TextStyle(color: Colors.green, fontSize: 10, height: 1.4),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final hasRejected =
        _photos.any((p) => p.scanResult != null && !p.scanResult!.isAccepted);

    return Column(
      children: [
        if (hasRejected)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ada foto yang tidak lolos verifikasi AI. Hapus dan ganti dengan foto botol plastik.',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: (_isSubmitting || hasRejected) ? null : _submitLaporan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1007BA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: const Color(0xFF1007BA).withOpacity(0.4),
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
                      Text('Mengirim…', style: TextStyle(fontSize: 16)),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Kirim Laporan',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Verifikasi ± 1×24 jam · AI pre-screening aktif',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
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
          // Corner brackets
          ..._corners(),
          // Scan line
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final t = controller.value;
              final y = t * 200.0;
              return Positioned(
                top: y,
                left: 20,
                right: 20,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF4C3FE8).withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
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
                        color: Colors.white, fontWeight: FontWeight.w700)),
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
    const color = Color(0xFF4C3FE8);
    const r = 4.0;

    return [
      // TL
      const Positioned(
        top: 16,
        left: 16,
        child: _Corner(
            size: size, thick: thick, color: color, top: true, left: true),
      ),
      // TR
      const Positioned(
        top: 16,
        right: 16,
        child: _Corner(
            size: size, thick: thick, color: color, top: true, left: false),
      ),
      // BL
      const Positioned(
        bottom: 16,
        left: 16,
        child: _Corner(
            size: size, thick: thick, color: color, top: false, left: true),
      ),
      // BR
      const Positioned(
        bottom: 16,
        right: 16,
        child: _Corner(
            size: size, thick: thick, color: color, top: false, left: false),
      ),
    ];
  }
}

class _Corner extends StatelessWidget {
  final double size, thick;
  final Color color;
  final bool top, left;

  const _Corner({
    required this.size,
    required this.thick,
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter:
            _CornerPainter(color: color, thick: thick, top: top, left: left),
      ),
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
    final dx = left ? size.width * 0.6 : -size.width * 0.6;
    final dy = top ? size.height * 0.6 : -size.height * 0.6;
    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
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
    final color = result.isAccepted
        ? Colors.green
        : result.type == BottleType.glassBottle
            ? Colors.orange
            : Colors.red;

    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(result.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(result.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
            Text('${result.confidencePercent}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

  const _ResultDialog({
    required this.success,
    required this.points,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                    ? Colors.green.withOpacity(0.12)
                    : Colors.red.withOpacity(0.12),
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
                  color: success ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              success
                  ? 'Botol plastikmu berhasil dilaporkan.\nTim kami akan verifikasi dalam 1×24 jam.'
                  : 'Terjadi kesalahan. Coba lagi ya!',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (success) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1007BA).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimasi poin',
                            style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text('+$points poin',
                            style: const TextStyle(
                                color: Color(0xFF1007BA),
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
                      success ? const Color(0xFF1007BA) : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  success ? 'Sip, terima kasih! 🌿' : 'Coba Lagi',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
