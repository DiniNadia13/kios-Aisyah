import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../state.dart';
import 'product_detail.dart';

// Palette Warna Modern Kios Aisyha (Perpaduan Modern Emerald 3D & Warm Merchant)
const kPrimary = Color(0xFF059669);      // Emerald Green segar
const kPrimaryDark = Color(0xFF047857);  // Deep Forest Emerald
const kPrimaryLight = Color(0xFFE6F4EA); // Mint pastel hangat
const kSecondary = Color(0xFFFF5722);    // Sunset Coral untuk promo & flash sale
const kAccentAmber = Color(0xFFF59E0B);  // Emas Padi untuk gratis ongkir & rating
const kAccentWarm = Color(0xFFD97706);   // Warm caramel accent
const kBg = Color(0xFFF4F6F4);           // Background hangat (kontras tinggi dengan kartu 3D)
const kSurface = Colors.white;           // Kartu putih bersih
const kTextPrimary = Color(0xFF0F172A);  // Slate 900
const kTextSecondary = Color(0xFF64748B);// Slate 500
const kSlate300 = Color(0xFFCBD5E1);
const kSlate400 = Color(0xFF94A3B8);
const kBorder = Color(0xFFE2E8F0);       // Slate 200

// Helper Bayangan Timbul 3D (Dual-Layer Soft Glow & Tactile Shadow)
List<BoxShadow> tactileCardShadow({Color? glowColor}) => [
  const BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 18,
    offset: Offset(0, 8),
  ),
  BoxShadow(
    color: (glowColor ?? kPrimary).withOpacity(0.06),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
];

List<BoxShadow> tactileBtnShadow({Color baseColor = const Color(0xFF047857)}) => [
  BoxShadow(
    color: baseColor,
    offset: const Offset(0, 3), // 3D bevel depth
    blurRadius: 0,
  ),
  BoxShadow(
    color: baseColor.withOpacity(0.32),
    offset: const Offset(0, 5),
    blurRadius: 10,
  ),
];

String rp(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp$b';
}

void snack(BuildContext c, String msg, {bool isSuccess = false}) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isSuccess ? kPrimaryDark : const Color(0xFF1E293B),
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: isSuccess ? const Color(0xFF6EE7B7) : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}

