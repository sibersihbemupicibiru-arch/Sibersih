import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://ciaykezzojnksqlsioqh.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw'
  );

  print('--- CHECKING TABLES ---');
  for (var table in ['faqs', 'faq', 'panduans', 'panduan', 'quotes', 'reward_items']) {
    try {
      final res = await client.from(table).select().limit(5);
      print('Table "$table": SUCCESS (found ${res.length} rows)');
      if (res.isNotEmpty) {
        print('  Sample row: ${res.first}');
      }
    } catch (e) {
      print('Table "$table": ERROR ($e)');
    }
  }
}
