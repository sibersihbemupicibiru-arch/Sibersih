import urllib.request
import json

url_upload = 'https://ciaykezzojnksqlsioqh.supabase.co/storage/v1/object/laporan_photos/rewards/test_file.txt'
headers = {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpYXlrZXp6b2pua3NxbHNpb3FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njc1ODA2MiwiZXhwIjoyMDkyMzM0MDYyfQ.glV4UI0HVHc4-id_uzFIeEqTQHuwTakOLbMNj2CnBfw',
    'Content-Type': 'text/plain',
}

data = b"Hello world from Python test upload"
req = urllib.request.Request(url_upload, data=data, headers=headers, method='POST')
try:
    with urllib.request.urlopen(req) as res:
        print('Upload Success:', res.read().decode('utf-8'))
except Exception as e:
    if hasattr(e, 'read'):
        print('Upload Error body:', e.read().decode('utf-8'))
    else:
        print('Upload Error:', e)
