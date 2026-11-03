import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import 'common.dart';

class ProductDetailScreen extends StatefulWidget {
  final Json product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int qty = 1;
  bool _initializedFromCart = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromCart) {
      _initializedFromCart = true;
      final inCart = context.read<CartState>().items[widget.product['id'] as int]?.qty ?? 0;
      if (inCart > 0) {
        qty = inCart;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cart = context.watch<CartState>();
    final inCartQty = cart.items[p['id'] as int]?.qty ?? 0;
    final hasPromo = p['has_promo'] == true;
    final stock = p['stock'] as int;
    final outOfStock = stock <= 0;
    final finalPrice = p['final_price'] as int;
    final normalPrice = p['price'] as int;
    final categoryName = p['category']?['name'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Detail Produk',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 21),
            onPressed: () => snack(context, 'Tautan produk disalin!'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Gambar Produk Besar
          Container(
            height: 290,
            width: double.infinity,
            color: const Color(0xFFF8FAFC),
            child: Stack(
              children: [
                Center(
                  child: NetImage(
                    p['image_url'] as String?,
                    height: 290,
                    fit: BoxFit.contain,
                  ),
                ),
                if (hasPromo)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'DISKON ${(((normalPrice - finalPrice) / normalPrice) * 100).round()}%',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kategori & Stok Chips
                Row(
                  children: [
                    if (categoryName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          categoryName,
                          style: GoogleFonts.plusJakartaSans(
                            color: kPrimaryDark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: outOfStock ? Colors.red.shade50 : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 3.5,
                            backgroundColor: outOfStock ? Colors.red : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            outOfStock ? 'Stok Habis' : 'Sisa $stock ${p['unit']}',
                            style: GoogleFonts.plusJakartaSans(
                              color: outOfStock ? Colors.red.shade700 : kTextSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Nama Produk
                Text(
                  p['name'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Harga
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      rp(finalPrice),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: kPrimaryDark,
                      ),
                    ),
                    Text(
                      ' / ${p['unit']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasPromo) ...[
                      const SizedBox(width: 10),
                      Text(
                        rp(normalPrice),
                        style: GoogleFonts.plusJakartaSans(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 14,
                          color: kSlate400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: kBorder),
                const SizedBox(height: 18),

                // Deskripsi Produk
                Text(
                  'Deskripsi Produk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (p['description'] as String?)?.isNotEmpty == true
                      ? p['description'] as String
                      : 'Produk sembako kualitas terjamin dari Kios Aisyha. Segar, bersih, dan siap diantar langsung ke rumah Anda.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: const Color(0xFF475569),
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 24),
                // Jaminan Kios Aisyha
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: kPrimary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jaminan Kualitas Sembako',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: kTextPrimary,
                              ),
                            ),
                            Text(
                              'Barang rusak atau tidak sesuai dapat ditukar.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Banner pemberitahuan jika produk sudah ada di keranjang + Opsi Hapus Cepat
              if (inCartQty > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                          const SizedBox(width: 6),
                          Text(
                            'Sudah ada $inCartQty ${p['unit']} di keranjang',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          cart.setQty(p['id'] as int, 0);
                          snack(context, '${p['name']} dihapus dari keranjang', isSuccess: true);
                          setState(() => qty = 1);
                        },
                        child: Text(
                          'Hapus Barang',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  // Pengatur Jumlah (Jika 1, tombol minus berubah jadi ikon tempat sampah merah untuk menghapus/batal)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (qty == 1 && inCartQty > 0)
                            ? Colors.red.shade200
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          iconSize: 18,
                          tooltip: (qty == 1 && inCartQty > 0)
                              ? 'Hapus dari keranjang'
                              : (qty == 1 ? 'Batal memilih barang ini' : 'Kurangi'),
                          onPressed: () {
                            if (qty > 1) {
                              setState(() => qty--);
                              if (inCartQty > 0) {
                                cart.setQty(p['id'] as int, qty);
                              }
                            } else {
                              // Saat jumlah 1 dan ditekan ikon hapus (tempat sampah merah)
                              if (inCartQty > 0) {
                                cart.setQty(p['id'] as int, 0);
                                snack(
                                  context,
                                  '${p['name']} dihapus dari keranjang',
                                  isSuccess: true,
                                );
                                setState(() => qty = 1);
                              } else {
                                snack(context, 'Batal memilih ${p['name']}');
                                Navigator.pop(context);
                              }
                            }
                          },
                          icon: Icon(
                            qty == 1
                                ? Icons.delete_outline_rounded
                                : Icons.remove_rounded,
                            color: qty == 1
                                ? Colors.red.shade600
                                : kTextPrimary,
                            size: qty == 1 ? 20 : 18,
                          ),
                        ),
                        Text(
                          '$qty',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: kTextPrimary,
                          ),
                        ),
                        IconButton(
                          iconSize: 18,
                          tooltip: 'Tambah',
                          onPressed: qty < stock
                              ? () {
                                  setState(() => qty++);
                                  if (inCartQty > 0) {
                                    cart.setQty(p['id'] as int, qty);
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tombol Tambah / Simpan ke Keranjang
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: outOfStock
                            ? kSlate300
                            : (inCartQty > 0 ? const Color(0xFF047857) : kPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: outOfStock
                          ? null
                          : () {
                              if (inCartQty > 0) {
                                cart.setQty(p['id'] as int, qty);
                                snack(
                                  context,
                                  'Jumlah ${p['name']} diperbarui ($qty ${p['unit']})',
                                  isSuccess: true,
                                );
                              } else {
                                final ok = cart.add(p, qty);
                                if (ok) {
                                  snack(
                                    context,
                                    '$qty x ${p['name']} masuk keranjang',
                                    isSuccess: true,
                                  );
                                } else {
                                  snack(context, 'Stok tidak mencukupi');
                                }
                              }
                            },
                      icon: Icon(
                        inCartQty > 0
                            ? Icons.check_circle_outline_rounded
                            : Icons.add_shopping_cart_rounded,
                        size: 20,
                      ),
                      label: Text(
                        outOfStock
                            ? 'Stok Habis'
                            : (inCartQty > 0
                                ? 'Tersimpan ($qty) • ${rp(finalPrice * qty)}'
                                : 'Tambah • ${rp(finalPrice * qty)}'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
