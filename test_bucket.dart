import 'package:supabase/supabase.dart';
void main() async {
  final client = SupabaseClient(
    'https://ciaykezzojnksqlsioqh.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw'
  );
  try {
    final buckets = await client.storage.listBuckets();
    final bucketIds = buckets.map((b) => b.id).toList();
    print('Existing buckets: $bucketIds');
    
    if (!bucketIds.contains('reward_images')) {
      await client.storage.createBucket('reward_images', const BucketOptions(public: true));
      print('Created bucket reward_images');
    } else {
      print('Bucket reward_images already exists');
    }
  } catch(e) {
    print('Error: $e');
  }
}
