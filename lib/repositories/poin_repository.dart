// ============================================================
// POIN REPOSITORY
// Mengelola riwayat poin, agregasi bulanan, reward items,
// dan quotes.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
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
      final adminClient = SupabaseClient(
        'https://ciaykezzojnksqlsioqh.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw'
      );
      final List<dynamic> data = await adminClient
          .from('reward_items')
          .select()
          .order('points');
      return List<Map<String, dynamic>>.from(data);
    } catch (e, stackTrace) {
      debugPrint('getRewardItems error: $e\n$stackTrace');
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
    required int rewardId,
  }) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return false;

    try {
      final response = await _supabase.functions.invoke(
        AppConfig.redeemRewardFunction,
        body: {
          'reward_id': rewardId,
        },
      );

      if (response.status == 200) {
        return true;
      } else {
        final errorMsg = response.data is Map ? response.data['error'] : 'Unknown error';
        debugPrint('redeemReward error status ${response.status}: $errorMsg');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('redeemReward exception: $e\n$stackTrace');
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
