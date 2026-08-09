import 'package:flutter/material.dart';
import '../../app_tokens.dart';
import '../../services/supabase_service.dart';
import 'admin_layout.dart';

class AdminQuotesPage extends StatefulWidget {
  const AdminQuotesPage({super.key});

  @override
  State<AdminQuotesPage> createState() => _AdminQuotesPageState();
}

class _AdminQuotesPageState extends State<AdminQuotesPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _quotes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await SupabaseService.instance.getAdminQuotes();
    if (!mounted) return;
    setState(() {
      _quotes = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _saveQuote({String? id}) async {
    final textCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final orderCtrl = TextEditingController();

    if (id != null) {
      final current = _quotes.firstWhere(
        (item) => item['id'].toString() == id,
        orElse: () => {},
      );
      if (current.isNotEmpty) {
        textCtrl.text = current['text']?.toString() ?? '';
        authorCtrl.text = current['author']?.toString() ?? '';
        orderCtrl.text = current['order']?.toString() ?? '0';
      }
    } else {
      orderCtrl.text = '${_quotes.length + 1}';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? 'Tambah Quote' : 'Edit Quote'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Teks quote',
                  hintText: '"Bumi ini bukan warisan nenek moyang..."',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: authorCtrl,
                decoration: const InputDecoration(labelText: 'Penulis'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Urutan tampil',
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
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (textCtrl.text.trim().isEmpty || authorCtrl.text.trim().isEmpty) {
      _showSnack('Teks dan penulis wajib diisi');
      return;
    }

    final saved = await SupabaseService.instance.saveQuoteItem(
      id: id,
      text: textCtrl.text.trim(),
      author: authorCtrl.text.trim(),
      order: int.tryParse(orderCtrl.text.trim()) ?? 0,
    );

    if (!mounted) return;
    if (saved) {
      _showSnack('Quote berhasil disimpan');
      await _loadData();
    } else {
      _showSnack('Gagal menyimpan quote');
    }
  }

  Future<void> _deleteQuote(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus quote'),
        content: const Text('Yakin ingin menghapus quote ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleted = await SupabaseService.instance.deleteQuoteItem(id);
    if (!mounted) return;
    if (deleted) {
      _showSnack('Quote berhasil dihapus');
      await _loadData();
    } else {
      _showSnack('Gagal menghapus quote');
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
      title: 'Kelola Quotes',
      currentRoute: '/admin/quotes',
      onRefresh: _loadData,
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: SibersihColors.primary),
              ),
            )
          : AdminPanel(
              title: 'Quotes Motivasi (${_quotes.length})',
              trailing: ElevatedButton.icon(
                onPressed: () => _saveQuote(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SibersihColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              child: _quotes.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Belum ada quote. Tambahkan quote motivasi untuk dashboard user.'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _quotes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final quote = _quotes[index];
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
                                  '${quote['order'] ?? index + 1}',
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
                                      quote['text']?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '— ${quote['author']?.toString() ?? 'Anonim'}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _saveQuote(id: quote['id'].toString()),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                onPressed: () => _deleteQuote(quote['id'].toString()),
                                icon: const Icon(Icons.delete_rounded, color: Colors.red),
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
