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

  // -----------------------------------------------------------
  //  PROFILE
  // -----------------------------------------------------------

  Future<UserModel> getCurrentUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return _mockUser;
    return _fetchUser(authUser.id);
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
    } catch (e) {
      debugPrint('updateUserProfile error: $e');
    }
  }

  Future<String?> uploadFotoProfile(Uint8List bytes) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final path =
        'profile_photos/${authUser.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
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
          .limit(limit);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  /// Menghitung jumlah total user terdaftar di DB.
  Future<int> getTotalUsers() async {
    try {
      final data = await _supabase
          .from('users')
          .select('id');
      return (data as List).length;
    } catch (e) {
      debugPrint('getTotalUsers error: $e');
      return 1;
    }
  }

  /// Menghitung rank user berdasarkan total_poin DESC.
  /// Rank = posisi user dalam urutan semua user (1-based).
  Future<int> getUserRank(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('users')
          .select('id, total_poin')
          .order('total_poin', ascending: false);
      final idx = data.indexWhere((u) => u['id'].toString() == userId);
      return idx >= 0 ? idx + 1 : data.length;
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
