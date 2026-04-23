// ============================================================
// SUPABASE SERVICE - WITH GOOGLE OAUTH
// ============================================================

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/laporan_model.dart';

class SupabaseService {
  // --- Singleton -------------------------------------------
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  UserModel? _currentUser;

  // -----------------------------------------------------------
  //  AUTH
  // -----------------------------------------------------------

  Future<AuthResult> login(String emailOrNim, String password) async {
    try {
      final email = await _resolveEmail(emailOrNim.trim());
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) return AuthResult.error('User tidak ditemukan');
      _currentUser = await _fetchUser(response.user!.id);
      return AuthResult.success();
    } catch (error) {
      return AuthResult.error(_extractError(error, defaultMessage: 'Login gagal'));
    }
  }

  /// Login dengan Google OAuth.
  /// Di web: buka popup Google → redirect kembali ke app → auth state berubah.
  /// Di mobile: gunakan custom scheme / deep link agar app menerima callback.
  /// Navigasi ke /home ditangani oleh listener di main.dart.
  Future<AuthResult> loginWithGoogle() async {
    try {
      final redirectTo = kIsWeb
          ? '${Uri.base.origin}${Uri.base.path}'
          : 'com.example.sibersih://login-callback';

      await _supabase.auth.signInWithOAuth(
        Provider.google,
        redirectTo: redirectTo,
      );
      // signInWithOAuth tidak langsung return user (redirect flow),
      // jadi kita return success dan biarkan onAuthStateChange di main.dart yang handle
      return AuthResult.success();
    } catch (error) {
      return AuthResult.error('Login Google gagal. Coba lagi.');
    }
  }

  /// Dipanggil setelah Google OAuth redirect berhasil.
  /// Jika user baru (pertama kali login Google), buat record di tabel users.
  Future<void> ensureUserRecord() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return;

    final existing = await _supabase
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (existing == null) {
      // User baru dari Google — buat record dengan data dari Google
      final meta = authUser.userMetadata ?? {};
      final nama = meta['full_name'] as String? ??
          meta['name'] as String? ??
          authUser.email?.split('@').first ??
          'User';

      await _supabase.from('users').insert({
        'id': authUser.id,
        'nama': nama,
        'nim': '',           // Google user tidak punya NIM
        'jurusan': '',
        'email': authUser.email ?? '',
        'total_poin': 0,
        'poin_masuk': 0,
        'poin_keluar': 0,
        'rank': 999,
        'jumlah_laporan': 0,
        'level': 'Pemula',
        'foto_url': meta['avatar_url'] as String?,
      });
    }

    _currentUser = await _fetchUser(authUser.id);
  }

  Future<AuthResult> register({
    required String nama,
    required String nim,
    required String jurusan,
    required String email,
    required String password,
  }) async {
    try {
      final authResult = await _supabase.auth.signUp(email: email.trim(), password: password);
      final user = authResult.user;
      if (user == null) return AuthResult.error('Registrasi gagal');

      final newUser = UserModel(
        uid: user.id,
        nama: nama, nim: nim, jurusan: jurusan, email: email.trim(),
        totalPoin: 0, poinMasuk: 0, poinKeluar: 0, rank: 999,
        jumlahLaporan: 0, level: 'Pemula', fotoUrl: null,
      );

      await _supabase.from('users').insert({
        'id': newUser.uid, 'nama': newUser.nama, 'nim': newUser.nim,
        'jurusan': newUser.jurusan, 'email': newUser.email,
        'total_poin': newUser.totalPoin, 'poin_masuk': newUser.poinMasuk,
        'poin_keluar': newUser.poinKeluar, 'rank': newUser.rank,
        'jumlah_laporan': newUser.jumlahLaporan, 'level': newUser.level,
      });

      _currentUser = newUser;
      return AuthResult.success();
    } catch (error) {
      return AuthResult.error(_extractError(error, defaultMessage: 'Registrasi gagal'));
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _supabase.auth.signOut();
  }

  bool get isLoggedIn => _supabase.auth.currentUser != null;

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  // -----------------------------------------------------------
  //  USER & PROFILE
  // -----------------------------------------------------------

  Future<UserModel> getCurrentUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return _currentUser ?? _mockUser;
    _currentUser = await _fetchUser(authUser.id);
    return _currentUser!;
  }

  Future<void> updateUserProfile({String? nama, String? jurusan, String? email}) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return;
    final updates = {
      if (nama != null) 'nama': nama,
      if (jurusan != null) 'jurusan': jurusan,
      if (email != null) 'email': email.trim(),
    };
    try {
      await _supabase.from('users').update(updates).eq('id', authUser.id);
      _currentUser = await _fetchUser(authUser.id);
    } catch (e) { print(e); }
  }

  Future<String?> uploadFotoProfile(Uint8List bytes) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;
    final path = 'profile_photos/${authUser.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _supabase.storage.from('profile_photos').uploadBinary(path, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
      final url = _supabase.storage.from('profile_photos').getPublicUrl(path);
      await _supabase.from('users').update({'foto_url': url}).eq('id', authUser.id);
      return url;
    } catch (e) { return null; }
  }

  // -----------------------------------------------------------
  //  POIN & HISTORY
  // -----------------------------------------------------------

  Future<List<Map<String, dynamic>>> getPoinMasukHistory() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase.from('poin_history')
          .select().eq('user_id', authUser.id).eq('type', 'masuk').order('tanggal');
      return data.map((e) => {'icon': e['icon'] ?? '💰', 'title': e['title'] ?? 'Poin Masuk', 'date': e['tanggal'], 'poin': e['poin']}).toList();
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getPoinKeluarHistory() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase.from('poin_history')
          .select().eq('user_id', authUser.id).eq('type', 'keluar').order('tanggal');
      return data.map((e) => {'icon': e['icon'] ?? '🛒', 'title': e['title'] ?? 'Tukar Poin', 'date': e['tanggal'], 'poin': e['poin']}).toList();
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getBulananPoin() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase.from('poin_history').select('tanggal, poin').eq('user_id', authUser.id);
      final months = <String, int>{};
      for (var row in data) {
        final date = DateTime.tryParse(row['tanggal'] ?? '');
        if (date != null) {
          final label = _monthName(date.month);
          months[label] = (months[label] ?? 0) + (row['poin'] as int);
        }
      }
      return months.entries.map((e) => {'bulan': e.key, 'poin': e.value}).toList();
    } catch (e) { return []; }
  }

  // -----------------------------------------------------------
  //  LAPORAN & OTHERS
  // -----------------------------------------------------------

  Future<bool> submitLaporan({
    required List<Uint8List> fotoBytes,
    required String kategori,   // 'plastik' | 'kaca'
    required String ukuran,     // 'kecil' | 'sedang' | 'besar'
    required int poin,
    required String catatan,
  }) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return false;
    const lokasi = 'Gedung B lt 1'; // fixed
    try {
      final urls = <String>[];
      for (var bytes in fotoBytes) {
        final path = 'laporan/${authUser.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
        await _supabase.storage.from('laporan_photos').uploadBinary(path, bytes);
        final url = _supabase.storage.from('laporan_photos').getPublicUrl(path);
        if (url.isNotEmpty) urls.add(url);
      }
      if (urls.isEmpty) return false;
      await _supabase.from('laporans').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'user_id': authUser.id,
        'foto_urls': urls,
        'kategori': kategori,
        'ukuran': ukuran,
        'poin_diterima': poin,
        'lokasi': lokasi,
        'catatan': catatan,
        'status': 'pending',
        'tanggal': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('LAPORAN ERROR: $e');
      return false;
    }
  }

  Future<List<LaporanModel>> getRiwayatLaporan() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase.from('laporans')
          .select().eq('user_id', authUser.id).order('tanggal');
      return data.map((e) => LaporanModel.fromMap(e, e['id'].toString())).toList();
    } catch (e) { return []; }
  }

  Future<List<Map<String, String>>> getQuotes() async {
    try {
      final List<dynamic> data = await _supabase.from('quotes').select().order('order');
      return data.map((e) => {'text': e['text'].toString(), 'author': e['author'].toString()}).toList();
    } catch (e) {
      return [{'text': '"Satu sampah, satu masalah. Bersihkan!"', 'author': 'Sibersih'}];
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final List<dynamic> data = await _supabase.from('users')
          .select().order('total_poin', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getRewardItems() async {
    try {
      final List<dynamic> data = await _supabase.from('reward_items').select().order('points');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) { return []; }
  }

  // -----------------------------------------------------------
  //  UTILITY
  // -----------------------------------------------------------

  Future<UserModel> _fetchUser(String uid) async {
    try {
      final data = await _supabase.from('users').select().eq('id', uid).maybeSingle();
      return data != null ? UserModel.fromMap(data, uid) : _mockUser;
    } catch (e) { return _mockUser; }
  }

  Future<String> _resolveEmail(String emailOrNim) async {
    if (emailOrNim.contains('@')) return emailOrNim;
    try {
      final data = await _supabase.from('users').select('email').eq('nim', emailOrNim).maybeSingle();
      return data?['email'] ?? emailOrNim;
    } catch (e) { return emailOrNim; }
  }

  String _extractError(Object error, {required String defaultMessage}) {
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return error.message;
    return defaultMessage;
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return names[(month - 1).clamp(0, 11)];
  }

  static const _mockUser = UserModel(
    uid: '0', nama: 'Guest', nim: '0', jurusan: '-',
    email: '', totalPoin: 0, poinMasuk: 0, poinKeluar: 0,
    rank: 0, jumlahLaporan: 0, level: 'Pemula',
  );
}

class AuthResult {
  final bool success;
  final String? errorMessage;
  AuthResult._({required this.success, this.errorMessage});
  factory AuthResult.success() => AuthResult._(success: true);
  factory AuthResult.error(String msg) => AuthResult._(success: false, errorMessage: msg);
}
