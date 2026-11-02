import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api.dart';
import '../state.dart';
import 'common.dart';

class CatalogScreen extends StatefulWidget {
  final int? categoryId;
  final String? title;
  const CatalogScreen({super.key, this.categoryId, this.title});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final search = TextEditingController();
  List<Json> categories = [];
  List<Json> products = [];
  int? categoryId;
  String sort = 'latest';
  int page = 1;
  int lastPage = 1;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    categoryId = widget.categoryId;
    _loadCategories();
    _load(reset: true);
  }

  Future<void> _loadCategories() async {
    try {
      final r = await Api.get('/categories') as List;
      setState(() => categories = r.map((e) => Json.from(e as Map)).toList());
    } catch (_) {}
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      page = 1;
      products = [];
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await Api.get('/products', {
        'page': '$page',
        'sort': sort,
        if (categoryId != null) 'category_id': '$categoryId',
        if (search.text.trim().isNotEmpty) 'q': search.text.trim(),
      });
      lastPage = r['last_page'] as int;
      products.addAll((r['data'] as List).map((e) => Json.from(e as Map)));
    } on ApiException catch (e) {
      error = e.message;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: widget.title != null ? 'Cari di ${widget.title}...' : 'Cari sembako...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kTextSecondary),
              suffixIcon: search.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        search.clear();
                        _load(reset: true);
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: (_) => _load(reset: true),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sort_rounded, size: 20, color: kTextPrimary),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (v) {
              sort = v;
              _load(reset: true);
            },
            itemBuilder: (_) => [
              _sortItem('latest', 'Terbaru'),
              _sortItem('best', 'Terlaris'),
              _sortItem('price_asc', 'Harga Terendah'),
              _sortItem('price_desc', 'Harga Tertinggi'),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Kategori Horizontal Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _chip('Semua', null),
                  for (final c in categories) _chip(c['name'] as String, c['id'] as int),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: kBorder),

          // Daftar Produk Grid
          Expanded(child: _body()),
        ],
      ),
    );
  }

  PopupMenuItem<String> _sortItem(String val, String label) {
    final active = sort == val;
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(
            active ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: active ? kPrimary : kTextSecondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? kPrimaryDark : kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int? id) {
    final selected = categoryId == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: () {
          setState(() => categoryId = id);
          _load(reset: true);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? kPrimary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              color: selected ? Colors.white : kTextSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (error != null && products.isEmpty) {
      return ErrorRetry(error!, () => _load(reset: true));
    }
    if (loading && products.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 48, color: kPrimary),
            ),
            const SizedBox(height: 14),
            Text(
              'Produk Tidak Ditemukan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba kata kunci lain atau titip belanja sembako ke admin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => showCustomGroceryRequestSheet(context),
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(
                'Titip Belanja / Request Sembako',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 6),
        ProductGrid(products, shrink: true),
        if (page < lastPage)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryDark,
                side: const BorderSide(color: kPrimary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: loading
                  ? null
                  : () {
                      page++;
                      _load();
                    },
              child: Text(
                loading ? 'Memuat...' : 'Muat Lebih Banyak',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
