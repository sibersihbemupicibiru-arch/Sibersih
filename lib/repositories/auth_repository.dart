// ============================================================
// AUTH REPOSITORY
// Mengelola semua operasi autentikasi:
// login, register, google OAuth, logout, dsb.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/result.dart';
import '../models/user_model.dart';
import '../services/supabase_client.dart';

class AuthRepository {
  // --- Singleton -------------------------------------------
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final _supabase = SupabaseClientProvider.instance.client;

  // ── State internal ────────────────────────────────────────
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  void setCurrentUser(UserModel? user) => _currentUser = user;

  // ── Getters ───────────────────────────────────────────────

  bool get isLoggedIn => _supabase.auth.currentUser != null;

  bool get isGoogleLoggedIn {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    final identities = user.identities;
    final hasGoogleIdentity = identities?.any((identity) => identity.provider == 'google') ?? false;
    return user.appMetadata['provider'] == 'google' || hasGoogleIdentity;
  }

  // -----------------------------------------------------------
  //  LOGIN & REGISTER
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

  Future<AuthResult> loginWithGoogle() async {
    try {
      final redirectTo = kIsWeb
          ? Uri.base.origin
          : 'com.sibersih.app://login-callback';

      await _supabase.auth.signInWithOAuth(
        Provider.google,
        redirectTo: redirectTo,
      );
      return AuthResult.success();
    } catch (error) {
      return AuthResult.error('Login Google gagal. Coba lagi.');
    }
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
        'id'            : newUser.uid,
        'nama'          : newUser.nama,
        'nim'           : newUser.nim,
        'jurusan'       : newUser.jurusan,
        'email'         : newUser.email,
        'total_poin'    : newUser.totalPoin,
        'poin_masuk'    : newUser.poinMasuk,
        'poin_keluar'   : newUser.poinKeluar,
        'rank'          : newUser.rank,
        'jumlah_laporan': newUser.jumlahLaporan,
        'level'         : newUser.level,
      });

      _currentUser = newUser;
      return AuthResult.success();
    } catch (error) {
      return AuthResult.error(
          _extractError(error, defaultMessage: 'Registrasi gagal'));
    }
  }

  Future<AuthResult> resendConfirmationEmail({required String email}) async {
    try {
      await _supabase.auth.resend(type: OtpType.signup, email: email);
      return AuthResult.success();
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _supabase.auth.signOut();
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  // -----------------------------------------------------------
  //  GOOGLE PROFILE COMPLETION
  // -----------------------------------------------------------

  Future<AuthResult> completeGoogleProfile({
    required String nama,
    required String nim,
    required String jurusan,
  }) async {
    try {
      final authUser = _supabase.auth.currentUser!;
      final meta = authUser.userMetadata ?? {};

      await _supabase.from('users').insert({
        'id'            : authUser.id,
        'nama'          : nama,
        'nim'           : nim,
        'jurusan'       : jurusan,
        'email'         : authUser.email ?? '',
        'total_poin'    : 0,
        'poin_masuk'    : 0,
        'poin_keluar'   : 0,
        'rank'          : 999,
        'jumlah_laporan': 0,
        'level'         : 'Pemula',
        'foto_url'      : meta['avatar_url'] as String?,
      });

      _currentUser = await _fetchUser(authUser.id);
      return AuthResult.success();
    } catch (e) {
      return AuthResult.error(
          _extractError(e, defaultMessage: 'Gagal menyimpan profil'));
    }
  }

  Future<bool> isProfileComplete(String uid) async {
    final data = await _supabase
        .from('users')
        .select('id')
        .eq('id', uid)
        .maybeSingle();
    return data != null;
  }

  Future<void> ensureUserRecord() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return;

    final existing = await _supabase
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (existing == null) {
      final meta = authUser.userMetadata ?? {};
      final nama = meta['full_name'] as String? ??
          meta['name'] as String? ??
          authUser.email?.split('@').first ??
          'User';

      await _supabase.from('users').insert({
        'id'            : authUser.id,
        'nama'          : nama,
        'nim'           : '',
        'jurusan'       : '',
        'email'         : authUser.email ?? '',
        'total_poin'    : 0,
        'poin_masuk'    : 0,
        'poin_keluar'   : 0,
        'rank'          : 999,
        'jumlah_laporan': 0,
        'level'         : 'Pemula',
        'foto_url'      : meta['avatar_url'] as String?,
      });
    }

    _currentUser = await _fetchUser(authUser.id);
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

  Future<String?> _resolveEmail(String emailOrNim) async {
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
    final msg = error.toString().toLowerCase();

    if (msg.contains('users_nim_key')) {
      return 'Data yang dimasukkan sudah terdaftar';
    }
    if (msg.contains('users_email_key')) {
      return 'Email sudah digunakan';
    }
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return error.message;

    return defaultMessage;
  }

  static const _mockUser = UserModel(
    uid: '0', nama: 'Guest', nim: '0', jurusan: '-',
    email: '', totalPoin: 0, poinMasuk: 0, poinKeluar: 0,
    rank: 0, jumlahLaporan: 0, level: 'Pemula',
  );
}
