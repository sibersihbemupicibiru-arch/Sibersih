// ============================================================
// POIN HISTORY MODEL
// ============================================================

class PoinHistoryModel {
  final String icon;
  final String title;
  final String date;
  final int poin;
  final String type; // 'masuk' | 'keluar'

  const PoinHistoryModel({
    required this.icon,
    required this.title,
    required this.date,
    required this.poin,
    required this.type,
  });

  factory PoinHistoryModel.fromMap(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'masuk';
    return PoinHistoryModel(
      icon: data['icon'] as String? ?? (type == 'masuk' ? '💰' : '🛒'),
      title: data['title'] as String? ??
          (type == 'masuk' ? 'Poin Masuk' : 'Tukar Poin'),
      date: data['tanggal'] as String? ?? '',
      poin: (data['poin'] as num?)?.toInt() ?? 0,
      type: type,
    );
  }

  Map<String, dynamic> toMap() => {
        'icon': icon,
        'title': title,
        'tanggal': date,
        'poin': poin,
        'type': type,
      };
}

/// Model untuk agregasi poin per bulan (dipakai di chart).
class BulananPoinModel {
  final String bulan;
  final int poin;

  const BulananPoinModel({required this.bulan, required this.poin});

  factory BulananPoinModel.fromMap(Map<String, dynamic> data) =>
      BulananPoinModel(
        bulan: data['bulan'] as String? ?? '',
        poin: (data['poin'] as num?)?.toInt() ?? 0,
      );
}
