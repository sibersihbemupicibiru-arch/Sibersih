import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://ciaykezzojnksqlsioqh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw',
  );

  final client = Supabase.instance.client;

  // 1. Try to insert
  print('\n--- 1. Testing insert into reward_items ---');
  try {
    final res = await client.from('reward_items').insert({
      'name': 'Test Reward',
      'points': 500,
      'description': 'Temporary test reward',
    }).select().maybeSingle();
    print('Insert Success: $res');
    
    if (res != null) {
      final newId = res['id'];
      
      // 2. Try to update
      print('\n--- 2. Testing update reward_items ---');
      try {
        final updateRes = await client.from('reward_items').update({
          'name': 'Updated Test Reward',
        }).eq('id', newId).select().maybeSingle();
        print('Update Success: $updateRes');
      } catch (e) {
        print('Update Error: $e');
      }

      // 3. Try to delete
      print('\n--- 3. Testing delete reward_items ---');
      try {
        final deleteRes = await client.from('reward_items').delete().eq('id', newId).select();
        print('Delete Success: $deleteRes');
      } catch (e) {
        print('Delete Error: $e');
      }
    }
  } catch (e) {
    print('Insert Error: $e');
  }

  // 4. Try upload
  print('\n--- 4. Testing upload to laporan_photos ---');
  try {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final path = 'rewards/test_file.txt';
    await client.storage.from('laporan_photos').uploadBinary(path, bytes,
        fileOptions: const FileOptions(contentType: 'text/plain', upsert: true));
    final url = client.storage.from('laporan_photos').getPublicUrl(path);
    print('Upload Success: $url');
  } catch (e) {
    print('Upload Error: $e');
  }
}
