// ============================================================
// APP CONFIG
// Semua konstanta konfigurasi aplikasi (URL, keys, env vars)
// dikumpulkan di sini agar tidak tersebar di berbagai file.
// ============================================================

abstract final class AppConfig {
  // ── Supabase ─────────────────────────────────────────────
  static const String supabaseUrl =
      'https://ciaykezzojnksqlsioqh.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NTgwNjIsImV4cCI6MjA5MjMzNDA2Mn0.vIeGdCi2d10Uds_wuJYfyLR2stjVjqZyFsyMRQ2DOCY';

  static const String supabaseServiceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw';

  // ── Auth callback ─────────────────────────────────────────
  /// Deep-link scheme untuk native app (Android/iOS).
  static const String authCallbackScheme = 'com.sibersih.app';
  static const String authCallbackHost = 'login-callback';
  static const String authCallbackUrl =
      '$authCallbackScheme://$authCallbackHost';

  // ── Edge Functions ────────────────────────────────────────
  static const String geminiScanFunction = 'gemini-scan';
  static const String submitLaporanFunction = 'submit-laporan';
  static const String redeemRewardFunction = 'redeem-reward';

  // ── Storage buckets ───────────────────────────────────────
  static const String bucketProfilePhotos = 'profile_photos';
  static const String bucketLaporanPhotos = 'laporan_photos';

  // ── Misc ──────────────────────────────────────────────────
  static const String defaultLokasi = 'Gedung B lt 1';
}
