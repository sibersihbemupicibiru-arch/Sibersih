import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_tokens.dart';
import '../../services/supabase_service.dart';
import 'admin_layout.dart';

class AdminRewardsPage extends StatefulWidget {
  const AdminRewardsPage({super.key});

  @override
  State<AdminRewardsPage> createState() => _AdminRewardsPageState();
}

class _AdminRewardsPageState extends State<AdminRewardsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _rewards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await SupabaseService.instance.getAdminRewards();
    if (!mounted) return;
    setState(() {
      _rewards = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _saveReward({String? id}) async {
    Map<String, dynamic>? reward;
    if (id != null) {
      reward = _rewards.firstWhere(
        (item) => item['id'].toString() == id,
        orElse: () => {},
      );
      if (reward.isEmpty) reward = null;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RewardFormDialog(reward: reward),
    );

    if (!mounted) return;
    if (saved == true) {
      _showSnack('Reward berhasil disimpan');
      await _loadData();
    }
  }

  Future<void> _deleteReward(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus reward'),
        content: const Text('Yakin ingin menghapus reward ini?'),
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

    final deleted = await SupabaseService.instance.deleteRewardItem(id);
    if (!mounted) return;
    if (deleted) {
      _showSnack('Reward berhasil dihapus');
      await _loadData();
    } else {
      _showSnack('Gagal menghapus reward');
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
      title: 'Kelola Reward',
      currentRoute: '/admin/rewards',
      onRefresh: _loadData,
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: SibersihColors.primary),
              ),
            )
          : AdminPanel(
              title: 'Reward Aktif (${_rewards.length})',
              trailing: ElevatedButton.icon(
                onPressed: () => _saveReward(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SibersihColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              child: _rewards.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Belum ada reward.'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _rewards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final reward = _rewards[index];
                        final imageUrl = reward['image_url']?.toString();
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20),
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.image_rounded, color: Colors.grey, size: 20),
                                      ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reward['name']?.toString() ?? 'Reward',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(reward['description']?.toString() ??
                                        '-'),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  '${reward['points'] ?? 0} poin',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _saveReward(id: reward['id'].toString()),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _deleteReward(reward['id'].toString()),
                                icon: const Icon(Icons.delete_rounded,
                                    color: Colors.red),
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

class _RewardFormDialog extends StatefulWidget {
  final Map<String, dynamic>? reward;
  const _RewardFormDialog({super.key, this.reward});

  @override
  State<_RewardFormDialog> createState() => _RewardFormDialogState();
}

class _RewardFormDialogState extends State<_RewardFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pointsCtrl;
  late final TextEditingController _descCtrl;

  Uint8List? _imageBytes;
  String? _imageExtension;
  String? _existingImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.reward?['name']?.toString() ?? '');
    _pointsCtrl = TextEditingController(text: widget.reward?['points']?.toString() ?? '');
    _descCtrl = TextEditingController(text: widget.reward?['description']?.toString() ?? '');
    _existingImageUrl = widget.reward?['image_url']?.toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pointsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      
      String ext = 'jpg';
      if (file.name.contains('.')) {
        final rawExt = file.name.split('.').last.toLowerCase();
        if (rawExt == 'png' || rawExt == 'jpg' || rawExt == 'jpeg' || rawExt == 'gif' || rawExt == 'webp') {
          ext = rawExt;
        }
      }
      
      setState(() {
        _imageBytes = bytes;
        _imageExtension = ext;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final points = int.tryParse(_pointsCtrl.text.trim()) ?? 0;
    final desc = _descCtrl.text.trim();

    if (name.isEmpty) return;
    if (points <= 0) return;

    setState(() => _isUploading = true);

    try {
      String? imageUrl = _existingImageUrl;

      if (_imageBytes != null && _imageExtension != null) {
        final uploadedUrl = await SupabaseService.instance.uploadRewardImage(
          _imageBytes!,
          _imageExtension!,
        );
        if (uploadedUrl == null) {
          throw Exception('Gagal mengunggah foto reward');
        }
        imageUrl = uploadedUrl;
      }

      final success = await SupabaseService.instance.saveRewardItem(
        id: widget.reward?['id']?.toString(),
        name: name,
        points: points,
        description: desc,
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        throw Exception('Gagal menyimpan ke database');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.reward == null ? 'Tambah Reward' : 'Edit Reward'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 36, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Pilih Foto Reward', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama reward'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Poin'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Poin wajib diisi';
                  final p = int.tryParse(val.trim());
                  if (p == null || p <= 0) return 'Poin harus angka > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: SibersihColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
