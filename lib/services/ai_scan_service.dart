import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

enum BottleType { plasticBottle, glassBottle, unknown }

class AiScanResult {
  final bool isAccepted;
  final BottleType type;
  final String label;
  final String message;
  final String emoji;
  final int confidencePercent;

  AiScanResult({
    required this.isAccepted,
    required this.type,
    required this.label,
    required this.message,
    required this.emoji,
    required this.confidencePercent,
  });

  factory AiScanResult.noBottleFound() => AiScanResult(
        isAccepted: false,
        type: BottleType.unknown,
        label: 'Botol tidak ditemukan',
        message: 'Pastikan foto menunjukkan botol plastik dengan jelas.',
        emoji: '❌',
        confidencePercent: 0,
      );

  factory AiScanResult.plasticBottle(double confidence) => AiScanResult(
        isAccepted: true,
        type: BottleType.plasticBottle,
        label: 'Botol plastik terdeteksi',
        message: 'Foto mengandung botol plastik dan siap dilaporkan.',
        emoji: '✅',
        confidencePercent: (confidence * 100).clamp(0, 100).round(),
      );

  factory AiScanResult.glassBottle(double confidence) => AiScanResult(
        isAccepted: false,
        type: BottleType.glassBottle,
        label: 'Botol kaca terdeteksi',
        message: 'Hanya botol kaca yang terdeteksi. Gunakan botol plastik.',
        emoji: '🧴',
        confidencePercent: (confidence * 100).clamp(0, 100).round(),
      );
}

class AiScanService {
  AiScanService._();

  // Ganti dengan URL HF Space-mu setelah deploy
  static const _baseUrl = 'https://ssemperor-sibersihai.hf.space';

  static Future<void> preload() async {} // tidak perlu preload lagi

  static Future<AiScanResult> analyzeImage(
    Uint8List bytes, {
    String? sourceName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/classify'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: sourceName ?? 'image.jpg',
        contentType: MediaType('image', 'jpeg'), // ← tambah ini
      ));

      final streamed  = await request.send().timeout(const Duration(seconds: 30));
      final response  = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) return AiScanResult.noBottleFound();

      final map     = jsonDecode(response.body) as Map<String, dynamic>;
      final plastic = (map['plastic'] as num?)?.toDouble() ?? 0.0;
      final glass   = (map['glass']   as num?)?.toDouble() ?? 0.0;

      const threshold = 0.25;
      if (plastic >= glass && plastic >= threshold) return AiScanResult.plasticBottle(plastic);
      if (glass > plastic  && glass   >= threshold) return AiScanResult.glassBottle(glass);
      return AiScanResult.noBottleFound();

    } catch (_) {
      return AiScanResult.noBottleFound();
    }
  }
}