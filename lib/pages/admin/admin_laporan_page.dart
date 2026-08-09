import 'package:flutter/material.dart';
import '../../app_tokens.dart';
import '../../services/supabase_service.dart';
import 'admin_layout.dart';

class AdminLaporanPage extends StatefulWidget {
  const AdminLaporanPage({super.key});

  @override
  State<AdminLaporanPage> createState() => _AdminLaporanPageState();
}

class _AdminLaporanPageState extends State<AdminLaporanPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _laporans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await SupabaseService.instance.getAdminLaporans();
    if (!mounted) return;
    setState(() {
      _laporans = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _handleStatusChange(String laporanId, String status, {String? userId}) async {
    final ok = await SupabaseService.instance.updateLaporanStatus(
      laporanId: laporanId,
      status: status,
      poinDiterima: status == 'diverifikasi' ? 100 : null,
      userId: userId,
    );
    if (!mounted) return;
    if (ok) {
      _showSnack(status == 'diverifikasi' 
          ? 'Laporan berhasil diverifikasi (+100 Poin ke User)' 
          : 'Laporan telah ditolak');
      await _loadData();
    } else {
      _showSnack('Gagal memperbarui status laporan');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year • $hour:$minute';
    } catch (_) {
      return rawDate;
    }
  }

  Map<String, dynamic>? _extractUserMap(dynamic rawUsers) {
    if (rawUsers is Map) {
      return Map<String, dynamic>.from(rawUsers);
    }
    if (rawUsers is List && rawUsers.isNotEmpty && rawUsers.first is Map) {
      return Map<String, dynamic>.from(rawUsers.first as Map);
    }
    return null;
  }

  void _showDetailModal(Map<String, dynamic> item) {
    try {
      final userMap = _extractUserMap(item['users']);
      final userName = (userMap?['nama']?.toString().trim().isNotEmpty == true)
          ? userMap!['nama'].toString()
          : (item['nama_pelapor']?.toString().trim().isNotEmpty == true
              ? item['nama_pelapor'].toString()
              : 'User Sibersih');
      final userEmail = userMap?['email']?.toString() ?? '-';
      final userNim = userMap?['nim']?.toString() ?? '-';
      final userJurusan = userMap?['jurusan']?.toString() ?? '-';
      final userFoto = userMap?['foto_url']?.toString();
      final userId = userMap?['id']?.toString() ?? item['user_id']?.toString();

      final status = item['status']?.toString() ?? 'pending';
      final badgeColor = status == 'diverifikasi'
          ? Colors.green
          : status == 'ditolak'
              ? Colors.red
              : Colors.orange;

      final rawFotoUrls = item['foto_urls'];
      List<String> fotoUrls = [];
      if (rawFotoUrls is List) {
        fotoUrls = rawFotoUrls
            .map((e) => e?.toString() ?? '')
            .where((e) => e.trim().isNotEmpty)
            .toList();
      } else if (rawFotoUrls is String && rawFotoUrls.isNotEmpty) {
        fotoUrls = [rawFotoUrls];
      }

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 550,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Modal
                Row(
                  children: [
                    const Icon(Icons.assignment_rounded, color: SibersihColors.primary, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Detail Laporan Sampah',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Content Modal
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- INFORMASI PELAPOR (USER) ---
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: SibersihColors.primary.withOpacity(0.15),
                                backgroundImage: userFoto != null && userFoto.isNotEmpty
                                    ? NetworkImage(userFoto)
                                    : null,
                                child: (userFoto == null || userFoto.isEmpty)
                                    ? Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          color: SibersihColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      userEmail,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (userNim != '-' || userJurusan != '-') ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'NIM: $userNim ${userJurusan != '-' ? '• $userJurusan' : ''}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --- FOTO BUKTI ---
                        const Text(
                          'Foto Bukti Sampah:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        if (fotoUrls.isEmpty)
                          Container(
                            height: 120,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade400, size: 36),
                                const SizedBox(height: 4),
                                Text(
                                  'Tidak ada foto bukti',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 160,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: fotoUrls.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, idx) {
                                final url = fotoUrls[idx];
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => Dialog(
                                          child: Image.network(url, fit: BoxFit.contain),
                                        ),
                                      );
                                    },
                                    child: Image.network(
                                      url,
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 160,
                                        height: 160,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image_rounded),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 16),

                        // --- DETAIL INFORMASI ---
                        _detailRow(Icons.category_rounded, 'Kategori', item['kategori']?.toString().toUpperCase() ?? '-'),
                        _detailRow(Icons.straighten_rounded, 'Ukuran', item['ukuran']?.toString().toUpperCase() ?? '-'),
                        _detailRow(Icons.scale_rounded, 'Berat', item['berat'] != null ? '${item['berat']} gram' : '-'),
                        _detailRow(Icons.location_on_rounded, 'Lokasi Pembuangan', item['lokasi']?.toString() ?? '-'),
                        _detailRow(Icons.access_time_rounded, 'Waktu Laporan', _formatDate(item['tanggal']?.toString())),
                        _detailRow(Icons.stars_rounded, 'Poin Diterima', '${item['poin_diterima'] ?? (status == 'diverifikasi' ? 100 : 0)} Poin'),

                        const SizedBox(height: 12),
                        const Text(
                          'Catatan Pelapor:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (item['catatan']?.toString().trim().isNotEmpty == true)
                                ? item['catatan'].toString()
                                : '(Tidak ada catatan)',
                            style: TextStyle(
                              fontStyle: (item['catatan']?.toString().trim().isNotEmpty == true)
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              color: Colors.grey.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                    const SizedBox(width: 8),
                    if (status != 'diverifikasi')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleStatusChange(item['id'].toString(), 'diverifikasi', userId: userId);
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Verifikasi (+100 Poin)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (status != 'ditolak') ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleStatusChange(item['id'].toString(), 'ditolak', userId: userId);
                        },
                        icon: const Icon(Icons.cancel_rounded, size: 18),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('_showDetailModal Error: $e\n$stackTrace');
      _showSnack('Terjadi kesalahan saat membuka detail: $e');
    }
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SibersihColors.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Kelola Laporan',
      currentRoute: '/admin/laporan',
      onRefresh: _loadData,
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: SibersihColors.primary),
              ),
            )
          : AdminPanel(
              title: 'Daftar Laporan Sampah (${_laporans.length})',
              child: _laporans.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Belum ada laporan dari user.'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _laporans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _laporans[index];
                        final userMap = _extractUserMap(item['users']);
                        final userName = (userMap?['nama']?.toString().trim().isNotEmpty == true)
                            ? userMap!['nama'].toString()
                            : (item['nama_pelapor']?.toString().trim().isNotEmpty == true
                                ? item['nama_pelapor'].toString()
                                : 'User Sibersih');
                        final userEmail = userMap?['email']?.toString() ?? '';
                        final userId = userMap?['id']?.toString() ?? item['user_id']?.toString();

                        final status = item['status']?.toString() ?? 'pending';
                        final badgeColor = status == 'diverifikasi'
                            ? Colors.green
                            : status == 'ditolak'
                                ? Colors.red
                                : Colors.orange;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: SibersihColors.primary.withOpacity(0.12),
                                    child: Text(
                                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        color: SibersihColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (userEmail.isNotEmpty)
                                          Text(
                                            userEmail,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: badgeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Kategori: ${item['kategori']?.toString().toUpperCase() ?? '-'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatDate(item['tanggal']?.toString()),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lokasi: ${item['lokasi'] ?? '-'} ${item['berat'] != null ? '• ${item['berat']} gram' : ''}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showDetailModal(item),
                                    icon: const Icon(Icons.visibility_rounded, size: 16),
                                    label: const Text('Lihat Detail'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: SibersihColors.primary,
                                      side: const BorderSide(color: SibersihColors.primary),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (status != 'diverifikasi') ...[
                                    ElevatedButton(
                                      onPressed: () => _handleStatusChange(
                                        item['id'].toString(), 
                                        'diverifikasi',
                                        userId: userId,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text('Verifikasi'),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (status != 'ditolak')
                                    OutlinedButton(
                                      onPressed: () => _handleStatusChange(
                                        item['id'].toString(), 
                                        'ditolak',
                                        userId: userId,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text('Tolak'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
