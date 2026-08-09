import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_tokens.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isOffline = false;
  Timer? _timer;
  bool _showRestoredBanner = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('https://ciaykezzojnksqlsioqh.supabase.co/rest/v1/'))
          .timeout(const Duration(seconds: 4));

      final isOnline = response.statusCode < 500;
      _updateStatus(!isOnline);
    } catch (_) {
      _updateStatus(true);
    }
  }

  void _updateStatus(bool offline) {
    if (!mounted) return;
    if (_isOffline != offline) {
      setState(() {
        if (!offline && _isOffline) {
          _showRestoredBanner = true;
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => _showRestoredBanner = false);
            }
          });
        }
        _isOffline = offline;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline || _showRestoredBanner)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _isOffline
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(SibersihRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isOffline
                          ? Icons.wifi_off_rounded
                          : Icons.wifi_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOffline
                          ? 'Koneksi Internet Terputus'
                          : 'Koneksi Terhubung Kembali',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
