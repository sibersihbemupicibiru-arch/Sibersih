// ============================================================
// PANDUAN MODEL
// Representasi satu panduan dari tabel `panduan` di Supabase.
// ============================================================

class PanduanModel {
  final int id;
  final int nomor;
  final String emoji;
  final String title;
  final String description;
  final List<String> tips;
  final List<String> gambarUrls;

  const PanduanModel({
    required this.id,
    required this.nomor,
    required this.emoji,
    required this.title,
    required this.description,
    required this.tips,
    required this.gambarUrls,
  });

  factory PanduanModel.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return PanduanModel(
      id: (map['id'] as num).toInt(),
      nomor: (map['nomor'] as num).toInt(),
      emoji: map['emoji'] as String? ?? '📋',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      tips: parseList(map['tips']),
      gambarUrls: parseList(map['gambar_urls']),
    );
  }

  String get nomorStr => nomor.toString().padLeft(2, '0');
}
