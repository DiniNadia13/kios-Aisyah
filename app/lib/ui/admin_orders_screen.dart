import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api.dart';
import '../state.dart';
import 'admin_products_screen.dart';
import 'common.dart';
import 'receipt_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Json> orders = [];
  Json? stats;
  bool loading = true;
  String? error;
  String filterStatus = 'all';
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted && !loading) {
        _silentRefresh();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    try {
      final statsRes = await Api.get('/admin/stats');
      final ordersRes = await Api.get('/admin/orders', {
        if (filterStatus != 'all') 'status': filterStatus,
      });

      if (mounted) {
        setState(() {
          stats = Json.from(statsRes as Map);
          orders = (ordersRes['data'] as List).map((e) => Json.from(e as Map)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final statsRes = await Api.get('/admin/stats');
      final ordersRes = await Api.get('/admin/orders', {
        if (filterStatus != 'all') 'status': filterStatus,
      });

      if (mounted) {
        setState(() {
          stats = Json.from(statsRes as Map);
          orders = (ordersRes['data'] as List).map((e) => Json.from(e as Map)).toList();
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _updateStatus(Json o, String newStatus, {String? paymentStatus}) async {
    try {
      await Api.post('/admin/orders/${o['id']}/status', {
        'status': newStatus,
        if (paymentStatus != null) 'payment_status': paymentStatus,
      });

      if (mounted) {
        snack(context, 'Status ${o['code']} diubah ke ${statusLabel(newStatus)}', isSuccess: true);
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    }
  }

  Future<void> _updatePayment(Json o, String paymentStatus) async {
    try {
      await Api.post('/admin/orders/${o['id']}/status', {
        'payment_status': paymentStatus,
      });
      if (mounted) {
        snack(context, 'Pembayaran ${o['code']} ditandai $paymentStatus', isSuccess: true);
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'delivering':
        return const Color(0xFF0284C7);
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelola Pesanan Kios',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'Panel Khusus Pemilik Kios (Admin)',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: kPrimaryDark,
              backgroundColor: kPrimaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
            ),
            icon: const Icon(Icons.inventory_2_outlined, size: 16),
            label: Text(
              'Produk Toko',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11.5),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kPrimaryDark),
            tooltip: 'Segarkan Data',
            onPressed: _load,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            // 1. Ringkasan Kios Hari Ini
            if (stats != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pendapatan Hari Ini',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFFD1FAE5), fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${stats!['today_orders_count']} Pesanan Masuk',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        rp(stats!['today_income'] ?? 0),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    Row(
                      children: [
                        _miniStat(
                          'Perlu Disetujui',
                          '${stats!['pending_count']}',
                          const Color(0xFFFEF08A),
                          Icons.notifications_active_rounded,
                        ),
                        const SizedBox(width: 12),
                        _miniStat(
                          'Sedang Diproses',
                          '${stats!['processing_count']}',
                          Colors.white,
                          Icons.inventory_2_outlined,
                        ),
                        const SizedBox(width: 12),
                        _miniStat(
                          'Sedang Diantar',
                          '${stats!['delivering_count']}',
                          const Color(0xFF67E8F9),
                          Icons.delivery_dining_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 2. Filter Status Kapsul
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip('Semua', 'all'),
                  _filterChip('Perlu Disetujui', 'pending'),
                  _filterChip('Diproses', 'processing'),
                  _filterChip('Diantar', 'delivering'),
                  _filterChip('Selesai', 'completed'),
                  _filterChip('Dibatalkan', 'cancelled'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Daftar Pesanan
            if (loading && orders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: kPrimary)),
              )
            else if (error != null && orders.isEmpty)
              ErrorRetry(error!, _load)
            else if (orders.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_rounded, size: 48, color: kSlate300),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada pesanan di kategori ini',
                        style: GoogleFonts.plusJakartaSans(
                          color: kTextSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, i) => _buildOrderAdminCard(orders[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFD1FAE5),
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => filterStatus = value);
          _load();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? kPrimaryDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? kPrimaryDark : const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              color: selected ? Colors.white : kTextPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderAdminCard(Json o) {
    final status = o['status'] as String;
    final color = _statusColor(status);
    final items = (o['items'] as List?) ?? [];
    final customerName = o['recipient'] ?? o['user']?['name'] ?? 'Pelanggan';
    final customerPhone = o['phone'] ?? o['user']?['phone'] ?? '';
    final isPaid = o['payment_status'] == 'paid';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status == 'pending' ? const Color(0xFFFDE68A) : const Color(0xFFF1F5F9),
          width: status == 'pending' ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Baris: Kode Order + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_rounded, size: 18, color: kPrimaryDark),
                    const SizedBox(width: 6),
                    Text(
                      o['code'] as String,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel(status),
                    style: GoogleFonts.plusJakartaSans(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Info Pembeli + Tombol Chat WA Pembeli
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, size: 18, color: kTextSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$customerName ($customerPhone)',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        if (o['address'] != null)
                          Text(
                            o['address'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary),
                          ),
                      ],
                    ),
                  ),
                  if (customerPhone.isNotEmpty)
                    InkWell(
                      onTap: () {
                        final clean = customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
                        final phone = clean.startsWith('0') ? '62${clean.substring(1)}' : clean;
                        openWhatsapp(
                          phone: phone,
                          message: 'Halo Kak $customerName, ini dari Kios Aisyha terkait pesanan ${o['code']}.',
                          context: context,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF059669)),
                            const SizedBox(width: 4),
                            Text(
                              'Chat WA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Daftar Barang Ringkas
            for (final it in items.take(3)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${it['name']} x${it['quantity']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextPrimary),
                      ),
                    ),
                    Text(
                      rp(it['subtotal']),
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            if (items.length > 3)
              Text(
                '+ ${items.length - 3} sembako lainnya...',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary, fontStyle: FontStyle.italic),
              ),
            const Divider(height: 16, color: kBorder),

            // Total Bayar & Status Pembayaran
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Pembayaran', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary)),
                    Text(
                      rp(o['total']),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimaryDark),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _updatePayment(o, isPaid ? 'unpaid' : 'paid'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPaid ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPaid ? Icons.check_circle_rounded : Icons.pending_outlined,
                          size: 13,
                          color: isPaid ? const Color(0xFF059669) : Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPaid ? 'LUNAS (Ubah)' : 'BELUM LUNAS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? const Color(0xFF059669) : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tombol Aksi Admin (Setujui, Proses, Antar, Selesai)
            Row(
              children: [
                // Tombol Lihat / Cetak Struk
                IconButton(
                  tooltip: 'Cetak Struk Thermal',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptScreen(order: o),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 18, color: kTextPrimary),
                ),
                const SizedBox(width: 8),

                // Tombol Status Dinamis
                if (status == 'pending') ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _updateStatus(o, 'cancelled'),
                      child: Text('Tolak', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _updateStatus(o, 'processing'),
                      child: Text('✓ Terima & Proses', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ] else if (status == 'processing') ...[
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _updateStatus(o, 'delivering'),
                      icon: const Icon(Icons.delivery_dining_rounded, size: 18),
                      label: Text('Mulai Antar Kurir', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ] else if (status == 'delivering') ...[
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _updateStatus(o, 'completed', paymentStatus: 'paid'),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text('Tandai Selesai & Lunas', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
