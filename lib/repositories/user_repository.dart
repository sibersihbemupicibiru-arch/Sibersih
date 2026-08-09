// ============================================================
// USER REPOSITORY
// Mengelola profil user, update data, upload foto, leaderboard.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_client.dart';

class UserRepository {
  // --- Singleton -------------------------------------------
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final _supabase = SupabaseClientProvider.instance.client;

  // --- In-memory cache untuk getCurrentUser ----------------
  UserModel? _cachedUser;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(seconds: 60);

  // -----------------------------------------------------------
  //  PROFILE
  // -----------------------------------------------------------

  /// Ambil user saat ini. Hasil di-cache selama 60 detik agar
  /// tidak hit DB setiap kali halaman dibuka.
  /// Gunakan [forceRefresh: true] setelah update profil / upload foto.
  Future<UserModel> getCurrentUser({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedUser != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedUser!;
    }
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return _mockUser;
    final user = await _fetchUser(authUser.id);
    _cachedUser = user;
    _cacheTime = DateTime.now();
    return user;
  }

  /// Hapus cache — panggil setelah update profil atau upload foto.
  void invalidateCache() {
    _cachedUser = null;
    _cacheTime = null;
  }

  Future<void> updateUserProfile({
    String? nama,
    String? jurusan,
    String? email,
  }) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return;

    final updates = {
      if (nama != null) 'nama': nama,
      if (jurusan != null) 'jurusan': jurusan,
      if (email != null) 'email': email.trim(),
    };

    try {
      await _supabase.from('users').update(updates).eq('id', authUser.id);
      invalidateCache(); // data berubah → cache tidak valid
    } catch (e) {
      debugPrint('updateUserProfile error: $e');
    }
  }

  Future<String?> uploadFotoProfile(Uint8List bytes) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final path =
        '${authUser.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _supabase.storage.from('profile_photos').uploadBinary(
            path,
            bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      final url = _supabase.storage.from('profile_photos').getPublicUrl(path);
      await _supabase
          .from('users')
          .update({'foto_url': url}).eq('id', authUser.id);
      invalidateCache(); // foto berubah → cache tidak valid
      return url;
    } catch (e) {
      debugPrint('uploadFotoProfile error: $e');
      rethrow;
    }
  }

  // -----------------------------------------------------------
  //  LEADERBOARD
  // -----------------------------------------------------------

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final List<dynamic> data = await _supabase
          .from('users')
          .select()
          .order('total_poin', ascending: false)
          .order('id', ascending: true) // Tie-breaker deterministik
          .limit(limit);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  /// Hitung jumlah total user terdaftar — menggunakan COUNT di DB,
  /// bukan fetch semua baris ke client.
  Future<int> getTotalUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id', const FetchOptions(count: CountOption.exact));
      return response.count ?? 0;
    } catch (e) {
      debugPrint('getTotalUsers error: $e');
      return 1;
    }
  }

  /// Hitung rank user berdasarkan total_poin DESC.
  /// Menggunakan dua query ringan (bukan download semua user):
  ///   1. Ambil poin user ini (1 baris).
  ///   2. COUNT berapa user yang poinnya lebih tinggi + COUNT user poin sama dengan ID lebih kecil.
  Future<int> getUserRank(String userId) async {
    try {
      // Ambil poin user ini — 1 baris saja
      final userData = await _supabase
          .from('users')
          .select('total_poin')
          .eq('id', userId)
          .maybeSingle();

      final myPoin = (userData?['total_poin'] as num?)?.toInt() ?? 0;

      // 1. Hitung berapa user yang poinnya lebih tinggi
      final higherPoinResponse = await _supabase
          .from('users')
          .select('id', const FetchOptions(count: CountOption.exact))
          .gt('total_poin', myPoin);

      // 2. Hitung berapa user yang poinnya sama tetapi ID-nya lebih kecil (tie-breaker)
      final equalPoinResponse = await _supabase
          .from('users')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('total_poin', myPoin)
          .lt('id', userId);

      final higherCount = higherPoinResponse.count ?? 0;
      final equalCount = equalPoinResponse.count ?? 0;

      return higherCount + equalCount + 1;
    } catch (e) {
      debugPrint('getUserRank error: $e');
      return 1;
    }
  }

  // -----------------------------------------------------------
  //  PRIVATE HELPERS
  // -----------------------------------------------------------

  Future<UserModel> _fetchUser(String userId) async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return _mockUser;
    return UserModel.fromMap(Map<String, dynamic>.from(data as Map), userId);
  }

  static const _mockUser = UserModel(
    uid: '0', nama: 'Guest', nim: '0', jurusan: '-',
    email: '', totalPoin: 0, poinMasuk: 0, poinKeluar: 0,
    rank: 0, jumlahLaporan: 0, level: 'Pemula',
  );
}
