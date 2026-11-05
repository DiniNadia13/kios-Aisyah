import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'main.dart';
import 'sound_helper.dart';
import 'state.dart';
import 'ui/admin_orders_screen.dart';
import 'ui/common.dart';

class AdminNotifier extends ChangeNotifier {
  static final AdminNotifier instance = AdminNotifier._();
  AdminNotifier._();

  Timer? _poller;
  final Set<int> _seenAdminOrderIds = {};
  final Map<int, String> _userOrderStatuses = {};
  bool _adminInitialized = false;
  bool _userInitialized = false;

  int pendingCount = 0;
  int userActiveOrderCount = 0;

  bool _currentIsAdmin = false;
  bool _currentLoggedIn = false;

  void start(BuildContext context, {required bool loggedIn, required bool isAdmin}) {
    if (!loggedIn) {
      stop();
      return;
    }

    if (_poller != null && _poller!.isActive && _currentIsAdmin == isAdmin && _currentLoggedIn == loggedIn) {
      return;
    }

    _currentIsAdmin = isAdmin;
    _currentLoggedIn = loggedIn;
    _poller?.cancel();
    _adminInitialized = false;
    _userInitialized = false;
    _seenAdminOrderIds.clear();
    _userOrderStatuses.clear();

    _tick(context);
    _poller = Timer.periodic(const Duration(seconds: 12), (_) {
      _tick(context);
    });
  }

  void stop() {
    _poller?.cancel();
    _poller = null;
    _adminInitialized = false;
    _userInitialized = false;
    _seenAdminOrderIds.clear();
    _userOrderStatuses.clear();
    pendingCount = 0;
    userActiveOrderCount = 0;
    _currentIsAdmin = false;
    _currentLoggedIn = false;
    notifyListeners();
  }

  Future<void> _tick(BuildContext context) async {
    if (Api.token == null) return;
    if (_currentIsAdmin) {
      await _checkAdminOrders(context);
    } else {
      await _checkUserOrders(context);
    }
  }

  // --- 1. NOTIFIKASI KHUSUS ADMIN (Pesanan Baru Masuk) ---
  Future<void> _checkAdminOrders(BuildContext context) async {
    try {
      final r = await Api.get('/admin/orders', {'status': 'pending'});
      final List data = (r['data'] as List?) ?? [];
      pendingCount = data.length;
      notifyListeners();

      final currentIds = <int>{};
      final newOrders = <Map<String, dynamic>>[];

      for (final item in data) {
        final id = item['id'] as int;
        currentIds.add(id);
        if (_adminInitialized && !_seenAdminOrderIds.contains(id)) {
          newOrders.add(Map<String, dynamic>.from(item as Map));
        }
      }

      _seenAdminOrderIds.addAll(currentIds);

      if (!_adminInitialized) {
        _adminInitialized = true;
        return;
      }

      for (final o in newOrders) {
        final code = (o['code'] as String?) ?? 'ORD';
        final user = o['user'] as Map?;
        final customerName = (user?['name'] as String?) ?? 'Pelanggan';
        final total = rp((o['total'] ?? o['total_price'] ?? 0) as int);

        // Suara Bel Kasir & Web Notification
        playOrderChime(
          orderCode: code,
          customerName: customerName,
          total: total,
        );

        // Banner Pop-up Mengambang di Web/App Admin
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF047857),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              duration: const Duration(seconds: 10),
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔔 PESANAN BARU MASUK!',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                            fontSize: 12.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$code dari $customerName ($total)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'BUKA PESANAN',
                textColor: Colors.amber,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (_) {}
  }

  // --- 2. NOTIFIKASI KHUSUS USER / PEMBELI (Pesanan Diantar / Disetujui) ---
  Future<void> _checkUserOrders(BuildContext context) async {
    try {
      final r = await Api.get('/orders');
      final List data = (r['data'] as List?) ?? [];

      userActiveOrderCount = data.where((e) {
        final st = e['status'] as String?;
        return st == 'pending' || st == 'processing' || st == 'delivering';
      }).length;
      notifyListeners();

      if (!_userInitialized) {
        for (final item in data) {
          final id = item['id'] as int;
          _userOrderStatuses[id] = (item['status'] as String?) ?? '';
        }
        _userInitialized = true;
        return;
      }

      for (final item in data) {
        final id = item['id'] as int;
        final status = (item['status'] as String?) ?? '';
        final prevStatus = _userOrderStatuses[id];
        _userOrderStatuses[id] = status;

        if (prevStatus != null && prevStatus != status) {
          final code = (item['code'] as String?) ?? 'ORD';
          String notifTitle = '';
          String notifBody = '';
          Color bannerColor = const Color(0xFF047857);
          IconData bannerIcon = Icons.notifications_active_rounded;

          if (status == 'delivering') {
            notifTitle = '🛵 PESANAN SEDANG DIANTAR!';
            notifBody = 'Pesanan $code sedang dalam perjalanan ke alamat Anda.';
            bannerColor = const Color(0xFF0284C7);
            bannerIcon = Icons.delivery_dining_rounded;
          } else if (status == 'processing') {
            notifTitle = '✅ PESANAN DISETUJUI & DISIAPKAN!';
            notifBody = 'Pesanan $code telah disetujui toko dan sedang dikemas.';
            bannerColor = const Color(0xFF059669);
            bannerIcon = Icons.check_circle_rounded;
          } else if (status == 'completed') {
            notifTitle = '🎉 PESANAN SELESAI / TIBA!';
            notifBody = 'Pesanan $code telah tiba. Terima kasih atas pembelian Anda!';
            bannerColor = const Color(0xFF10B981);
            bannerIcon = Icons.task_alt_rounded;
          } else if (status == 'cancelled') {
            notifTitle = '❌ PESANAN DIBATALKAN';
            notifBody = 'Pesanan $code telah dibatalkan.';
            bannerColor = const Color(0xFFEF4444);
            bannerIcon = Icons.cancel_rounded;
          }

          if (notifTitle.isNotEmpty) {
            playOrderChime(
              orderCode: code,
              customerName: notifTitle,
              total: notifBody,
            );

            if (context.mounted) {
              context.read<OrdersState>().load();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: bannerColor,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  duration: const Duration(seconds: 10),
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(bannerIcon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notifTitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 12.5,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notifBody,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  action: SnackBarAction(
                    label: 'LIHAT PESANAN',
                    textColor: Colors.amber,
                    onPressed: () {
                      Shell.switchTab(context, 3);
                    },
                  ),
                ),
              );
            }
          }
        }
      }
    } catch (_) {}
  }
}
