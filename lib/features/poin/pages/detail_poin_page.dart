import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/poin_repository.dart';
import '../../../models/poin_history_model.dart';
import '../../../core/app_tokens.dart';

class DetailPoinPage extends StatefulWidget {
  const DetailPoinPage({super.key});

  @override
  State<DetailPoinPage> createState() => _DetailPoinPageState();
}

class _DetailPoinPageState extends State<DetailPoinPage>
    with TickerProviderStateMixin {
  late AnimationController _chartController;
  
  bool _isLoading = true;
  UserModel? _user;
  int _poinMasukBulanIni = 0;
  int _poinKeluarBulanIni = 0;
  List<BulananPoinModel> _bulananPoin = [];
  int _selectedMonth = 0;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await UserRepository.instance.getCurrentUser();
      final userRank = await UserRepository.instance.getUserRank(user.uid);
      final updatedUser = user.copyWith(rank: userRank);

      final results = await Future.wait([
        PoinRepository.instance.getPoinBulanIni(),
        PoinRepository.instance.getBulananPoin(),
      ]);

      final poinBulanIni = results[0] as Map<String, int>;
      final bulananPoin = results[1] as List<BulananPoinModel>;

      setState(() {
        _user = updatedUser;
        _poinMasukBulanIni = poinBulanIni['masuk'] ?? 0;
        _poinKeluarBulanIni = poinBulanIni['keluar'] ?? 0;
        _bulananPoin = bulananPoin;
        _selectedMonth = bulananPoin.isNotEmpty ? bulananPoin.length - 1 : 0;
        _isLoading = false;
      });
      _chartController.forward();
    } catch (e) {
      debugPrint('DetailPoinPage _loadData error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SibersihColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Detail Poin',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SibersihColors.primary))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Poin Card
                    _buildTotalPoinCard(),
                    const SizedBox(height: 24),
                    // Graph Title
                    const Text(
                      'Grafik Poin Bulanan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tren perolehan poin Anda setiap bulannya',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    // Bar Chart
                    _buildBarChart(),
                    const SizedBox(height: 24),
                    // Deskripsi
                    //_buildDescriptionSection(),
                    const SizedBox(height: 24),
                    // Statistik
                    _buildStatisticsSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTotalPoinCard() {
    final totalPoin = _user?.totalPoin ?? 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SibersihColors.primary, SibersihColors.primaryGlow],
        ),
        borderRadius: BorderRadius.circular(SibersihRadius.xl),
        boxShadow: [
          BoxShadow(
            color: SibersihColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Poin Keseluruhan',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '⭐ $totalPoin',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (_poinMasukBulanIni > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '+$_poinMasukBulanIni Bulan Ini',
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (_bulananPoin.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? SibersihColors.cardDark
              : Colors.white,
          borderRadius: BorderRadius.circular(SibersihRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'Belum ada data grafik',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    final months = _bulananPoin.map((e) => e.bulan).toList();
    final data = _bulananPoin.map((e) => e.poin.toDouble()).toList();
    
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final maxValue = maxVal > 0 ? maxVal * 1.2 : 100.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? SibersihColors.cardDark
            : Colors.white,
        borderRadius: BorderRadius.circular(SibersihRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (index) {
                final height = (data[index] / maxValue) * 160;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (data[index] > 0)
                          Text(
                            '${data[index].toInt()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 4),
                        AnimatedBuilder(
                          animation: _chartController,
                          builder: (_, __) {
                            final animatedHeight =
                                height * _chartController.value;
                            return Container(
                              width: double.infinity,
                              height: animatedHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    SibersihColors.primary,
                                    SibersihColors.primary.withValues(alpha: 0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: months
                .asMap()
                .entries
                .map(
                  (entry) => Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: entry.key == _selectedMonth
                          ? SibersihColors.primary
                          : Colors.grey,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // Widget _buildDescriptionSection() {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Tentang Sistem Poin',
  //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
  //       ),
  //       const SizedBox(height: 12),
  //       Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: isDark 
  //               ? SibersihColors.cardDark
  //               : SibersihColors.primary.withValues(alpha: 0.05),
  //           borderRadius: BorderRadius.circular(SibersihRadius.md),
  //           border: Border.all(
  //             color: isDark
  //                 ? Colors.white.withValues(alpha: 0.08)
  //                 : SibersihColors.primary.withValues(alpha: 0.12),
  //           ),
  //         ),
  //         child: const Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               '🎯 Cara Mendapatkan Poin:',
  //               style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
  //             ),
  //             SizedBox(height: 8),
  //             Text(
  //               '• Lapor sampah plastik: 100 poin per kg',
  //               style: TextStyle(fontSize: 12, color: Colors.grey),
  //             ),
  //             Text(
  //               '• Lapor sampah kertas: 80 poin per kg',
  //               style: TextStyle(fontSize: 12, color: Colors.grey),
  //             ),
  //             Text(
  //               '• Lapor sampah logam: 150 poin per kg',
  //               style: TextStyle(fontSize: 12, color: Colors.grey),
  //             ),
  //             SizedBox(height: 12),
  //             Text(
  //               '🎁 Poin dapat ditukar dengan rewards menarik!',
  //               style: TextStyle(
  //                 fontSize: 12,
  //                 fontWeight: FontWeight.w600,
  //                 color: SibersihColors.primaryGlow,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildStatisticsSection() {
    final level = _user?.level ?? 'Pemula';
    final rank = _user?.rank ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Poin',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.3,
          children: [
            _buildStatCard(
              'Poin Masuk',
              '+$_poinMasukBulanIni',
              Icons.trending_up_rounded,
              SibersihColors.success,
            ),
            _buildStatCard(
              'Poin Keluar',
              '-$_poinKeluarBulanIni',
              Icons.trending_down_rounded,
              SibersihColors.warning,
            ),
            _buildStatCard(
              'Level Kamu',
              level,
              Icons.military_tech_rounded,
              SibersihColors.accentPurple,
            ),
            _buildStatCard(
              'Peringkat',
              '#$rank',
              Icons.leaderboard_rounded,
              SibersihColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? SibersihColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(SibersihRadius.md),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : SibersihColors.primary.withValues(alpha: 0.08),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
