import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://ciaykezzojnksqlsioqh.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw'
  );

  print('--- TESTING LAPORAN WITH USER DATA ---');
  try {
    final laporans = await client.from('laporans').select('*, users(nama, email, nim)').order('tanggal', ascending: false);
    print('Join select success: ${laporans.length} rows');
    if (laporans.isNotEmpty) {
      print('First row joined: ${laporans.first}');
    }
  } catch (e) {
    print('Join select error: $e');
  }
}
