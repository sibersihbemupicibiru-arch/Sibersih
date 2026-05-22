// ============================================================
// LAPORAN MODEL — siap dihubungkan ke Firestore
// Collection path: /laporans/{laporanId}
// ============================================================

enum StatusLaporan { pending, diverifikasi, ditolak }

class LaporanModel {
  final String id;
  final String userId;
  final String namaPelapor;
  final String nim;
  final List<String> fotoUrls; // Firebase Storage URLs
  final double berat; // dalam gram
  final String lokasi;
  final String catatan;
  final int poinDiterima;
  final StatusLaporan status;
  final DateTime tanggal;

  const LaporanModel({
    required this.id,
    required this.userId,
    required this.namaPelapor,
    required this.nim,
    required this.fotoUrls,
    required this.berat,
    required this.lokasi,
    required this.catatan,
    required this.poinDiterima,
    required this.status,
    required this.tanggal,
  });

  // TODO: Uncomment saat Firebase sudah diintegrasikan
  // factory LaporanModel.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return LaporanModel.fromMap(data, doc.id);
  // }

  factory LaporanModel.fromMap(Map<String, dynamic> data, String id) {
    return LaporanModel(
      id: id,
      userId: data['userId'] as String? ?? data['user_id'] as String? ?? '',
      namaPelapor: data['namaPelapor'] as String? ?? data['nama_pelapor'] as String? ?? '',
      nim: data['nim'] as String? ?? '',
      fotoUrls: List<String>.from(data['fotoUrls'] as List? ?? data['foto_urls'] as List? ?? []),
      berat: (data['berat'] as num? ?? data['weight'] as num?)?.toDouble() ?? 0.0,
      lokasi: data['lokasi'] as String? ?? data['location'] as String? ?? '',
      catatan: data['catatan'] as String? ?? data['note'] as String? ?? '',
      poinDiterima: (data['poinDiterima'] as num? ?? data['poin_diterima'] as num?)?.toInt() ?? 0,
      status: StatusLaporan.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => StatusLaporan.pending,
      ),
      tanggal: data['tanggal'] != null
          ? DateTime.tryParse(data['tanggal'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'nama_pelapor': namaPelapor,
        'nim': nim,
        'foto_urls': fotoUrls,
        'berat': berat,
        'lokasi': lokasi,
        'catatan': catatan,
        'poin_diterima': poinDiterima,
        'status': status.name,
        'tanggal': tanggal.toIso8601String(),
      };

  String get beratFormatted {
    if (berat >= 1000) return '${(berat / 1000).toStringAsFixed(1)} kg';
    return '${berat.toInt()} gram';
  }

  String get statusLabel {
    switch (status) {
      case StatusLaporan.pending:
        return 'Menunggu';
      case StatusLaporan.diverifikasi:
        return 'Diverifikasi';
      case StatusLaporan.ditolak:
        return 'Ditolak';
    }
  }
}
