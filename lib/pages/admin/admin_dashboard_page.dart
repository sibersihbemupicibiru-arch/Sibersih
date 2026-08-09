import 'package:flutter/material.dart';
import '../../app_tokens.dart';
import '../../services/supabase_service.dart';
import 'admin_layout.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _loading = true;
  Map<String, int> _overview = const {
    'users': 0,
    'laporans': 0,
    'pending': 0,
    'verified': 0,
    'points': 0,
  };
  int _rewardCount = 0;
  int _quoteCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      SupabaseService.instance.getAdminOverview(),
      SupabaseService.instance.getAdminRewards(),
      SupabaseService.instance.getAdminQuotes(),
    ]);
    if (!mounted) return;
    setState(() {
      _overview = results[0] as Map<String, int>;
      _rewardCount = (results[1] as List).length;
      _quoteCount = (results[2] as List).length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Dashboard',
      currentRoute: '/admin/dashboard',
      onRefresh: _loadData,
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: SibersihColors.primary),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2E2E4A),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pantau aktivitas platform Sibersih secara real-time.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    AdminStatCard(
                      title: 'Pengguna',
                      value: '${_overview['users']}',
                      icon: Icons.group_rounded,
                      accentColor: Colors.blue,
                    ),
                    AdminStatCard(
                      title: 'Laporan',
                      value: '${_overview['laporans']}',
                      icon: Icons.report_problem_rounded,
                      accentColor: Colors.orange,
                    ),
                    AdminStatCard(
                      title: 'Pending',
                      value: '${_overview['pending']}',
                      icon: Icons.pending_actions_rounded,
                      accentColor: Colors.red,
                    ),
                    AdminStatCard(
                      title: 'Terverifikasi',
                      value: '${_overview['verified']}',
                      icon: Icons.check_circle_rounded,
                      accentColor: Colors.green,
                    ),
                    AdminStatCard(
                      title: 'Total Poin',
                      value: '${_overview['points']}',
                      icon: Icons.stars_rounded,
                      accentColor: Colors.amber.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                AdminPanel(
                  title: 'Aktivitas Terbaru',
                  child: Column(
                    children: [
                      _infoRow('Laporan menunggu verifikasi', '${_overview['pending']} item'),
                      _infoRow('Laporan terverifikasi', '${_overview['verified']} item'),
                      _infoRow('Total pengguna terdaftar', '${_overview['users']} akun'),
                      _infoRow('Total reward aktif', '$_rewardCount item'),
                      _infoRow('Total quotes motivasi', '$_quoteCount item'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AdminPanel(
                  title: 'Aksi Cepat',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _quickAction(
                        'Kelola Laporan',
                        Icons.fact_check_rounded,
                        '/admin/laporan',
                      ),
                      _quickAction(
                        'Lihat Pengguna',
                        Icons.people_alt_rounded,
                        '/admin/users',
                      ),
                      _quickAction(
                        'Kelola Reward',
                        Icons.card_giftcard_rounded,
                        '/admin/rewards',
                      ),
                      _quickAction(
                        'Kelola Quotes',
                        Icons.format_quote_rounded,
                        '/admin/quotes',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, String route) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushReplacementNamed(context, route),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: SibersihColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
