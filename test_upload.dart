import 'dart:typed_data';
import 'package:supabase/supabase.dart';
void main() async {
  final client = SupabaseClient(
    'https://ciaykezzojnksqlsioqh.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw'
  );
  try {
    // Note: client.rpc('run_sql') will only work if we created a custom run_sql function on the db.
    // Instead, since the anon key is actually a service_role key in this app,
    // if uploads STILL fail, it means we must upload using the service_role client or fix the RLS.
    // Let's try to upload a dummy file to the bucket using this client to see what error it gives!
    
    await client.storage.from('reward_images').uploadBinary(
      'rewards/test.txt', 
      Uint8List.fromList([1, 2, 3]),
      fileOptions: const FileOptions(upsert: true)
    );
    print('Upload successful');
  } catch(e) {
    print('Upload failed: $e');
  }
}
