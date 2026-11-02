import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api.dart';
import '../state.dart';
import 'catalog_screen.dart';
import 'common.dart';
import 'product_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Json? data;
  String? error;
  bool popupShown = false;
  final pageController = PageController();
  Timer? timer;
  int bannerIndex = 0;
  int? selectedCategoryId; // Untuk filter kategori langsung di beranda

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final n = (data?['banners'] as List?)?.length ?? 0;
      if (n > 1 && pageController.hasClients) {
        pageController.animateToPage(
          (bannerIndex + 1) % n,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => error = null);
    try {
      final r = Json.from(await Api.get('/home') as Map);
      if (!mounted) return;
      setState(() => data = r);
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePopup());
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  void _maybePopup() {
    final popup = data?['popup'];
    if (popup == null || popupShown || !mounted) return;
    popupShown = true;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _openLink(Json.from(popup as Map));
                  },
                  child: NetImage(popup['image_url'] as String?, height: 280),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(Json b) async {
    final type = b['link_type'];
    final value = b['link_value']?.toString();
    if (value == null || value.isEmpty) return;
    if (type == 'product') {
      try {
        final p = Json.from(await Api.get('/products/$value') as Map);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
        );
      } catch (_) {}
    } else if (type == 'category') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CatalogScreen(categoryId: int.tryParse(value)),
        ),
      );
    } else if (type == 'voucher') {
      Clipboard.setData(ClipboardData(text: value));
      snack(context, 'Kode voucher $value berhasil disalin!', isSuccess: true);
    }
  }

  List<Json> _list(String key) =>
      ((data?[key] as List?) ?? []).map((e) => Json.from(e as Map)).toList();

  @override
  Widget build(BuildContext context) {
    if (error != null && data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kios Aisyha')),
        body: ErrorRetry(error!, _load),
      );
    }
    if (data == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: kPrimary),
        ),
      );
    }

    final banners = _list('banners');
    final flash = _list('flash_sale');
    final categories = _list('categories');
    final allProducts = _list('best_sellers');

    // Filter produk berdasarkan kategori jika dipilih
    final displayedProducts = selectedCategoryId == null
        ? allProducts
        : allProducts
            .where((p) => p['category_id'] == selectedCategoryId)
            .toList();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimary,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header Minimalis & Rapi
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: kPrimaryDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kios Aisyha',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: kTextPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Buka 07:00 - 21:00 • Sembako Murah',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: kTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Tombol WhatsApp Toko (Rapi di Header, tidak menutupi produk)
                      IconButton(
                        tooltip: 'Chat WhatsApp Toko',
                        onPressed: () => openWhatsapp(
                          message: 'Halo Kios Aisyha, saya mau tanya info stok sembako hari ini.',
                          context: context,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFECFDF5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFA7F3D0)),
                          ),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF059669),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Bar Pencarian Bersih & Nyaman
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CatalogScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x04000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: kSlate400, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cari beras, minyak goreng, gula, telur...',
                              style: GoogleFonts.plusJakartaSans(
                                color: kSlate400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Info Ringkas Gratis Ongkir (Satu Baris, Rapi)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          color: kPrimaryDark,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gratis Ongkir untuk belanja sembako min. Rp150.000',
                            style: GoogleFonts.plusJakartaSans(
                              color: kPrimaryDark,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Banner Carousel Bersih
              if (banners.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 135,
                          child: PageView.builder(
                            controller: pageController,
                            itemCount: banners.length,
                            onPageChanged: (i) => setState(() => bannerIndex = i),
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: GestureDetector(
                                onTap: () => _openLink(banners[i]),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x08000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: NetImage(
                                    banners[i]['image_url'] as String?,
                                    borderRadius: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (banners.length > 1) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              banners.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                height: 4,
                                width: bannerIndex == i ? 14 : 5,
                                decoration: BoxDecoration(
                                  color: bannerIndex == i ? kPrimary : kSlate300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // 5. Pilihan Kategori Sembako (Pills Ramping)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final isAll = i == 0;
                        final isSelected = isAll
                            ? selectedCategoryId == null
                            : selectedCategoryId == categories[i - 1]['id'];
                        final label = isAll ? 'Semua' : (categories[i - 1]['name'] as String);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategoryId = isAll ? null : (categories[i - 1]['id'] as int);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? kPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? kPrimary : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: kPrimary.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : kTextPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 6. Flash Sale (Hanya Tampil Jika Ada Promo Aktif)
              if (flash.isNotEmpty && selectedCategoryId == null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PROMO',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Harga Spesial Hari Ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: flash.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(
                        width: 155,
                        child: ProductCard(flash[i]),
                      ),
                    ),
                  ),
                ),
              ],

              // 7. Daftar Produk Sembako
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedCategoryId == null
                            ? 'Daftar Sembako'
                            : (categories.firstWhere(
                                (c) => c['id'] == selectedCategoryId,
                                orElse: () => {'name': 'Sembako'},
                              )['name'] as String),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CatalogScreen(categoryId: selectedCategoryId),
                          ),
                        ),
                        child: Text(
                          'Katalog Lengkap →',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Grid Produk 2 Kolom Bersih
              if (displayedProducts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Belum ada produk di kategori ini',
                        style: GoogleFonts.plusJakartaSans(
                          color: kTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.67,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(displayedProducts[i]),
                      childCount: displayedProducts.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
