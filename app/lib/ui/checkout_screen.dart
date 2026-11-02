import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../main.dart';
import '../state.dart';
import 'common.dart';
import 'payment_info_card.dart';
import 'profile_screen.dart';
import 'receipt_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Json> addresses = [];
  int? addressId;
  String delivery = 'delivery';
  String payment = 'cod';
  String deliverySlot = 'Langsung (30-45 Menit)';
  static const deliverySlots = [
    'Langsung (30-45 Menit)',
    'Pagi (08:00 - 11:00 WIB)',
    'Siang (13:00 - 16:00 WIB)',
    'Sore (16:00 - 19:00 WIB)',
  ];
  final voucher = TextEditingController();
  final note = TextEditingController();
  String? appliedVoucher;
  Json? quote;
  String? quoteError;
  bool busy = false;

  static const payments = {
    'cod': {'title': 'Bayar di Tempat (COD)', 'desc': 'Bayar tunai saat kurir tiba di rumah', 'icon': Icons.handshake_rounded},
    'transfer': {'title': 'Transfer Bank', 'desc': 'BCA, Mandiri, BRI, BNI', 'icon': Icons.account_balance_rounded},
    'qris': {'title': 'QRIS', 'desc': 'Scan instan via GoPay, OVO, Dana, ShopeePay, BCA', 'icon': Icons.qr_code_scanner_rounded},
    'ewallet': {'title': 'E-Wallet', 'desc': 'Dana / OVO / GoPay / ShopeePay', 'icon': Icons.account_balance_wallet_rounded},
  };

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final r = await Api.get('/addresses') as List;
      addresses = r.map((e) => Json.from(e as Map)).toList();
      if (addresses.isNotEmpty) {
        final def = addresses.firstWhere(
          (a) => a['is_default'] == true,
          orElse: () => addresses.first,
        );
        addressId = def['id'] as int;
      }
    } catch (_) {}
    if (mounted) setState(() {});
    _requote();
  }

  int? get _zoneId {
    if (delivery != 'delivery' || addressId == null) return null;
    final a = addresses.firstWhere((a) => a['id'] == addressId, orElse: () => {});
    return a['shipping_zone_id'] as int?;
  }

  Future<void> _requote() async {
    try {
      final r = await Api.post('/cart/quote', {
        'items': context.read<CartState>().payload(),
        'delivery_method': delivery,
        'shipping_zone_id': _zoneId,
        if (appliedVoucher != null) 'voucher_code': appliedVoucher,
      });
      if (mounted) {
        setState(() {
          quote = Json.from(r as Map);
          quoteError = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => quoteError = e.message);
        if (appliedVoucher != null) {
          appliedVoucher = null;
          _requote();
        }
      }
    }
  }

  Future<void> _addAddress() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddressFormScreen()),
    );
    if (ok == true) _loadAddresses();
  }

  Future<void> _order() async {
    if (delivery == 'delivery' && addressId == null) {
      snack(context, 'Silakan pilih atau tambahkan alamat pengiriman');
      return;
    }
    setState(() => busy = true);
    final fullNote = [
      if (delivery == 'delivery') 'Waktu Antar: $deliverySlot',
      if (note.text.trim().isNotEmpty) note.text.trim(),
    ].join(' | ');

    try {
      final res = await Api.post('/checkout', {
        'items': context.read<CartState>().payload(),
        'delivery_method': delivery,
        'address_id': delivery == 'delivery' ? addressId : null,
        'payment_method': payment,
        'note': fullNote.isEmpty ? null : fullNote,
        if (appliedVoucher != null) 'voucher_code': appliedVoucher,
      });
      if (!mounted) return;
      context.read<CartState>().clear();

      final orderData = Json.from(res as Map);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: kPrimaryDark, size: 54),
                ),
                const SizedBox(height: 18),
                Text(
                  'Pesanan Berhasil!',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No. Pesanan: ${orderData['code']}\nTotal: ${rp(orderData['total'])}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: kTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Informasi Transfer / QRIS (jika memilih selain COD)
                if (payment == 'transfer' || payment == 'qris') ...[
                  PaymentInfoCard(order: orderData),
                  const SizedBox(height: 14),
                ],

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final msg = formatOrderForWhatsapp(orderData);
                      openWhatsapp(message: msg, context: ctx);
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                    label: Text(
                      payment == 'transfer' || payment == 'qris'
                          ? 'Kirim Bukti ke WhatsApp Toko'
                          : 'Kirim Nota ke WhatsApp Toko',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceiptScreen(order: orderData),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_rounded, size: 18),
                    label: Text(
                      'Lihat / Cetak Struk Belanja',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Lihat Status di Pesanan Saya',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: kTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (!mounted) return;
      context.read<OrdersState>().load();
      Navigator.of(context).popUntil((r) => r.isFirst);
      Shell.switchTab(context, 3);
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = quote;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          'Checkout Pesanan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Opsi Pengiriman
          _sectionCard(
            title: 'Metode Penerimaan',
            icon: Icons.local_shipping_outlined,
            child: Row(
              children: [
                Expanded(
                  child: _deliveryOption(
                    title: 'Diantar ke Rumah',
                    subtitle: 'Kurir Kios Aisyha',
                    value: 'delivery',
                    icon: Icons.delivery_dining_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _deliveryOption(
                    title: 'Ambil di Toko',
                    subtitle: 'Bebas Ongkir',
                    value: 'pickup',
                    icon: Icons.storefront_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Alamat Penerima (Jika Diantar)
          if (delivery == 'delivery') ...[
            _sectionCard(
              title: 'Alamat Pengiriman',
              icon: Icons.location_on_outlined,
              action: TextButton.icon(
                onPressed: _addAddress,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah'),
                style: TextButton.styleFrom(
                  foregroundColor: kPrimary,
                  textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              child: addresses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Belum ada alamat tersimpan. Klik Tambah di atas.',
                          style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 12.5),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (final a in addresses) ...[
                          GestureDetector(
                            onTap: () {
                              setState(() => addressId = a['id'] as int);
                              _requote();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: addressId == a['id'] ? kPrimaryLight.withOpacity(0.4) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: addressId == a['id'] ? kPrimary : const Color(0xFFE2E8F0),
                                  width: addressId == a['id'] ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    addressId == a['id'] ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                    color: addressId == a['id'] ? kPrimaryDark : kTextSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              a['label'] as String,
                                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const SizedBox(width: 6),
                                            Text('• ${a['recipient']}', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: kTextSecondary)),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          a['full_address'] as String,
                                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextPrimary),
                                        ),
                                        Text(
                                          a['phone'] as String,
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: kTextSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 14),

            // Waktu Pengantaran
            _sectionCard(
              title: 'Waktu Pengantaran',
              icon: Icons.schedule_rounded,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in deliverySlots)
                    GestureDetector(
                      onTap: () => setState(() => deliverySlot = slot),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: deliverySlot == slot ? kPrimaryLight : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: deliverySlot == slot ? kPrimary : const Color(0xFFE2E8F0),
                            width: deliverySlot == slot ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          slot,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: deliverySlot == slot ? FontWeight.bold : FontWeight.w500,
                            color: deliverySlot == slot ? kPrimaryDark : kTextPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 3. Voucher Promo
          _sectionCard(
            title: 'Voucher Promo Hemat',
            icon: Icons.confirmation_number_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: voucher,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Punya kode promo? (Contoh: HEMAT10)',
                          prefixIcon: const Icon(Icons.discount_outlined, color: kSecondary, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        appliedVoucher = voucher.text.trim().isEmpty ? null : voucher.text.trim();
                        _requote();
                      },
                      child: Text(
                        'Terapkan',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (quoteError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      quoteError!,
                      style: GoogleFonts.plusJakartaSans(color: Colors.red.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (appliedVoucher != null && quoteError == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: kPrimary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Promo $appliedVoucher berhasil digunakan!',
                          style: GoogleFonts.plusJakartaSans(color: kPrimaryDark, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Metode Pembayaran
          _sectionCard(
            title: 'Metode Pembayaran',
            icon: Icons.payment_outlined,
            child: Column(
              children: [
                for (final e in payments.entries) ...[
                  GestureDetector(
                    onTap: () => setState(() => payment = e.key),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: payment == e.key ? kPrimaryLight.withOpacity(0.4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: payment == e.key ? kPrimary : const Color(0xFFE2E8F0),
                          width: payment == e.key ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            e.value['icon'] as IconData,
                            color: payment == e.key ? kPrimaryDark : kTextSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.value['title'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: kTextPrimary,
                                  ),
                                ),
                                Text(
                                  e.value['desc'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            payment == e.key ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: payment == e.key ? kPrimaryDark : kTextSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Catatan Penjual
          _sectionCard(
            title: 'Catatan Untuk Toko',
            icon: Icons.edit_note_rounded,
            child: TextField(
              controller: note,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Contoh: Titip di pagar jika tidak ada orang...',
                fillColor: Color(0xFFF8FAFC),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 6. Ringkasan Pembayaran
          _sectionCard(
            title: 'Rincian Pembayaran',
            icon: Icons.receipt_outlined,
            child: q == null
                ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: kPrimary)))
                : Column(
                    children: [
                      for (final it in (q['items'] as List))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${it['name']} (x${it['quantity']})',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: kTextPrimary),
                                ),
                              ),
                              Text(
                                rp(it['subtotal']),
                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: kBorder)),
                      _summaryRow('Subtotal Belanja', rp(q['subtotal'])),
                      if ((q['discount'] as int) > 0)
                        _summaryRow('Potongan Promo', '-${rp(q['discount'])}', color: Colors.red.shade600, isBold: true),
                      _summaryRow(
                        'Ongkos Kirim',
                        q['free_shipping'] == true ? 'GRATIS' : rp(q['shipping_fee']),
                        color: q['free_shipping'] == true ? kPrimaryDark : null,
                        isBold: q['free_shipping'] == true,
                      ),
                      if (q['free_shipping'] != true && delivery == 'delivery')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: kAccentAmber),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Tambah ${rp(q['remaining_for_free_shipping'])} lagi untuk bebas ongkir!',
                                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: kBorder)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Belanja', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: kTextPrimary)),
                          Text(rp(q['total']), style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimaryDark)),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 90),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Color(0x0E000000), blurRadius: 16, offset: Offset(0, -4)),
            ],
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: busy || q == null ? null : _order,
            child: Text(
              busy ? 'Memproses Pesanan...' : 'Bayar Sekarang • ${q != null ? rp(q['total']) : ''}',
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child, Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 19, color: kPrimary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: kTextPrimary),
                  ),
                ],
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _deliveryOption({required String title, required String subtitle, required String value, required IconData icon}) {
    final selected = delivery == value;
    return GestureDetector(
      onTap: () {
        setState(() => delivery = value);
        _requote();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? kPrimaryLight.withOpacity(0.5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? kPrimary : const Color(0xFFE2E8F0), width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? kPrimaryDark : kTextSecondary, size: 28),
            const SizedBox(height: 6),
            Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5, color: kTextPrimary)),
            Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: kTextSecondary)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? kTextPrimary)),
        ],
      ),
    );
  }
}
