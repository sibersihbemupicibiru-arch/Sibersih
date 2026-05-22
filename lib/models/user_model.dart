// ============================================================
// USER MODEL — siap dihubungkan ke Firestore
// Collection path: /users/{uid}
// ============================================================

class UserModel {
  final String uid;
  final String nama;
  final String nim;
  final String jurusan;
  final String email;
  final int totalPoin;
  final int poinMasuk;
  final int poinKeluar;
  final int rank;
  final int jumlahLaporan;
  final String level; // Pemula / Aktif / Emas / Platinum
  final String? fotoUrl; // Firebase Storage URL

  const UserModel({
    required this.uid,
    required this.nama,
    required this.nim,
    required this.jurusan,
    required this.email,
    required this.totalPoin,
    required this.poinMasuk,
    required this.poinKeluar,
    required this.rank,
    required this.jumlahLaporan,
    required this.level,
    this.fotoUrl,
  });

  // TODO: Uncomment saat Firebase sudah diintegrasikan
  // factory UserModel.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return UserModel.fromMap(data, doc.id);
  // }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      nama: data['nama'] as String? ?? '',
      nim: data['nim'] as String? ?? '',
      jurusan: data['jurusan'] as String? ?? '',
      email: data['email'] as String? ?? '',
      totalPoin: (data['totalPoin'] as num? ?? data['total_poin'] as num?)?.toInt() ?? 0,
      poinMasuk: (data['poinMasuk'] as num? ?? data['poin_masuk'] as num?)?.toInt() ?? 0,
      poinKeluar: (data['poinKeluar'] as num? ?? data['poin_keluar'] as num?)?.toInt() ?? 0,
      rank: (data['rank'] as num?)?.toInt() ?? 999,
      jumlahLaporan: (data['jumlahLaporan'] as num? ?? data['jumlah_laporan'] as num?)?.toInt() ?? 0,
      level: data['level'] as String? ?? 'Pemula',
      fotoUrl: data['fotoUrl'] as String? ?? data['foto_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'nama': nama,
        'nim': nim,
        'jurusan': jurusan,
        'email': email,
        'total_poin': totalPoin,
        'poin_masuk': poinMasuk,
        'poin_keluar': poinKeluar,
        'rank': rank,
        'jumlah_laporan': jumlahLaporan,
        'level': level,
        'foto_url': fotoUrl,
      };

  UserModel copyWith({
    String? uid,
    String? nama,
    String? nim,
    String? jurusan,
    String? email,
    int? totalPoin,
    int? poinMasuk,
    int? poinKeluar,
    int? rank,
    int? jumlahLaporan,
    String? level,
    String? fotoUrl,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        nama: nama ?? this.nama,
        nim: nim ?? this.nim,
        jurusan: jurusan ?? this.jurusan,
        email: email ?? this.email,
        totalPoin: totalPoin ?? this.totalPoin,
        poinMasuk: poinMasuk ?? this.poinMasuk,
        poinKeluar: poinKeluar ?? this.poinKeluar,
        rank: rank ?? this.rank,
        jumlahLaporan: jumlahLaporan ?? this.jumlahLaporan,
        level: level ?? this.level,
        fotoUrl: fotoUrl ?? this.fotoUrl,
      );
}
