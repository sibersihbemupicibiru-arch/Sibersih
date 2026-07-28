// ============================================================
// PANDUAN REPOSITORY
// Mengambil data panduan dan FAQ dari Supabase.
// ============================================================

import '../models/panduan_model.dart';
import '../models/faq_model.dart';
import '../services/supabase_client.dart';

class PanduanRepository {
  PanduanRepository._();
  static final PanduanRepository instance = PanduanRepository._();

  final _supabase = SupabaseClientProvider.instance.client;

  /// Ambil semua panduan, diurutkan berdasarkan kolom `nomor`.
  Future<List<PanduanModel>> fetchPanduan() async {
    try {
      final data = await _supabase
          .from('panduan')
          .select()
          .order('nomor', ascending: true);

      if (data == null) return [];
      return (data as List)
          .map((e) => PanduanModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Ambil semua FAQ, diurutkan berdasarkan kolom `urutan`.
  Future<List<FaqModel>> fetchFAQ() async {
    try {
      final data = await _supabase
          .from('faq')
          .select()
          .order('urutan', ascending: true);

      if (data == null) return [];
      return (data as List)
          .map((e) => FaqModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
