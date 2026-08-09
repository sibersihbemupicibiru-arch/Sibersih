import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../repositories/poin_repository.dart';
import '../../../repositories/user_repository.dart';

class TukarPoinPage extends StatefulWidget {
  const TukarPoinPage({super.key});

  @override
  State<TukarPoinPage> createState() => _TukarPoinPageState();
}

class _TukarPoinPageState extends State<TukarPoinPage> {
  int _currentPoin = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _rewards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      // Paralel: getCurrentUser dan getRewardItems tidak saling bergantung
      final results = await Future.wait([
        UserRepository.instance.getCurrentUser(forceRefresh: forceRefresh),
        PoinRepository.instance.getRewardItems(),
      ]);

      final user = results[0] as UserModel;
      final dbRewards = results[1] as List<Map<String, dynamic>>;

      setState(() {
        _currentPoin = user.totalPoin;
        _rewards = dbRewards;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('TukarPoinPage _loadData error: $e');
      setState(() {
        _currentPoin = 0;
        _rewards = [];
        _isLoading = false;
      });
    }
  }

  Color _getRewardColor(dynamic colorValue, int index) {
    if (colorValue is Color) return colorValue;
    if (colorValue is String) {
      if (colorValue.startsWith('#')) {
        final hex = colorValue.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
      final parsedInt = int.tryParse(colorValue);
      if (parsedInt != null) return Color(parsedInt);
    }
    final defaultColors = [
      const Color(0xFF1007BA),
      const Color(0xFF4C3FE8),
      const Color(0xFFFF6B35),
      const Color(0xFFFF8C42),
      const Color(0xFFFFD700),
      const Color(0xFFFFA500),
      const Color(0xFF00A86B),
      const Color(0xFF9C27B0),
    ];
    return defaultColors[index % defaultColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1007BA),
        foregroundColor: Colors.white,
        title: const Text(
          'Tukar Poin',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1007BA)))
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: const Color(0xFF1007BA),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Poin Card
                    _buildCurrentPoinCard(),
                    const SizedBox(height: 24),
                    // Title
                    const Text(
                      'Pilih Reward',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tukarkan poin Anda dengan reward pilihan',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (_rewards.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🎁', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada reward tersedia',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Silakan hubungi administrator',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                        children: _rewards
                            .map((reward) => _buildRewardCard(reward))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildCurrentPoinCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1007BA), Color(0xFF4C3FE8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1007BA).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Poin Tersedia',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '⭐ $_currentPoin',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('🎁', style: TextStyle(fontSize: 40)),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    final points = (reward['poin'] as num? ?? reward['points'] as num? ?? 0).toInt();
    final name = reward['name'] as String? ?? reward['title'] as String? ?? 'Reward';
    final imageUrl = reward['image_url'] as String?;
    final color = _getRewardColor(reward['color'], _rewards.indexOf(reward));
    
    final canBuy = _currentPoin >= points;

    return GestureDetector(
      onTap: () => _showRewardDetailPopup(reward),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: canBuy ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo (imageUrl)
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.card_giftcard_rounded,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Poin Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⭐ $points',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Disabled Overlay
            if (!canBuy)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Poin Kurang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRewardDetailPopup(Map<String, dynamic> reward) {
    final points = (reward['poin'] as num? ?? reward['points'] as num? ?? 0).toInt();
    final name = reward['name'] as String? ?? reward['title'] as String? ?? 'Reward';
    final imageUrl = reward['image_url'] as String?;
    final description = reward['description'] as String? ?? 'Tidak ada deskripsi barang.';
    final pickupLocation = reward['pickup_location'] as String? ?? 'Sekretariat/Gedung Utama';
    final pickupTime = reward['pickup_time'] as String? ?? 'Senin - Jumat, 09.00 - 15.00';
    final color = _getRewardColor(reward['color'], _rewards.indexOf(reward));
    
    final canBuy = _currentPoin >= points;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image header
              Container(
                height: 160,
                width: double.infinity,
                color: color.withValues(alpha: 0.1),
                child: Stack(
                  children: [
                    imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.card_giftcard_rounded, size: 48, color: Colors.grey),
                          ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Points Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '⭐ $points',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'poin',
                            style: TextStyle(
                              color: color.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    // Description
                    const Text(
                      'Deskripsi Barang',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pickup Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.redAccent),
                              SizedBox(width: 6),
                              Text(
                                'Lokasi Pengambilan:',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 2),
                            child: Text(
                              pickupLocation,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: Colors.blueAccent),
                              SizedBox(width: 6),
                              Text(
                                'Waktu Pengambilan:',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 2),
                            child: Text(
                              pickupTime,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close detail dialog
                          if (canBuy) {
                            _showConfirmDialog(reward);
                          } else {
                            _showInsufficientPoinDialog(reward);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          canBuy ? 'Tukar Sekarang' : 'Poin Kurang',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(Map<String, dynamic> reward) {
    final points = (reward['poin'] as num? ?? reward['points'] as num? ?? 0).toInt();
    final name = reward['name'] as String? ?? reward['title'] as String? ?? 'Reward';
    final icon = reward['icon'] as String? ?? '🎁';
    final color = _getRewardColor(reward['color'], _rewards.indexOf(reward));

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Konfirmasi Penukaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Poin Digunakan',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            '⭐ $points',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF1007BA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Poin Sisa',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            '⭐ ${_currentPoin - points}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Lanjutkan untuk menukar poin Anda',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _processRedemption(reward);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Tukar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInsufficientPoinDialog(Map<String, dynamic> reward) {
    final points = (reward['poin'] as num? ?? reward['points'] as num? ?? 0).toInt();
    final poinKurang = points - _currentPoin;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '😞',
                style: TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 16),
              const Text(
                'Poin Tidak Cukup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda membutuhkan $poinKurang poin lagi',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Laporkan lebih banyak sampah untuk mendapatkan poin tambahan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1007BA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Baik',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processRedemption(Map<String, dynamic> reward) async {
    setState(() => _isLoading = true);

    final rewardId = reward['id'] as int;

    final success = await PoinRepository.instance.redeemReward(
      rewardId: rewardId,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Berhasil Ditukar! 🎉',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reward['name'] as String? ?? 'Reward',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Voucher Code',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            'SBR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Berlaku Hingga',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            DateTime.now()
                                .add(const Duration(days: 30))
                                .toString()
                                .split(' ')
                                .first,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kode voucher telah dikirim ke email Anda',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadData(forceRefresh: true); // Reload points on successful redemption completion
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal melakukan penukaran poin. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