class NetImage extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double borderRadius;

  const NetImage(
    this.url, {
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_rounded, color: kSlate300, size: 36),
          const SizedBox(height: 4),
          Text(
            'Kios Aisyha',
            style: GoogleFonts.plusJakartaSans(
              color: kSlate400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url!,
        height: height,
        width: width ?? double.infinity,
        fit: fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            width: width ?? double.infinity,
            color: const Color(0xFFF8FAFC),
            alignment: Alignment.center,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(kPrimary.withOpacity(0.5)),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Json product;
  const ProductCard(this.product, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final hasPromo = p['has_promo'] == true;
    final outOfStock = (p['stock'] as int) <= 0;
    final cart = context.watch<CartState>();
    final cartItem = cart.items[p['id'] as int];
    final inCartQty = cartItem?.qty ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDF2F7), width: 1.2),
        boxShadow: tactileCardShadow(glowColor: hasPromo ? kSecondary : kPrimary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Produk & Badge Diskon Timbul
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: NetImage(
                        p['image_url'] as String?,
                        borderRadius: 16,
                      ),
                    ),
                    if (hasPromo)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                              topRight: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF416C).withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 1),
                              Text(
                                '-${(((p['price'] - p['final_price']) / p['price']) * 100).round()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (outOfStock)
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Habis',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Detail Produk
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 4, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag Satuan Hangat (Pill)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD1FAE5), width: 0.8),
                      ),
                      child: Text(
                        'per ${p['unit']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Nama Produk
                    Text(
                      p['name'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: kTextPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Harga Coret (jika ada promo)
                    if (hasPromo)
                      Text(
                        rp(p['price']),
                        style: GoogleFonts.plusJakartaSans(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 11,
                          color: kSlate400,
                        ),
                      ),

                    // Baris Harga & Tombol Tambah Timbul 3D
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            rp(p['final_price']),
                            style: GoogleFonts.plusJakartaSans(
                              color: kPrimaryDark,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        // Tombol Tambah ke Keranjang Timbul 3D (Tactile Button)
                        if (!outOfStock)
                          GestureDetector(
                            onTap: () {
                              final ok = cart.add(p);
                              if (ok) {
                                snack(context, '${p['name']} ditambah ke keranjang', isSuccess: true);
                              } else {
                                snack(context, 'Stok maksimal tercapai');
                              }
                            },
                            onLongPress: inCartQty > 0
                                ? () {
                                    cart.setQty(p['id'] as int, 0);
                                    snack(context, '${p['name']} dihapus dari keranjang', isSuccess: true);
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: inCartQty > 0
                                      ? [const Color(0xFF047857), const Color(0xFF065F46)]
                                      : [const Color(0xFF10B981), const Color(0xFF059669)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: inCartQty > 0
                                        ? const Color(0xFF024430)
                                        : const Color(0xFF047857),
                                    offset: const Offset(0, 2.5), // Efek timbul alas 3D
                                    blurRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: kPrimary.withOpacity(0.28),
                                    offset: const Offset(0, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: inCartQty > 0
                                  ? Text(
                                      '$inCartQty',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  : const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                            ),
                          ),
                      ],
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
}

class ProductGrid extends StatelessWidget {
  final List<Json> products;
  final bool shrink;
  const ProductGrid(this.products, {super.key, this.shrink = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.67,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(products[i]),
    );
  }
}

// Icon & Warna Kategori Khusus Sembako
IconData getCategoryIcon(String name) {
  final l = name.toLowerCase();
  if (l.contains('beras')) return Icons.grain_rounded;
  if (l.contains('minyak')) return Icons.water_drop_rounded;
  if (l.contains('gula') || l.contains('tepung')) return Icons.bakery_dining_rounded;
  if (l.contains('telur')) return Icons.egg_rounded;
  if (l.contains('mie') || l.contains('instan')) return Icons.ramen_dining_rounded;
  if (l.contains('bumbu')) return Icons.soup_kitchen_rounded;
  if (l.contains('minuman') || l.contains('kopi') || l.contains('teh')) return Icons.local_cafe_rounded;
  if (l.contains('bersih') || l.contains('sabun')) return Icons.cleaning_services_rounded;
  return Icons.storefront_rounded;
}

Color getCategoryColor(String name) {
  final l = name.toLowerCase();
  if (l.contains('beras')) return const Color(0xFFF59E0B);
  if (l.contains('minyak')) return const Color(0xFFEA580C);
  if (l.contains('gula') || l.contains('tepung')) return const Color(0xFFEC4899);
  if (l.contains('telur')) return const Color(0xFFEAB308);
  if (l.contains('mie') || l.contains('instan')) return const Color(0xFFEF4444);
  if (l.contains('bumbu')) return const Color(0xFF10B981);
  if (l.contains('minuman')) return const Color(0xFF06B6D4);
  if (l.contains('bersih')) return const Color(0xFF8B5CF6);
  return kPrimary;
}

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry(this.message, this.onRetry, {super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off_rounded, size: 40, color: Colors.red.shade400),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: kTextSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
}

String statusLabel(String s) => const {
      'pending': 'Menunggu Konfirmasi',
      'processing': 'Sedang Diproses',
      'delivering': 'Sedang Diantar 🛵',
      'completed': 'Selesai ✓',
      'cancelled': 'Dibatalkan',
    }[s] ??
    s;

Future<void> openWhatsapp({
  required String message,
  String phone = storeWhatsapp,
  BuildContext? context,
}) async {
  final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
  final url = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
  try {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && context != null) {
      await Clipboard.setData(ClipboardData(text: message));
      if (context.mounted) {
        snack(context, 'WhatsApp tidak terbuka. Pesan disalin ke clipboard!');
      }
    }
  } catch (_) {
    if (context != null) {
      await Clipboard.setData(ClipboardData(text: message));
      if (context.mounted) {
        snack(context, 'Pesan pesanan berhasil disalin ke clipboard!');
      }
    }
  }
}

String formatOrderForWhatsapp(Map<String, dynamic> o) {
  final sb = StringBuffer()
    ..writeln('Halo Kios Aisyha, saya ingin konfirmasi pesanan:')
    ..writeln('📦 *No. Pesanan:* ${o['code']}')
    ..writeln('👤 *Pemesan:* ${o['recipient'] ?? 'Pelanggan'} (${o['phone'] ?? '-'})')
    ..writeln('🛵 *Metode:* ${o['delivery_method'] == 'pickup' ? 'Ambil di Toko' : 'Diantar ke Rumah'}');

  if (o['delivery_slot'] != null) {
    sb.writeln('⏰ *Waktu Pengantaran:* ${o['delivery_slot']}');
  }
  if (o['address'] != null) {
    sb.writeln('📍 *Alamat:* ${o['address']}');
  }

  sb.writeln('\n📋 *Daftar Belanja:*');
  if (o['items'] is List) {
    for (final it in (o['items'] as List)) {
      final name = it['name'] ?? 'Produk';
      final qty = it['quantity'] ?? 1;
      final sub = it['subtotal'] != null ? rp(it['subtotal']) : '';
      sb.writeln('• $name x$qty = $sub');
    }
  }

  sb.writeln('\n💰 *Rincian Pembayaran:*');
  if (o['subtotal'] != null) sb.writeln('• Subtotal: ${rp(o['subtotal'])}');
  if ((o['discount'] ?? 0) > 0) sb.writeln('• Diskon: -${rp(o['discount'])}');
  final fee = o['shipping_fee'] ?? 0;
  sb.writeln('• Ongkir: ${fee == 0 ? "GRATIS" : rp(fee)}');
  if (o['total'] != null) sb.writeln('• *TOTAL AKHIR:* ${rp(o['total'])}');
  sb.writeln('• Metode Bayar: ${o['payment_method'].toString().toUpperCase()}');

  if (o['note'] != null && o['note'].toString().isNotEmpty) {
    sb.writeln('\n📝 *Catatan:* ${o['note']}');
  }

  sb.writeln('\nMohon segera diproses ya, terima kasih!');
  return sb.toString();
}

void showCustomGroceryRequestSheet(BuildContext context, {String? userName}) {
  final itemController = TextEditingController();
  final qtyController = TextEditingController();
  final notesController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Titip Belanja Sembako',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kTextPrimary,
                        ),
                      ),
                      Text(
                        'Butuh sembako yang belum terdaftar di aplikasi?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Nama Sembako & Merk',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: itemController,
              decoration: const InputDecoration(
                hintText: 'Misal: Beras Pandan Wangi 10kg, Terigu Cakra 1kg',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Perkiraan Jumlah / Takaran',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(
                hintText: 'Misal: 2 karung / 3 botol / 1 karton',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Catatan Khusus (Opsional)',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Misal: Tolong carikan yang tanggal expired-nya jauh',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final item = itemController.text.trim();
                  if (item.isEmpty) {
                    snack(context, 'Mohon sebutkan nama sembako yang dicari');
                    return;
                  }
                  final qty = qtyController.text.trim();
                  final notes = notesController.text.trim();
                  final user = userName ?? 'Pelanggan Kios Aisyha';

                  final msg = StringBuffer()
                    ..writeln('Halo Admin Kios Aisyha, saya mau titip belanja / request sembako:')
                    ..writeln('👤 Pemesan: $user')
                    ..writeln('📦 Barang: $item');
                  if (qty.isNotEmpty) msg.writeln('🔢 Jumlah: $qty');
                  if (notes.isNotEmpty) msg.writeln('📝 Catatan: $notes');
                  msg.writeln('Apakah ada stoknya atau bisa dicarikan? Terima kasih!');

                  Navigator.pop(ctx);
                  openWhatsapp(message: msg.toString(), context: context);
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Kirim Request via WhatsApp Toko',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
