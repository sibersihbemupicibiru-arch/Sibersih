import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'admin_layout.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await SupabaseService.instance.getAdminUsers();
    if (!mounted) return;
    setState(() {
      _users = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Daftar Pengguna',
      currentRoute: '/admin/users',
      onRefresh: _loadData,
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          : AdminPanel(
              title: 'Pengguna Terdaftar (${_users.length})',
              child: _users.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Belum ada pengguna.'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final nama = user['nama']?.toString() ?? 'User';
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF1007BA).withOpacity(0.12),
                                child: Text(
                                  nama.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF1007BA),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nama,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    Text(
                                      user['email']?.toString() ?? '-',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${user['total_poin'] ?? 0} poin',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${user['jumlah_laporan'] ?? 0} laporan',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
