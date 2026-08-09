// ============================================================
// SUPABASE SERVICE - WITH GOOGLE OAUTH
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/laporan_model.dart';

class SupabaseService {
  // --- Singleton -------------------------------------------
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  SupabaseClient get _adminClient => SupabaseClient(
        AppConfig.supabaseUrl,
        AppConfig.supabaseServiceRoleKey,
      );
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
      if (response.user == null) {
        return AuthResult.error('User tidak ditemukan');
      }
      _currentUser = await _fetchUser(response.user!.id);
      return AuthResult.success();
    } catch (error) {
      return AuthResult.error(
          _extractError(error, defaultMessage: 'Login gagal'));
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
        'nim': '', // Google user tidak punya NIM
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
      final authResult =
          await _supabase.auth.signUp(email: email.trim(), password: password);
      final user = authResult.user;
      if (user == null) return AuthResult.error('Registrasi gagal');

      final newUser = UserModel(
        uid: user.id,
        nama: nama,
        nim: nim,
        jurusan: jurusan,
        email: email.trim(),
        totalPoin: 0,
        poinMasuk: 0,
        poinKeluar: 0,
        rank: 999,
        jumlahLaporan: 0,
        level: 'Pemula',
        fotoUrl: null,
      );

      await _supabase.from('users').insert({
        'id': newUser.uid,
        'nama': newUser.nama,
        'nim': newUser.nim,
        'jurusan': newUser.jurusan,
        'email': newUser.email,
        'total_poin': newUser.totalPoin,
        'poin_masuk': newUser.poinMasuk,
        'poin_keluar': newUser.poinKeluar,
        'rank': newUser.rank,
        'jumlah_laporan': newUser.jumlahLaporan,
        'level': newUser.level,
      });

      _currentUser = newUser;
      return AuthResult.success();
    } catch (error) {
      return AuthResult.error(
          _extractError(error, defaultMessage: 'Registrasi gagal'));
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

  Future<void> updateUserProfile(
      {String? nama, String? jurusan, String? email}) async {
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
    } catch (e) {
      print(e);
    }
  }

  Future<String?> uploadFotoProfile(Uint8List bytes) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;
    final path =
        'profile_photos/${authUser.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _supabase.storage.from('profile_photos').uploadBinary(path, bytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true));
      final url = _supabase.storage.from('profile_photos').getPublicUrl(path);
      await _supabase
          .from('users')
          .update({'foto_url': url}).eq('id', authUser.id);
      return url;
    } catch (e) {
      return null;
    }
  }

  // -----------------------------------------------------------
  //  POIN & HISTORY
  // -----------------------------------------------------------

  Future<List<Map<String, dynamic>>> getPoinMasukHistory() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase
          .from('poin_history')
          .select()
          .eq('user_id', authUser.id)
          .eq('type', 'masuk')
          .order('tanggal');
      return data
          .map((e) => {
                'icon': e['icon'] ?? '💰',
                'title': e['title'] ?? 'Poin Masuk',
                'date': e['tanggal'],
                'poin': e['poin']
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPoinKeluarHistory() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase
          .from('poin_history')
          .select()
          .eq('user_id', authUser.id)
          .eq('type', 'keluar')
          .order('tanggal');
      return data
          .map((e) => {
                'icon': e['icon'] ?? '🛒',
                'title': e['title'] ?? 'Tukar Poin',
                'date': e['tanggal'],
                'poin': e['poin']
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBulananPoin() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase
          .from('poin_history')
          .select('tanggal, poin')
          .eq('user_id', authUser.id);
      final months = <String, int>{};
      for (var row in data) {
        final date = DateTime.tryParse(row['tanggal'] ?? '');
        if (date != null) {
          final label = _monthName(date.month);
          months[label] = (months[label] ?? 0) + (row['poin'] as int);
        }
      }
      return months.entries
          .map((e) => {'bulan': e.key, 'poin': e.value})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // -----------------------------------------------------------
  //  LAPORAN & OTHERS
  // -----------------------------------------------------------

  Future<bool> submitLaporan({
    required List<Uint8List> fotoBytes,
    required double berat,
    required String lokasi,
    required String catatan,
  }) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return false;
    try {
      final urls = <String>[];
      for (var bytes in fotoBytes) {
        final path =
            'laporan/${authUser.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
        await _supabase.storage
            .from('laporan_photos')
            .uploadBinary(path, bytes);
        urls.add(_supabase.storage.from('laporan_photos').getPublicUrl(path));
      }
      await _supabase.from('laporans').insert({
        'user_id': authUser.id,
        'nama_pelapor': _currentUser?.nama,
        'nim': _currentUser?.nim,
        'foto_urls': urls,
        'berat': berat,
        'lokasi': lokasi,
        'catatan': catatan,
        'status': 'pending',
        'tanggal': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
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

  Future<List<Map<String, String>>> getQuotes() async {
    try {
      final List<dynamic> data =
          await _supabase.from('quotes').select().order('order');
      return data
          .map((e) =>
              {'text': e['text'].toString(), 'author': e['author'].toString()})
          .toList();
    } catch (e) {
      return [
        {
          'text': '"Satu sampah, satu masalah. Bersihkan!"',
          'author': 'Sibersih'
        }
      ];
    }
  }

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

  Future<List<Map<String, dynamic>>> getRewardItems() async {
    try {
      final adminClient = SupabaseClient(
        'https://ciaykezzojnksqlsioqh.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw'
      );
      final List<dynamic> data =
          await adminClient.from('reward_items').select().order('points');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('getRewardItems error: $e');
      return [];
    }
  }

  // -----------------------------------------------------------
  //  UTILITY
  // -----------------------------------------------------------

  Future<UserModel> _fetchUser(String uid) async {
    try {
      final data =
          await _supabase.from('users').select().eq('id', uid).maybeSingle();
      return data != null ? UserModel.fromMap(data, uid) : _mockUser;
    } catch (e) {
      return _mockUser;
    }
  }

  Future<String> _resolveEmail(String emailOrNim) async {
    if (emailOrNim.contains('@')) return emailOrNim;
    try {
      final data = await _supabase
          .from('users')
          .select('email')
          .eq('nim', emailOrNim)
          .maybeSingle();
      return data?['email'] ?? emailOrNim;
    } catch (e) {
      return emailOrNim;
    }
  }

  String _extractError(Object error, {required String defaultMessage}) {
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return error.message;
    return defaultMessage;
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  static const _mockUser = UserModel(
    uid: '0',
    nama: 'Guest',
    nim: '0',
    jurusan: '-',
    email: '',
    totalPoin: 0,
    poinMasuk: 0,
    poinKeluar: 0,
    rank: 0,
    jumlahLaporan: 0,
    level: 'Pemula',
  );

  // -----------------------------------------------------------
  //  ADMIN METHODS
  // -----------------------------------------------------------

  bool get isAdminLoggedIn => _supabase.auth.currentUser?.email != null && (_supabase.auth.currentUser!.email!.contains('admin'));

  Future<AuthResult> loginAdmin(String emailOrUsername, String password) async {
    String email = emailOrUsername.trim();
    if (email.toLowerCase() == 'admin') {
      email = 'admin@sibersih.com';
    } else if (!email.contains('@')) {
      email = '$email@sibersih.com';
    }
    return login(email, password);
  }

  Future<void> logoutAdmin() async {
    return logout();
  }

  Future<Map<String, int>> getAdminOverview() async {
    try {
      final users = await _supabase.from('users').select('id');
      final laporans = await _supabase.from('laporans').select('id, status');
      
      int pending = 0;
      int verified = 0;
      for (var l in laporans) {
        if (l['status'] == 'pending') pending++;
        if (l['status'] == 'verified') verified++;
      }
      
      final poinData = await _supabase.from('users').select('total_poin');
      int totalPoints = 0;
      for (var p in poinData) {
        totalPoints += ((p['total_poin'] as num?)?.toInt() ?? 0);
      }
      
      return {
        'users': users.length,
        'laporans': laporans.length,
        'pending': pending,
        'verified': verified,
        'points': totalPoints,
      };
    } catch(e) {
      return {'users': 0, 'laporans': 0, 'pending': 0, 'verified': 0, 'points': 0};
    }
  }

  Future<List<dynamic>> getAdminRewards() async {
    try {
      return await _adminClient.from('reward_items').select().order('points');
    } catch(e) { return []; }
  }

  Future<List<dynamic>> getAdminQuotes() async {
    try {
      return await _adminClient.from('quotes').select().order('order');
    } catch(e) { 
      debugPrint('getAdminQuotes error: $e');
      return []; 
    }
  }

  Future<List<dynamic>> getFaqs() async {
    try {
      return await _adminClient.from('faq').select().order('urutan', ascending: true);
    } catch(e) { 
      debugPrint('getFaqs error: $e');
      return []; 
    }
  }

  Future<bool> saveFaqItem({String? id, required String pertanyaan, required String jawaban, required int urutan}) async {
    try {
      final data = {'pertanyaan': pertanyaan, 'jawaban': jawaban, 'urutan': urutan};
      if (id != null) {
        await _adminClient.from('faq').update(data).eq('id', id);
      } else {
        await _adminClient.from('faq').insert(data);
      }
      return true;
    } catch(e) { 
      debugPrint('saveFaqItem error: $e');
      return false; 
    }
  }

  Future<bool> deleteFaqItem(String id) async {
    try {
      await _adminClient.from('faq').delete().eq('id', id);
      return true;
    } catch(e) { 
      debugPrint('deleteFaqItem error: $e');
      return false; 
    }
  }

  Future<List<dynamic>> getAdminLaporans() async {
    try {
      return await _adminClient
          .from('laporans')
          .select('*, users(id, nama, email, nim, jurusan, foto_url)')
          .order('tanggal', ascending: false);
    } catch(e) { 
      debugPrint('getAdminLaporans error: $e');
      return []; 
    }
  }

  Future<bool> updateLaporanStatus({
    required String laporanId, 
    required String status, 
    int? poinDiterima,
    String? userId,
  }) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (poinDiterima != null) {
        data['poin_diterima'] = poinDiterima;
      }
      await _adminClient.from('laporans').update(data).eq('id', laporanId);

      // Jika laporan diverifikasi, tambahkan poin dan jumlah_laporan ke user
      if (status == 'diverifikasi') {
        String? targetUserId = userId;
        if (targetUserId == null || targetUserId.isEmpty) {
          final lap = await _adminClient
              .from('laporans')
              .select('user_id')
              .eq('id', laporanId)
              .maybeSingle();
          targetUserId = lap?['user_id']?.toString();
        }
        if (targetUserId != null && targetUserId.isNotEmpty) {
          final userRes = await _adminClient
              .from('users')
              .select('total_poin, poin_masuk, jumlah_laporan')
              .eq('id', targetUserId)
              .maybeSingle();
          if (userRes != null) {
            final currentPoin = (userRes['total_poin'] as num?)?.toInt() ?? 0;
            final currentPoinMasuk = (userRes['poin_masuk'] as num?)?.toInt() ?? 0;
            final currentLaporan = (userRes['jumlah_laporan'] as num?)?.toInt() ?? 0;
            final addPoin = poinDiterima ?? 100;

            await _adminClient.from('users').update({
              'total_poin': currentPoin + addPoin,
              'poin_masuk': currentPoinMasuk + addPoin,
              'jumlah_laporan': currentLaporan + 1,
            }).eq('id', targetUserId);

            await _adminClient.from('poin_history').insert({
              'user_id': targetUserId,
              'judul': 'Laporan Sampah Diverifikasi',
              'poin': addPoin,
              'type': 'masuk',
              'tanggal': DateTime.now().toIso8601String(),
            });
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('updateLaporanStatus error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getPanduans() async {
    try {
      return await _adminClient.from('panduan').select().order('nomor', ascending: true);
    } catch(e) { 
      debugPrint('getPanduans error: $e');
      return []; 
    }
  }

  Future<bool> savePanduanItem({String? id, required int nomor, required String emoji, required String title, required String description, required List<String> tips, required List<String> gambarUrls}) async {
    try {
      final data = {
        'nomor': nomor,
        'emoji': emoji,
        'title': title,
        'description': description,
        'tips': tips,
        'gambar_urls': gambarUrls,
      };
      if (id != null) {
        await _adminClient.from('panduan').update(data).eq('id', id);
      } else {
        await _adminClient.from('panduan').insert(data);
      }
      return true;
    } catch (e) { 
      debugPrint('savePanduanItem error: $e');
      return false; 
    }
  }

  Future<bool> deletePanduanItem(String id) async {
    try {
      await _adminClient.from('panduan').delete().eq('id', id);
      return true;
    } catch (e) { 
      debugPrint('deletePanduanItem error: $e');
      return false; 
    }
  }

  Future<bool> saveQuoteItem({String? id, required String text, required String author, required int order}) async {
    try {
      final data = {'text': text, 'author': author, 'order': order};
      if (id != null) {
        await _adminClient.from('quotes').update(data).eq('id', id);
      } else {
        await _adminClient.from('quotes').insert(data);
      }
      return true;
    } catch (e) { 
      debugPrint('saveQuoteItem error: $e');
      return false; 
    }
  }

  Future<bool> deleteQuoteItem(String id) async {
    try {
      await _adminClient.from('quotes').delete().eq('id', id);
      return true;
    } catch (e) { 
      debugPrint('deleteQuoteItem error: $e');
      return false; 
    }
  }

  Future<bool> saveRewardItem({String? id, required String name, required int points, required String description, String? imageUrl}) async {
    try {
      final data = {'name': name, 'points': points, 'description': description};
      if (imageUrl != null) data['image_url'] = imageUrl;
      
      if (id != null) {
        await _adminClient.from('reward_items').update(data).eq('id', id);
      } else {
        await _adminClient.from('reward_items').insert(data);
      }
      return true;
    } catch (e) { 
      debugPrint('saveRewardItem error: $e');
      throw Exception('DB Error: $e'); 
    }
  }

  Future<bool> deleteRewardItem(String id) async {
    try {
      await _adminClient.from('reward_items').delete().eq('id', id);
      return true;
    } catch (e) { 
      debugPrint('deleteRewardItem error: $e');
      throw Exception('DB Error: $e'); 
    }
  }

  Future<String?> uploadRewardImage(Uint8List bytes, String extension) async {
    try {
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'rewards/$uniqueName';
      
      await _adminClient.storage.from('reward_images').uploadBinary(
        path, 
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      return _supabase.storage.from('reward_images').getPublicUrl(path);
    } catch(e) { 
      debugPrint('uploadRewardImage error: $e');
      throw Exception('Detail: $e'); 
    }
  }

  Future<List<dynamic>> getAdminUsers() async {
    try {
      return await _supabase.from('users').select().order('total_poin', ascending: false);
    } catch(e) { return []; }
  }
}

class AuthResult {
  final bool success;
  final String? errorMessage;
  AuthResult._({required this.success, this.errorMessage});
  factory AuthResult.success() => AuthResult._(success: true);
  factory AuthResult.error(String msg) =>
      AuthResult._(success: false, errorMessage: msg);
}
