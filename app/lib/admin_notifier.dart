import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api.dart';
import 'ui/common.dart';
import 'sound_helper.dart';
import 'ui/admin_orders_screen.dart';

class AdminNotifier extends ChangeNotifier {
  static final AdminNotifier instance = AdminNotifier._();
  AdminNotifier._();

  Timer? _poller;
  final Set<int> _seenOrderIds = {};
  bool _initialized = false;
  int pendingCount = 0;

  void start(BuildContext context, bool isAdmin) {
    if (!isAdmin) {
      stop();
      return;
    }
    if (_poller != null && _poller!.isActive) return;

    _checkNewOrders(context);
    _poller = Timer.periodic(const Duration(seconds: 12), (_) {
      _checkNewOrders(context);
    });
  }

  void stop() {
    _poller?.cancel();
    _poller = null;
    _initialized = false;
    _seenOrderIds.clear();
    pendingCount = 0;
    notifyListeners();
  }

  Future<void> _checkNewOrders(BuildContext context) async {
    if (Api.token == null) return;
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
        if (_initialized && !_seenOrderIds.contains(id)) {
          newOrders.add(Map<String, dynamic>.from(item as Map));
        }
      }

      _seenOrderIds.addAll(currentIds);

      if (!_initialized) {
        _initialized = true;
        return;
      }

      for (final o in newOrders) {
        final code = (o['code'] as String?) ?? 'ORD';
        final user = o['user'] as Map?;
        final customerName = (user?['name'] as String?) ?? 'Pelanggan';
        final total = rp((o['total'] ?? o['total_price'] ?? 0) as int);

        // 1. Suara Bel Kasir & Web Notification
        playOrderChime(
          orderCode: code,
          customerName: customerName,
          total: total,
        );

        // 2. Banner Pop-up Mengambang
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
}
