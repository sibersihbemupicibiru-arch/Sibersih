import 'dart:async';
import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../core/app_tokens.dart';

class ImageCropperPage extends StatefulWidget {
  final String imagePath;

  const ImageCropperPage({super.key, required this.imagePath});

  @override
  State<ImageCropperPage> createState() => _ImageCropperPageState();
}

class _ImageCropperPageState extends State<ImageCropperPage> {
  final GlobalKey _boundaryKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  
  bool _isLoading = true;
  double? _imageWidth;
  double? _imageHeight;
  double? _imageAspectRatio;
  int _rotationTurns = 0; // 0, 1, 2, 3 (each is 90 degrees)
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImageDetails();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadImageDetails() async {
    try {
      final Uint8List bytes;
      if (kIsWeb) {
        final response = await http.get(Uri.parse(widget.imagePath));
        bytes = response.bodyBytes;
      } else {
        bytes = await io.File(widget.imagePath).readAsBytes();
      }
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });
      final image = await completer.future;
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _imageWidth = image.width.toDouble();
          _imageHeight = image.height.toDouble();
          _imageAspectRatio = _imageWidth! / _imageHeight!;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading image details: $e");
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Gagal memuat gambar")),
            );
          }
        });
      }
    }
  }

  void _rotate() {
    HapticFeedback.lightImpact();
    setState(() {
      _rotationTurns = (_rotationTurns + 1) % 4;
      _transformationController.value = Matrix4.identity();
    });
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _rotationTurns = 0;
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();

    // PENTING: Ambil referensi boundary DAN ukurannya SEBELUM setState,
    // karena setState(_isLoading=true) menghapus RepaintBoundary dari tree
    // sehingga _boundaryKey.currentContext menjadi null.
    final boundary =
        _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gambar belum siap. Coba lagi.')),
        );
      }
      return;
    }

    // Simpan ukuran viewport sekarang (sebelum widget di-unmount)
    final viewportWidth = boundary.size.width;
    final viewportHeight = boundary.size.height;

    final screenSize = MediaQuery.of(context).size;
    final cropSize = math.min(screenSize.width - 48, 320.0);

    // Delay singkat agar transformasi InteractiveViewer selesai di-commit
    // (boundary masih di tree saat ini)
    await Future.delayed(const Duration(milliseconds: 120));

    // Capture gambar penuh dari RepaintBoundary sebelum loading state diset
    ui.Image fullImage;
    try {
      const pixelRatio = 3.0;
      fullImage = await boundary.toImage(pixelRatio: pixelRatio);
    } catch (e) {
      debugPrint('Error capturing boundary image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e')),
        );
      }
      return;
    }

    // Baru sekarang set loading — RepaintBoundary boleh hilang dari tree
    if (mounted) setState(() => _isLoading = true);

    try {
      const pixelRatio = 3.0;

      // Hitung crop rectangle dalam physical pixels
      final cropLeftPx = ((viewportWidth - cropSize) / 2) * pixelRatio;
      final cropTopPx = ((viewportHeight - cropSize) / 2) * pixelRatio;
      final cropSizePx = cropSize * pixelRatio;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Gambar hanya area crop ke canvas baru
      final srcRect = Rect.fromLTWH(cropLeftPx, cropTopPx, cropSizePx, cropSizePx);
      final dstRect = Rect.fromLTWH(0, 0, cropSizePx, cropSizePx);
      canvas.drawImageRect(fullImage, srcRect, dstRect, Paint());

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(cropSizePx.toInt(), cropSizePx.toInt());
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final croppedBytes = byteData.buffer.asUint8List();

      if (mounted) {
        Navigator.pop(context, croppedBytes);
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memotong gambar: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Calculate safe crop area size
    final cropSize = math.min(screenSize.width - 48, 320.0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sesuaikan Foto',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Selesai',
                    style: TextStyle(
                      color: SibersihColors.accentCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: SibersihColors.accentCyan,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final viewportWidth = constraints.maxWidth;
                      final viewportHeight = constraints.maxHeight;

                      double childWidth;
                      double childHeight;

                      if (_rotationTurns % 2 == 0) {
                        // Even rotation (0 or 180 degrees)
                        if (_imageAspectRatio! >= 1.0) {
                          childHeight = cropSize;
                          childWidth = cropSize * _imageAspectRatio!;
                        } else {
                          childWidth = cropSize;
                          childHeight = cropSize / _imageAspectRatio!;
                        }
                      } else {
                        // Odd rotation (90 or 270 degrees)
                        final rotatedAspectRatio = 1.0 / _imageAspectRatio!;
                        double rotatedWidth, rotatedHeight;
                        if (rotatedAspectRatio >= 1.0) {
                          rotatedHeight = cropSize;
                          rotatedWidth = cropSize * rotatedAspectRatio;
                        } else {
                          rotatedWidth = cropSize;
                          rotatedHeight = cropSize / rotatedAspectRatio;
                        }
                        childWidth = rotatedHeight;
                        childHeight = rotatedWidth;
                      }

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // The full viewport container inside RepaintBoundary so that
                          // we capture the full screen area (excluding overlays/buttons)
                          RepaintBoundary(
                            key: _boundaryKey,
                            child: Container(
                              width: viewportWidth,
                              height: viewportHeight,
                              color: Colors.black,
                              child: Center(
                                child: InteractiveViewer(
                                  transformationController: _transformationController,
                                  minScale: 1.0,
                                  maxScale: 5.0,
                                  boundaryMargin: const EdgeInsets.all(240),
                                  clipBehavior: Clip.none,
                                  child: SizedBox(
                                    width: childWidth,
                                    height: childHeight,
                                    child: Center(
                                      child: RotatedBox(
                                        quarterTurns: _rotationTurns,
                                        child: Image.memory(
                                          _imageBytes!,
                                          fit: BoxFit.fill,
                                          width: _rotationTurns % 2 == 0 ? childWidth : childHeight,
                                          height: _rotationTurns % 2 == 0 ? childHeight : childWidth,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Dark overlay mask with circular transparent view hole
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size(viewportWidth, viewportHeight),
                              painter: CropOverlayPainter(cropSize: cropSize),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Tool buttons container
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  color: Colors.black.withValues(alpha: 0.8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _toolButton(
                        icon: Icons.rotate_90_degrees_cw_rounded,
                        label: 'Putar',
                        onTap: _rotate,
                      ),
                      _toolButton(
                        icon: Icons.restart_alt_rounded,
                        label: 'Atur Ulang',
                        onTap: _reset,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CropOverlayPainter extends CustomPainter {
  final double cropSize;

  CropOverlayPainter({required this.cropSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    // 1. Dark mask path outside the circle crop area
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final center = Offset(size.width / 2, size.height / 2);
    final innerPath = Path()..addOval(Rect.fromCircle(center: center, radius: cropSize / 2));
    
    final maskPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(maskPath, paint);

    // 2. White circle border guide
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, cropSize / 2, borderPaint);

    // 3. WhatsApp-style grid lines inside the circle
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final r = cropSize / 2;
    // Calculate the chord limits using math.sqrt(R^2 - y^2) where y = R/3
    final offsetLimit = r * math.sqrt(8.0 / 9.0);

    // Horizontal lines at y = -r/3 and y = r/3
    canvas.drawLine(
      Offset(center.dx - offsetLimit, center.dy - r / 3),
      Offset(center.dx + offsetLimit, center.dy - r / 3),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - offsetLimit, center.dy + r / 3),
      Offset(center.dx + offsetLimit, center.dy + r / 3),
      gridPaint,
    );

    // Vertical lines at x = -r/3 and x = r/3
    canvas.drawLine(
      Offset(center.dx - r / 3, center.dy - offsetLimit),
      Offset(center.dx - r / 3, center.dy + offsetLimit),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx + r / 3, center.dy - offsetLimit),
      Offset(center.dx + r / 3, center.dy + offsetLimit),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) =>
      oldDelegate.cropSize != cropSize;
}
