import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../state.dart';
import 'auth_screen.dart';
import 'checkout_screen.dart';
import 'common.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Json> upsellItems = [];
  bool loadingUpsell = false;

  @override
  void initState() {
    super.initState();
    _loadUpsell();
  }

  Future<void> _loadUpsell() async {
    setState(() => loadingUpsell = true);
    try {
      final r = await Api.get('/cart-upsell');
      if (mounted && r is List) {
        setState(() => upsellItems = r.map((e) => Json.from(e as Map)).toList());
      }
    } catch (_) {}
    if (mounted) setState(() => loadingUpsell = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final auth = context.watch<AuthState>();
    final items = cart.items.values.toList();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          'Keranjang Belanja',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => cart.clear(),
              child: Text(
                'Kosongkan',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: items.isEmpty
          ? Center(
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
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 56,
                        color: kPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Keranjang Masih Kosong',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Yuk mulai belanja sembako kebutuhan rumah tangga Anda sekarang!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Banner Progress Gratis Ongkir Modern
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: cart.remainingForFree == 0
                          ? [const Color(0xFF047857), const Color(0xFF10B981)]
                          : [const Color(0xFF1E293B), const Color(0xFF334155)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            cart.remainingForFree == 0
                                ? Icons.verified_rounded
                                : Icons.local_shipping_rounded,
                            color: cart.remainingForFree == 0
                                ? const Color(0xFFFEF08A)
                                : Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cart.remainingForFree == 0
                                  ? '🎉 Selamat! Anda Mendapatkan GRATIS ONGKIR!'
                                  : 'Belanja ${rp(cart.remainingForFree)} lagi untuk GRATIS ONGKIR',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (cart.subtotal / cart.freeShippingMin).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            cart.remainingForFree == 0
                                ? const Color(0xFFFEF08A)
                                : kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Genapkan Belanjaan untuk Gratis Ongkir (Smart Cart Upsell)
                if (cart.remainingForFree > 0 && upsellItems.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Genapkan untuk Gratis Ongkir!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 84,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: upsellItems.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (_, idx) {
                              final prod = upsellItems[idx];
                              final finalPrice = prod['final_price'] ?? prod['price'];
                              return Container(
                                width: 170,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: NetImage(
                                          prod['image_url'] as String?,
                                          borderRadius: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            prod['name'] as String,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            rp(finalPrice),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: kPrimaryDark,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          InkWell(
                                            onTap: () {
                                              final ok = cart.add(prod, 1);
                                              if (ok) {
                                                snack(
                                                  context,
                                                  '${prod['name']} ditambahkan!',
                                                  isSuccess: true,
                                                );
                                              } else {
                                                snack(context, 'Stok habis');
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: kPrimary,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '+ Tambah',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Daftar Item di Keranjang
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      final p = it.product;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x04000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Thumbnail Produk
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: NetImage(
                                p['image_url'] as String?,
                                borderRadius: 12,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Informasi Produk
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: kTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${rp(it.price)} / ${p['unit']}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: kTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rp(it.subtotal),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: kPrimaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tombol Stepper Jumlah
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                    iconSize: 17,
                                    onPressed: () => cart.setQty(it.id, it.qty - 1),
                                    icon: Icon(
                                      it.qty == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                                      color: it.qty == 1 ? Colors.red.shade600 : kTextPrimary,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      '${it.qty}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                    iconSize: 17,
                                    onPressed: () => cart.setQty(it.id, it.qty + 1),
                                    icon: const Icon(Icons.add_rounded, color: kTextPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0E000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: kTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            rp(cart.subtotal),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: kPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (!auth.loggedIn) {
                          final ok = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                          if (ok != true || !context.mounted) return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            'Checkout',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
