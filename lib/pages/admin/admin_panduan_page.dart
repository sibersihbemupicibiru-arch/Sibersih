import 'package:flutter/material.dart';
import '../../app_tokens.dart';
import '../../services/supabase_service.dart';
import 'admin_layout.dart';

class AdminPanduanPage extends StatefulWidget {
  const AdminPanduanPage({super.key});

  @override
  State<AdminPanduanPage> createState() => _AdminPanduanPageState();
}

class _AdminPanduanPageState extends State<AdminPanduanPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _panduans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await SupabaseService.instance.getPanduans();
    if (!mounted) return;
    setState(() {
      _panduans = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _savePanduan({String? id}) async {
    final nomorCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final tipsCtrl = TextEditingController();
    final urlsCtrl = TextEditingController();

    if (id != null) {
      final current = _panduans.firstWhere(
        (item) => item['id'].toString() == id,
        orElse: () => {},
      );
      if (current.isNotEmpty) {
        nomorCtrl.text = current['nomor']?.toString() ?? '0';
        emojiCtrl.text = current['emoji']?.toString() ?? '';
        titleCtrl.text = current['title']?.toString() ?? '';
        descCtrl.text = current['description']?.toString() ?? '';
        
        final List<dynamic> tipsList = current['tips'] ?? [];
        tipsCtrl.text = tipsList.join('\n');

        final List<dynamic> urlsList = current['gambar_urls'] ?? [];
        urlsCtrl.text = urlsList.join('\n');
      }
    } else {
      nomorCtrl.text = '${_panduans.length + 1}';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(id == null ? 'Tambah Panduan' : 'Edit Panduan',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomorCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nomor Langkah',
                  hintText: 'Misal: 1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Emoji Langkah',
                  hintText: 'Misal: 🔐',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Langkah',
                  hintText: 'Misal: Daftar & Masuk Akun',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Masukkan penjelasan lengkap langkah ini...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tipsCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Tips / Petunjuk Detail',
                  hintText: 'Gunakan email resmi\nNIM sesuai KTM\nTulis satu per baris...',
                  helperText: 'Tulis satu tips per baris (tekan Enter untuk baris baru)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'URL Gambar (Opsional)',
                  hintText: 'https://link-gambar.com/img.png',
                  helperText: 'Tulis satu URL per baris jika ada beberapa gambar',
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

    final nomorStr = nomorCtrl.text.trim();
    final emoji = emojiCtrl.text.trim();
    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();
    final tips = tipsCtrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final urls = urlsCtrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (nomorStr.isEmpty || emoji.isEmpty || title.isEmpty || description.isEmpty) {
      _showSnack('Semua field wajib diisi kecuali URL Gambar');
      return;
    }

    final nomor = int.tryParse(nomorStr) ?? 0;

    final saved = await SupabaseService.instance.savePanduanItem(
      id: id,
      nomor: nomor,
      emoji: emoji,
      title: title,
      description: description,
      tips: tips,
      gambarUrls: urls,
    );

    if (!mounted) return;
    if (saved) {
      _showSnack('Panduan berhasil disimpan');
      await _loadData();
    } else {
      _showSnack('Gagal menyimpan panduan');
    }
  }

  Future<void> _deletePanduan(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Panduan'),
        content: const Text('Yakin ingin menghapus langkah panduan ini?'),
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

    final deleted = await SupabaseService.instance.deletePanduanItem(id);
    if (!mounted) return;
    if (deleted) {
      _showSnack('Panduan berhasil dihapus');
      await _loadData();
    } else {
      _showSnack('Gagal menghapus panduan');
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
      title: 'Kelola Panduan',
      currentRoute: '/admin/panduan',
      onRefresh: _loadData,
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: SibersihColors.primary),
              ),
            )
          : AdminPanel(
              title: 'Langkah Panduan Aplikasi (${_panduans.length})',
              trailing: ElevatedButton.icon(
                onPressed: () => _savePanduan(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SibersihColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              child: _panduans.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Belum ada panduan. Tambahkan panduan untuk aplikasi user.'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _panduans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final panduan = _panduans[index];
                        final List<dynamic> tipsList = panduan['tips'] ?? [];
                        final stepNum = panduan['nomor']?.toString().padLeft(2, '0') ?? '00';
                        return Container(
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             border: Border.all(color: Colors.grey.shade200),
                             borderRadius: BorderRadius.circular(10),
                           ),
                           child: Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Container(
                                 width: 44,
                                 height: 44,
                                 alignment: Alignment.center,
                                 decoration: BoxDecoration(
                                   color: SibersihColors.primary.withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(10),
                                 ),
                                 child: Text(
                                   panduan['emoji']?.toString() ?? '🌿',
                                   style: const TextStyle(fontSize: 22),
                                 ),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Row(
                                       children: [
                                         Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                           decoration: BoxDecoration(
                                             color: SibersihColors.primary,
                                             borderRadius: BorderRadius.circular(4),
                                           ),
                                           child: Text(
                                             'Langkah $stepNum',
                                             style: const TextStyle(
                                               color: Colors.white,
                                               fontWeight: FontWeight.w800,
                                               fontSize: 11,
                                             ),
                                           ),
                                         ),
                                         const SizedBox(width: 8),
                                         Expanded(
                                           child: Text(
                                             panduan['title']?.toString() ?? '-',
                                             style: const TextStyle(
                                               fontWeight: FontWeight.w800,
                                               fontSize: 15,
                                               color: Color(0xFF2E2E4A),
                                             ),
                                           ),
                                         ),
                                       ],
                                     ),
                                     const SizedBox(height: 8),
                                     Text(
                                       panduan['description']?.toString() ?? '-',
                                       style: TextStyle(
                                         color: Colors.grey.shade600,
                                         fontSize: 13,
                                         height: 1.4,
                                       ),
                                     ),
                                     if (tipsList.isNotEmpty) ...[
                                       const SizedBox(height: 8),
                                       const Text(
                                         'Tips detail:',
                                         style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                       ),
                                       const SizedBox(height: 4),
                                       Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: tipsList.map((tip) => Padding(
                                           padding: const EdgeInsets.only(bottom: 2),
                                           child: Row(
                                             children: [
                                               const Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
                                               const SizedBox(width: 6),
                                               Expanded(child: Text(tip.toString(), style: const TextStyle(fontSize: 12))),
                                             ],
                                           ),
                                         )).toList(),
                                       ),
                                     ],
                                   ],
                                 ),
                               ),
                               const SizedBox(width: 8),
                               IconButton(
                                 onPressed: () => _savePanduan(id: panduan['id'].toString()),
                                 icon: const Icon(Icons.edit_rounded, size: 20),
                               ),
                               IconButton(
                                 onPressed: () => _deletePanduan(panduan['id'].toString()),
                                 icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
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
