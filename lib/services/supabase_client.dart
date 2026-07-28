// ============================================================
// SUPABASE CLIENT
// Thin singleton wrapper — hanya expose SupabaseClient.
// Semua repository import dari sini, bukan langsung dari
// supabase_flutter, supaya mudah di-mock saat testing.
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientProvider {
  SupabaseClientProvider._();
  static final SupabaseClientProvider instance = SupabaseClientProvider._();

  SupabaseClient get client => Supabase.instance.client;
}
