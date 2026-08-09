import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

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
  static Future<void> preload() async {}

  static Future<AiScanResult> analyzeImage(
    Uint8List bytes, {
    String? sourceName,
  }) async {
    try {
      final base64Image = base64Encode(bytes);
      final session = Supabase.instance.client.auth.currentSession;
      final response = await http
          .post(
            Uri.parse(
              '${AppConfig.supabaseUrl}/functions/v1/${AppConfig.geminiScanFunction}',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session?.accessToken}',
            },
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {
                      "text": """
Analisa gambar ini.

Jika ada botol plastik:
{
  "type": "plastic",
  "confidence": 0.95
}

Jika ada botol kaca:
{
  "type": "glass",
  "confidence": 0.95
}

Jika tidak ada botol:
{
  "type": "none",
  "confidence": 0.0
}

Balas JSON saja tanpa teks tambahan.
"""
                    },
                    {
                      "inline_data": {
                        "mime_type": "image/jpeg",
                        "data": base64Image,
                      }
                    }
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return AiScanResult.noBottleFound();
      }

      final responseData = jsonDecode(response.body);
      final text =
          responseData['candidates'][0]['content']['parts'][0]['text'];

      // Bersihkan markdown Gemini kalau ada
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final result = jsonDecode(cleaned);
      final type = result['type'];
      final confidence =
          (result['confidence'] as num?)?.toDouble() ?? 0.0;

      if (type == 'plastic') return AiScanResult.plasticBottle(confidence);
      if (type == 'glass') return AiScanResult.glassBottle(confidence);

      return AiScanResult.noBottleFound();
    } catch (e) {
      print('AI Scan Error: $e');
      return AiScanResult.noBottleFound();
    }
  }
}