import 'package:flutter/material.dart';
import '../../app_tokens.dart';
import '../../services/supabase_service.dart';
import 'admin_layout.dart';

class AdminFaqsPage extends StatefulWidget {
  const AdminFaqsPage({super.key});

  @override
  State<AdminFaqsPage> createState() => _AdminFaqsPageState();
}

class _AdminFaqsPageState extends State<AdminFaqsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _faqs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await SupabaseService.instance.getFaqs();
    if (!mounted) return;
    setState(() {
      _faqs = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _saveFaq({String? id}) async {
    final pertCtrl = TextEditingController();
    final jawCtrl = TextEditingController();
    final urutanCtrl = TextEditingController();

    if (id != null) {
      final current = _faqs.firstWhere(
        (item) => item['id'].toString() == id,
        orElse: () => {},
      );
      if (current.isNotEmpty) {
        pertCtrl.text = current['pertanyaan']?.toString() ?? '';
        jawCtrl.text = current['jawaban']?.toString() ?? '';
        urutanCtrl.text = current['urutan']?.toString() ?? '0';
      }
    } else {
      urutanCtrl.text = '${_faqs.length + 1}';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(id == null ? 'Tambah FAQ' : 'Edit FAQ',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pertCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Pertanyaan',
                  hintText: 'Masukkan pertanyaan...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jawCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Jawaban',
                  hintText: 'Masukkan jawaban...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urutanCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Urutan Tampil',
                  helperText: 'Angka lebih kecil tampil lebih dulu',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SibersihColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final pertanyaan = pertCtrl.text.trim();
    final jawaban = jawCtrl.text.trim();
    final urutanStr = urutanCtrl.text.trim();

    if (pertanyaan.isEmpty || jawaban.isEmpty) {
      _showSnack('Pertanyaan dan jawaban wajib diisi');
      return;
    }

    final urutan = int.tryParse(urutanStr) ?? 0;

    final saved = await SupabaseService.instance.saveFaqItem(
      id: id,
      pertanyaan: pertanyaan,
      jawaban: jawaban,
      urutan: urutan,
    );

    if (!mounted) return;
    if (saved) {
      _showSnack('FAQ berhasil disimpan');
      await _loadData();
    } else {
      _showSnack('Gagal menyimpan FAQ');
    }
  }

  Future<void> _deleteFaq(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus FAQ'),
        content: const Text('Yakin ingin menghapus FAQ ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleted = await SupabaseService.instance.deleteFaqItem(id);
    if (!mounted) return;
    if (deleted) {
      _showSnack('FAQ berhasil dihapus');
      await _loadData();
    } else {
      _showSnack('Gagal menghapus FAQ');
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
      title: 'Kelola FAQ',
      currentRoute: '/admin/faqs',
      onRefresh: _loadData,
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: SibersihColors.primary),
              ),
            )
          : AdminPanel(
              title: 'FAQ Aplikasi (${_faqs.length})',
              trailing: ElevatedButton.icon(
                onPressed: () => _saveFaq(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SibersihColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              child: _faqs.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Belum ada FAQ. Tambahkan FAQ untuk panduan user.'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _faqs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final faq = _faqs[index];
                        return Container(
                           padding: const EdgeInsets.all(14),
                           decoration: BoxDecoration(
                             border: Border.all(color: Colors.grey.shade200),
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Container(
                                 width: 36,
                                 height: 36,
                                 alignment: Alignment.center,
                                 decoration: BoxDecoration(
                                   color: SibersihColors.primary.withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: Text(
                                   '${faq['urutan'] ?? index + 1}',
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w800,
                                     color: SibersihColors.primary,
                                   ),
                                 ),
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       faq['pertanyaan']?.toString() ?? '-',
                                       style: const TextStyle(
                                         fontWeight: FontWeight.w800,
                                         fontSize: 14,
                                         color: Color(0xFF2E2E4A),
                                       ),
                                     ),
                                     const SizedBox(height: 6),
                                     Text(
                                       faq['jawaban']?.toString() ?? '-',
                                       style: TextStyle(
                                         color: Colors.grey.shade600,
                                         fontSize: 13,
                                         height: 1.4,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                               const SizedBox(width: 8),
                               IconButton(
                                 onPressed: () => _saveFaq(id: faq['id'].toString()),
                                 icon: const Icon(Icons.edit_rounded, size: 20),
                                 constraints: const BoxConstraints(),
                                 padding: const EdgeInsets.all(8),
                               ),
                               IconButton(
                                 onPressed: () => _deleteFaq(faq['id'].toString()),
                                 icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                                 constraints: const BoxConstraints(),
                                 padding: const EdgeInsets.all(8),
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
