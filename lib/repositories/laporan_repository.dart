// ============================================================
// LAPORAN REPOSITORY
// Mengelola submit laporan, riwayat, dan image hashing untuk
// deteksi foto duplikat.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../core/result.dart';
import '../models/laporan_model.dart';
import '../services/supabase_client.dart';
import '../config/app_config.dart';

class LaporanRepository {
  // --- Singleton -------------------------------------------
  LaporanRepository._();
  static final LaporanRepository instance = LaporanRepository._();

  final _supabase = SupabaseClientProvider.instance.client;

  // -----------------------------------------------------------
  //  RATE LIMITING (anti-spam)
  // -----------------------------------------------------------

  /// Cek apakah user masih dalam cooldown setelah submit terakhir.
  /// Returns null jika OK, returns sisa detik cooldown jika masih harus tunggu.
  Future<int?> checkSubmitCooldown({
    int cooldownMinutes = 5,
  }) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;
    try {
      final cutoff = DateTime.now()
          .subtract(Duration(minutes: cooldownMinutes))
          .toUtc()
          .toIso8601String();
      final List<dynamic> data = await _supabase
          .from('laporans')
          .select('tanggal')
          .eq('user_id', authUser.id)
          .gte('tanggal', cutoff)
          .order('tanggal', ascending: false)
          .limit(1);

      if (data.isEmpty) return null;

      final lastStr = data.first['tanggal'] as String?;
      if (lastStr == null) return null;

      final lastTime = DateTime.parse(lastStr).toLocal();
      final diff = DateTime.now().difference(lastTime);
      final remaining = Duration(minutes: cooldownMinutes) - diff;
      return remaining.isNegative ? null : remaining.inSeconds;
    } catch (e) {
      debugPrint('checkSubmitCooldown error: $e');
      return null; // Fail open — jangan blokir user kalau DB error
    }
  }

  /// Cek apakah user sudah melewati batas laporan harian.
  /// Returns true jika masih boleh submit, false jika sudah melebihi batas.
  Future<bool> checkDailyLimit({
    int maxPerDay = 10,
  }) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return false;
    try {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ).toUtc().toIso8601String();

      final List<dynamic> data = await _supabase
          .from('laporans')
          .select('id')
          .eq('user_id', authUser.id)
          .gte('tanggal', today);

      return data.length < maxPerDay;
    } catch (e) {
      debugPrint('checkDailyLimit error: $e');
      return true; // Fail open
    }
  }

  // -----------------------------------------------------------
  //  FOTO HASHING (public — dipanggil dari page)
  // -----------------------------------------------------------

  /// Difference Hash (dHash) 32x32 → 1024-bit string '0'/'1'.
  /// Dipakai untuk deteksi foto duplikat via hamming distance.
  String hashImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return '';

    final resized = img.copyResize(image, width: 32, height: 32);
    final grayscale = img.grayscale(resized);

    final pixels = <double>[];
    for (int y = 0; y < 32; y++) {
      for (int x = 0; x < 32; x++) {
        pixels.add(grayscale.getPixel(x, y).luminance.toDouble());
      }
    }

    final avg = pixels.reduce((a, b) => a + b) / pixels.length;
    return pixels.map((p) => p > avg ? '1' : '0').join();
  }

  /// Cek apakah [newHash] duplikat dengan salah satu hash di [existingHashes].
  /// Threshold hamming distance <= [threshold] dianggap duplikat.
  bool isDuplicateHash(
    String newHash,
    List<String> existingHashes, {
    int threshold = 102, // ~10% dari 1024 bit
  }) {
    for (final h in existingHashes) {
      if (_hammingDistance(newHash, h) <= threshold) return true;
    }
    return false;
  }

  // -----------------------------------------------------------
  //  CRUD
  // -----------------------------------------------------------

  /// Fetch semua dHash foto milik user dari DB.
  Future<List<String>> getUserFotoHashes() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase
          .from('laporans')
          .select('foto_hashes')
          .eq('user_id', authUser.id);

      final hashes = <String>[];
      for (final row in data) {
        final list = row['foto_hashes'];
        if (list is List) {
          hashes.addAll(list.map((e) => e.toString()));
        }
      }
      return hashes;
    } catch (e) {
      debugPrint('getUserFotoHashes error: $e');
      return [];
    }
  }

  /// Submit laporan sampah.
  ///
  /// Hash & cek duplikat sudah dilakukan di page sebelum method ini dipanggil.
  /// Method ini: upload foto ke Storage → invoke Edge Function.
  Future<SubmitResult> submitLaporan({
    required List<Uint8List> fotoBytes,
    required List<String> fotoHashes,
    required String kategori,
    required String ukuran,
    required String catatan,
  }) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return SubmitResult.error();

    try {
      // Upload foto ke Storage
      final urls = <String>[];
      for (final bytes in fotoBytes) {
        final path =
            '${authUser.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
        await _supabase.storage
            .from(AppConfig.bucketLaporanPhotos)
            .uploadBinary(path, bytes);
        final url = _supabase.storage
            .from(AppConfig.bucketLaporanPhotos)
            .getPublicUrl(path);
        if (url.isNotEmpty) urls.add(url);
      }
      if (urls.isEmpty) return SubmitResult.error();

      // Invoke Edge Function
      final response = await _supabase.functions.invoke(
        AppConfig.submitLaporanFunction,
        body: {
          'foto_urls'  : urls,
          'foto_hashes': fotoHashes,
          'kategori'   : kategori,
          'ukuran'     : ukuran,
          'catatan'    : catatan,
          'lokasi'     : AppConfig.defaultLokasi,
        },
      );

      if (response.status == 409) return SubmitResult.duplicate();
      if (response.status != 200) return SubmitResult.error();

      final poin = (response.data as Map<String, dynamic>)['poin_diterima'];
      return SubmitResult.success(
          poin is int ? poin : int.parse(poin.toString()));
    } catch (e) {
      debugPrint('LAPORAN ERROR: $e');
      return SubmitResult.error();
    }
  }

  Future<List<LaporanModel>> getRiwayatLaporan() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase
          .from('laporans')
          .select()
          .eq('user_id', authUser.id)
          .order('tanggal');
      return data
          .map((e) => LaporanModel.fromMap(e, e['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Ambil [limit] laporan terbaru user, diurutkan dari yang terbaru.
  Future<List<LaporanModel>> getRecentLaporans({int limit = 5}) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase
          .from('laporans')
          .select()
          .eq('user_id', authUser.id)
          .order('tanggal', ascending: false)
          .limit(limit);
      return data
          .map((e) => LaporanModel.fromMap(e, e['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // -----------------------------------------------------------
  //  PRIVATE HELPERS
  // -----------------------------------------------------------

  int _hammingDistance(String a, String b) {
    int dist = 0;
    for (int i = 0; i < a.length && i < b.length; i++) {
      if (a[i] != b[i]) dist++;
    }
    return dist;
  }
}
