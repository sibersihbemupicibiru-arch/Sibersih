import 'package:flutter/material.dart';
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

  Future<void> _handleStatusChange(String laporanId, String status) async {
    final ok = await SupabaseService.instance.updateLaporanStatus(
      laporanId: laporanId,
      status: status,
      poinDiterima: status == 'diverifikasi' ? 100 : null,
    );
    if (!mounted) return;
    if (ok) {
      _showSnack('Status laporan berhasil diperbarui');
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
                child: CircularProgressIndicator(),
              ),
            )
          : AdminPanel(
              title: 'Daftar Laporan (${_laporans.length})',
              child: _laporans.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Belum ada laporan.'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _laporans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _laporans[index];
                        final status = item['status']?.toString() ?? 'pending';
                        final badgeColor = status == 'diverifikasi'
                            ? Colors.green
                            : status == 'ditolak'
                                ? Colors.red
                                : Colors.orange;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['nama_pelapor']?.toString() ?? 'Pelapor',
                                      style: const TextStyle(fontWeight: FontWeight.w800),
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
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item['lokasi'] ?? '-'} • ${item['berat'] ?? 0} gram',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(item['catatan']?.toString() ?? '-'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (status != 'diverifikasi')
                                    ElevatedButton(
                                      onPressed: () => _handleStatusChange(
                                          item['id'].toString(), 'diverifikasi'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      child: const Text('Verifikasi'),
                                    ),
                                  if (status != 'ditolak')
                                    OutlinedButton(
                                      onPressed: () => _handleStatusChange(
                                          item['id'].toString(), 'ditolak'),
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
