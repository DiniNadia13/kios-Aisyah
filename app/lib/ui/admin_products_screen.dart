import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api.dart';
import '../state.dart';
import 'admin_product_form.dart';
import 'common.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Json> products = [];
  List<Json> categories = [];
  int? selectedCategory;
  final searchCtrl = TextEditingController();
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _load();
  }

  Future<void> _loadCategories() async {
    try {
      final r = await Api.get('/categories') as List;
      if (mounted) {
        setState(() => categories = r.map((e) => Json.from(e as Map)).toList());
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final q = <String, String>{};
      if (selectedCategory != null) q['category_id'] = '$selectedCategory';
      if (searchCtrl.text.trim().isNotEmpty) q['q'] = searchCtrl.text.trim();

      final r = await Api.get('/admin/products', q) as List;
      if (mounted) {
        setState(() {
          products = r.map((e) => Json.from(e as Map)).toList();
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

  Future<void> _toggleActive(Json p) async {
    try {
      final updated = await Api.post('/admin/products/${p['id']}/toggle');
      if (mounted) {
        final active = updated['is_active'] == true;
        snack(
          context,
          active
              ? '${p['name']} diaktifkan di etalase'
              : '${p['name']} dinonaktifkan (disembunyikan)',
          isSuccess: active,
        );
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    }
  }

  Future<void> _delete(Json p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Sembako Ini?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${p['name']}" dari katalog toko Kios Aisyha?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Produk'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await Api.delete('/admin/products/${p['id']}');
      if (mounted) {
        snack(context, '${p['name']} berhasil dihapus', isSuccess: true);
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
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
              'Kelola Produk Sembako',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              '${products.length} sembako terdaftar',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kPrimaryDark),
            tooltip: 'Segarkan',
            onPressed: _load,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () async {
          final refresh = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AdminProductFormScreen()),
          );
          if (refresh == true) _load();
        },
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'Tambah Sembako',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            // 1. Kotak Pencarian
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: searchCtrl,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari nama sembako...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kSlate400),
                    suffixIcon: searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              searchCtrl.clear();
                              _load();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
            ),

            // 2. Filter Kategori Pills
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip('Semua Kategori', null),
                  for (final c in categories)
                    _filterChip(c['name'] as String, c['id'] as int),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Daftar Produk
            if (loading && products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(50),
                child: Center(child: CircularProgressIndicator(color: kPrimary)),
              )
            else if (error != null && products.isEmpty)
              ErrorRetry(error!, _load)
            else if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.all(50),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 48, color: kSlate300),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada sembako di kategori ini',
                        style: GoogleFonts.plusJakartaSans(
                          color: kTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          final refresh = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminProductFormScreen()),
                          );
                          if (refresh == true) _load();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Produk Sekarang'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _buildProductAdminCard(products[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, int? id) {
    final selected = selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => selectedCategory = id);
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

  Widget _buildProductAdminCard(Json p) {
    final isActive = p['is_active'] == true;
    final stock = (p['stock'] as num?)?.toInt() ?? 0;
    final price = (p['price'] as num?)?.toInt() ?? 0;
    final promoPrice = (p['promo_price'] as num?)?.toInt();
    final unit = (p['unit'] as String?) ?? 'pcs';
    final hasPromo = promoPrice != null && promoPrice < price;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFFF1F5F9) : const Color(0xFFFCA5A5),
          width: isActive ? 1 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto Thumbnail
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: NetImage(p['image_url'] as String?, borderRadius: 12),
                ),
              ),
              if (!isActive)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'TIDAK\nAKTIF',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Detail Sembako
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p['name'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: kTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Harga & Promo
                Row(
                  children: [
                    Text(
                      rp(hasPromo ? promoPrice : price),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: kPrimaryDark,
                      ),
                    ),
                    Text(
                      ' / $unit',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: kTextSecondary),
                    ),
                    if (hasPromo) ...[
                      const SizedBox(width: 6),
                      Text(
                        rp(price),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: kSlate400,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Stok & Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: stock <= 5 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Stok: $stock $unit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: stock <= 5 ? Colors.red.shade700 : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                    if (p['is_flash_sale'] == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '⚡ Flash Sale',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Tombol Aksi (Ubah, Toggle Aktif, Hapus)
          Column(
            children: [
              IconButton(
                iconSize: 19,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.edit_outlined, color: kPrimaryDark),
                tooltip: 'Ubah Data & Foto',
                onPressed: () async {
                  final refresh = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminProductFormScreen(product: p),
                    ),
                  );
                  if (refresh == true) _load();
                },
              ),
              IconButton(
                iconSize: 19,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: isActive ? const Color(0xFF10B981) : kSlate400,
                ),
                tooltip: isActive ? 'Sembunyikan dari Etalase' : 'Tampilkan di Etalase',
                onPressed: () => _toggleActive(p),
              ),
              IconButton(
                iconSize: 19,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                tooltip: 'Hapus Sembako',
                onPressed: () => _delete(p),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

