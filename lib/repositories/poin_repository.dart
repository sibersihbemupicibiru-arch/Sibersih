// ============================================================
// POIN REPOSITORY
// Mengelola riwayat poin, agregasi bulanan, reward items,
// dan quotes.
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/poin_history_model.dart';
import '../services/supabase_client.dart';

class PoinRepository {
  // --- Singleton -------------------------------------------
  PoinRepository._();
  static final PoinRepository instance = PoinRepository._();

  final _supabase = SupabaseClientProvider.instance.client;

  // -----------------------------------------------------------
  //  POIN HISTORY
  // -----------------------------------------------------------

  Future<List<PoinHistoryModel>> getPoinMasukHistory() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase
          .from('poin_history')
          .select()
          .eq('user_id', authUser.id)
          .eq('type', 'masuk')
          .order('tanggal');
      return data.map((e) => PoinHistoryModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<PoinHistoryModel>> getPoinKeluarHistory() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase
          .from('poin_history')
          .select()
          .eq('user_id', authUser.id)
          .eq('type', 'keluar')
          .order('tanggal');
      return data.map((e) => PoinHistoryModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Poin per bulan dari Jan s/d bulan berjalan, bulan tanpa data = 0.
  Future<List<BulananPoinModel>> getBulananPoin() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return [];
    try {
      final List<dynamic> data = await _supabase
          .from('poin_history')
          .select('tanggal, poin, type')
          .eq('user_id', authUser.id)
          .eq('type', 'masuk');

      // Map bulan → total poin masuk
      final monthMap = <int, int>{};
      for (var row in data) {
        final date = DateTime.tryParse(row['tanggal'] ?? '');
        if (date != null) {
          monthMap[date.month] = (monthMap[date.month] ?? 0) +
              ((row['poin'] as num?)?.toInt() ?? 0);
        }
      }

      // Kembalikan dari Jan (1) sampai bulan saat ini, isi 0 jika tidak ada
      final now = DateTime.now();
      return List.generate(now.month, (i) {
        final m = i + 1;
        return BulananPoinModel(bulan: _monthName(m), poin: monthMap[m] ?? 0);
      });
    } catch (e) {
      return [];
    }
  }

  /// Total poin masuk & keluar pada bulan berjalan.
  Future<Map<String, int>> getPoinBulanIni() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return {'masuk': 0, 'keluar': 0};
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1).toIso8601String();
      final List<dynamic> data = await _supabase
          .from('poin_history')
          .select('poin, type')
          .eq('user_id', authUser.id)
          .gte('tanggal', firstDay);

      int masuk = 0, keluar = 0;
      for (var row in data) {
        final poin = (row['poin'] as num?)?.toInt() ?? 0;
        if (row['type'] == 'masuk') masuk += poin;
        if (row['type'] == 'keluar') keluar += poin;
      }
      return {'masuk': masuk, 'keluar': keluar};
    } catch (e) {
      return {'masuk': 0, 'keluar': 0};
    }
  }

  // -----------------------------------------------------------
  //  REWARD ITEMS
  // -----------------------------------------------------------

  Future<List<Map<String, dynamic>>> getRewardItems() async {
    try {
      final List<dynamic> data = await _supabase
          .from('reward_items')
          .select('id, name, description, image_url, points, color, pickup_location, pickup_time')
          .order('points');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // -----------------------------------------------------------
  //  QUOTES (motivasi)
  // -----------------------------------------------------------

  Future<List<Map<String, String>>> getQuotes() async {
    try {
      final List<dynamic> data =
          await _supabase.from('quotes').select().order('order');
      return data
          .map((e) => {
                'text'  : e['text'].toString(),
                'author': e['author'].toString(),
              })
          .toList();
    } catch (e) {
      return [
        {'text': '"Satu sampah, satu masalah. Bersihkan!"', 'author': 'Sibersih'}
      ];
    }
  }

  // -----------------------------------------------------------
  //  REDEMPTION (penukaran poin)
  // -----------------------------------------------------------

  Future<bool> redeemReward({
    required int points,
    required String title,
    required String icon,
  }) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return false;

    try {
      // 1. Ambil poin terkini user
      final userData = await _supabase
          .from('users')
          .select('total_poin, poin_keluar')
          .eq('id', authUser.id)
          .single();

      final currentPoin = (userData['total_poin'] as num?)?.toInt() ?? 0;
      final currentKeluar = (userData['poin_keluar'] as num?)?.toInt() ?? 0;

      if (currentPoin < points) return false;

      // 2. Update total_poin dan poin_keluar di tabel users
      await _supabase.from('users').update({
        'total_poin': currentPoin - points,
        'poin_keluar': currentKeluar + points,
      }).eq('id', authUser.id);

      // 3. Catat di tabel poin_history
      await _supabase.from('poin_history').insert({
        'user_id': authUser.id,
        'type': 'keluar',
        'icon': icon,
        'title': 'Tukar: $title',
        'poin': points,
        'tanggal': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('redeemReward error: $e');
      return false;
    }
  }

  // -----------------------------------------------------------
  //  PRIVATE HELPERS
  // -----------------------------------------------------------

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}
