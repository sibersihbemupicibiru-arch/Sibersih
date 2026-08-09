// ============================================================
// FAQ MODEL
// Representasi satu FAQ dari tabel `faq` di Supabase.
// ============================================================

class FaqModel {
  final int id;
  final int urutan;
  final String pertanyaan;
  final String jawaban;

  const FaqModel({
    required this.id,
    required this.urutan,
    required this.pertanyaan,
    required this.jawaban,
  });

  factory FaqModel.fromMap(Map<String, dynamic> map) {
    return FaqModel(
      id: (map['id'] as num).toInt(),
      urutan: (map['urutan'] as num).toInt(),
      pertanyaan: map['pertanyaan'] as String? ?? '',
      jawaban: map['jawaban'] as String? ?? '',
    );
  }
}
