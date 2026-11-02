import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../state.dart';
import 'admin_orders_screen.dart';
import 'common.dart';
import 'payment_info_card.dart';
import 'receipt_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrdersState>().load();
      }
    });
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

  void _reorder(Json o) {
    final cart = context.read<CartState>();
    final items = o['items'] as List?;
    if (items == null || items.isEmpty) return;

    int count = 0;
    for (final it in items) {
      final itemMap = Json.from(it as Map);
      final prod = {
        'id': itemMap['product_id'] ?? itemMap['id'],
        'name': itemMap['name'] ?? 'Sembako',
        'price': itemMap['price'] ?? 0,
        'final_price': itemMap['price'] ?? 0,
        'unit': itemMap['unit'] ?? 'pcs',
        'stock': 999,
      };
      final qty = (itemMap['quantity'] as num?)?.toInt() ?? 1;
      if (cart.add(prod, qty)) {
        count++;
      }
    }

    snack(
      context,
      '$count produk dari ${o['code']} telah ditambahkan ke keranjang!',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = context.watch<OrdersState>();
    final orders = ordersState.orders;
    final error = ordersState.error;
    final loading = ordersState.loading;

    Widget body;
    if (error != null && (orders == null || orders.isEmpty)) {
      body = ErrorRetry(error, () => context.read<OrdersState>().load());
    } else if (orders == null || (loading && orders.isEmpty)) {
      body = const Center(child: CircularProgressIndicator(color: kPrimary));
    } else if (orders.isEmpty) {
      body = RefreshIndicator(
        color: kPrimary,
        onRefresh: () => context.read<OrdersState>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kPrimaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_outlined, size: 52, color: kPrimaryDark),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Riwayat Pesanan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pesanan sembako yang Anda buat akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: kTextSecondary),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.read<OrdersState>().load(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'Perbarui Data',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        color: kPrimary,
        onRefresh: () => context.read<OrdersState>().load(),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final o = orders[i];
            final status = o['status'] as String;
            final color = _statusColor(status);
            final itemsCount = (o['items'] as List).length;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)),
                    );
                    if (context.mounted) {
                      context.read<OrdersState>().load();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_rounded, size: 18, color: kPrimary),
                                const SizedBox(width: 6),
                                Text(
                                  o['code'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusLabel(status),
                                style: GoogleFonts.plusJakartaSans(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$itemsCount jenis sembako • ${o['delivery_method'] == 'pickup' ? 'Ambil di Toko' : 'Diantar ke Rumah'}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: kTextSecondary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Belanja',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: kTextSecondary,
                                  ),
                                ),
                                Text(
                                  rp(o['total']),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: kPrimaryDark,
                                  ),
                                ),
                              ],
                            ),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: kPrimaryLight,
                                foregroundColor: kPrimaryDark,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _reorder(o),
                              icon: const Icon(Icons.replay_rounded, size: 16),
                              label: Text(
                                'Pesan Lagi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          'Pesanan Saya',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (context.watch<AuthState>().isAdmin) ...[
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryDark,
                backgroundColor: kPrimaryLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
              ),
              icon: const Icon(Icons.storefront_rounded, size: 16),
              label: Text(
                'Kelola Kios',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11.5),
              ),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kPrimary),
            tooltip: 'Segarkan Pesanan',
            onPressed: () => context.read<OrdersState>().load(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: body,
    );
  }
}

class OrderDetailScreen extends StatefulWidget {
  final Json order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Json o = widget.order;
  bool cancelling = false;

  Future<void> _cancel() async {
    setState(() => cancelling = true);
    try {
      final r = await Api.post('/orders/${o['id']}/cancel');
      setState(() => o = Json.from(r as Map));
      if (mounted) {
        context.read<OrdersState>().load();
        snack(context, 'Pesanan berhasil dibatalkan', isSuccess: true);
      }
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    }
    if (mounted) setState(() => cancelling = false);
  }

  void _reorder() {
    final cart = context.read<CartState>();
    final items = o['items'] as List?;
    if (items == null || items.isEmpty) return;

    int count = 0;
    for (final it in items) {
      final itemMap = Json.from(it as Map);
      final prod = {
        'id': itemMap['product_id'] ?? itemMap['id'],
        'name': itemMap['name'] ?? 'Sembako',
        'price': itemMap['price'] ?? 0,
        'final_price': itemMap['price'] ?? 0,
        'unit': itemMap['unit'] ?? 'pcs',
        'stock': 999,
      };
      final qty = (itemMap['quantity'] as num?)?.toInt() ?? 1;
      if (cart.add(prod, qty)) {
        count++;
      }
    }

    snack(
      context,
      '$count produk dari ${o['code']} dimasukkan ke keranjang!',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = o['status'] as String;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          'Detail ${o['code']}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Status Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: kPrimaryDark, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Pesanan',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: kTextSecondary),
                      ),
                      Text(
                        statusLabel(status),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Kartu Pembayaran Transfer / QRIS (jika ada)
          PaymentInfoCard(order: o),

          // Tombol WhatsApp, Struk, & Pesan Lagi
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final msg = formatOrderForWhatsapp(o);
                      openWhatsapp(message: msg, context: context);
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: Text(
                      'Kirim Rincian ke WhatsApp Toko',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceiptScreen(order: o),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_rounded, size: 18),
                    label: Text(
                      'Lihat & Cetak Struk Belanja (POS)',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryDark,
                      side: const BorderSide(color: kPrimaryDark),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _reorder,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: Text(
                      'Pesan Lagi Semua Produk Ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Daftar Item Produk
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produk yang Dipesan',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                for (final it in (o['items'] as List)) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it['name'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: kTextPrimary,
                                ),
                              ),
                              Text(
                                '${it['quantity']} x ${rp(it['price'])}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          rp(it['subtotal']),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (it != (o['items'] as List).last) const Divider(height: 8, color: kBorder),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Rincian Pembayaran
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rincian Biaya',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _row('Subtotal', rp(o['subtotal'])),
                if ((o['discount'] as int) > 0)
                  _row('Potongan Promo', '-${rp(o['discount'])}',
                      color: Colors.red.shade600, isBold: true),
                _row(
                  'Ongkir',
                  (o['shipping_fee'] as int) == 0 ? 'GRATIS' : rp(o['shipping_fee']),
                  color: (o['shipping_fee'] as int) == 0 ? kPrimaryDark : null,
                  isBold: (o['shipping_fee'] as int) == 0,
                ),
                const Divider(height: 16, color: kBorder),
                _row('Total Akhir', rp(o['total']),
                    isBold: true, fontSize: 16, color: kPrimaryDark),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Info Penerimaan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Pengantaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _row('Metode',
                    o['delivery_method'] == 'pickup' ? 'Ambil di Toko' : 'Diantar Kurir'),
                if (o['address'] != null) _row('Alamat', o['address'] as String),
                _row('Pembayaran',
                    '${o['payment_method'].toString().toUpperCase()} (${o['payment_status'] == 'paid' ? 'Lunas' : 'Belum Bayar'})'),
              ],
            ),
          ),

          if (status == 'pending') ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: cancelling ? null : _cancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(
                cancelling ? 'Membatalkan...' : 'Batalkan Pesanan Ini',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _row(String l, String r,
          {bool isBold = false, double fontSize = 12.5, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(l,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: fontSize, color: kTextSecondary)),
            ),
            Expanded(
              child: Text(
                r,
                textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  fontSize: fontSize,
                  color: color ?? kTextPrimary,
                ),
              ),
            ),
          ],
        ),
      );
}
