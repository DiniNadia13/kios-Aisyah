import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../api.dart';
import '../state.dart';
import 'common.dart';

class AdminProductFormScreen extends StatefulWidget {
  final Json? product; // null jika tambah baru
  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final promoPriceCtrl = TextEditingController();
  final stockCtrl = TextEditingController(text: '10');
  final descCtrl = TextEditingController();

  List<Json> categories = [];
  int? categoryId;
  String unit = 'kg';
  bool isFlashSale = false;
  bool isActive = true;

  XFile? pickedImage;
  Uint8List? pickedImageBytes;
  bool saving = false;

  static const popularUnits = [
    'kg',
    'liter',
    'sak',
    'pcs',
    'dus',
    'bungkus',
    'botol',
    'renteng',
    'ikat',
    'pak',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    final p = widget.product;
    if (p != null) {
      nameCtrl.text = p['name'] ?? '';
      priceCtrl.text = '${p['price'] ?? ''}';
      promoPriceCtrl.text = p['promo_price'] != null ? '${p['promo_price']}' : '';
      stockCtrl.text = '${p['stock'] ?? 0}';
      descCtrl.text = p['description'] ?? '';
      categoryId = p['category_id'] as int?;
      unit = (p['unit'] as String?) ?? 'kg';
      isFlashSale = p['is_flash_sale'] == true;
      isActive = p['is_active'] != false;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final r = await Api.get('/categories') as List;
      if (mounted) {
        setState(() {
          categories = r.map((e) => Json.from(e as Map)).toList();
          if (categoryId == null && categories.isNotEmpty) {
            categoryId = categories.first['id'] as int;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        pickedImage = file;
        pickedImageBytes = bytes;
      });
    } catch (e) {
      if (mounted) snack(context, 'Gagal memilih foto: $e');
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Foto Produk',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: kPrimaryDark),
                title: const Text('Ambil Foto Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: kPrimaryDark),
                title: const Text('Pilih dari Galeri HP'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    if (categoryId == null) {
      snack(context, 'Pilih kategori sembako terlebih dahulu');
      return;
    }

    setState(() => saving = true);

    final fields = <String, String>{
      'name': nameCtrl.text.trim(),
      'category_id': '$categoryId',
      'unit': unit,
      'price': priceCtrl.text.trim(),
      if (promoPriceCtrl.text.trim().isNotEmpty)
        'promo_price': promoPriceCtrl.text.trim(),
      'stock': stockCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'is_flash_sale': isFlashSale ? '1' : '0',
      'is_active': isActive ? '1' : '0',
    };

    try {
      final isEdit = widget.product != null;
      final path = isEdit ? '/admin/products/${widget.product!['id']}' : '/admin/products';

      if (pickedImage != null) {
        await Api.uploadMultipart(
          path,
          fields: fields,
          fileField: 'photo',
          filePath: kIsWeb ? null : pickedImage!.path,
          fileBytes: pickedImageBytes,
          fileName: pickedImage!.name,
        );
      } else {
        await Api.post(path, fields);
      }

      if (mounted) {
        snack(
          context,
          isEdit ? 'Produk berhasil diperbarui!' : 'Produk sembako berhasil ditambahkan!',
          isSuccess: true,
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    } catch (e) {
      if (mounted) snack(context, 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Ubah Sembako' : 'Tambah Sembako Baru',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Kotak Upload Foto Produk
            Center(
              child: GestureDetector(
                onTap: _showImagePickerSheet,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildImagePreview(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: _showImagePickerSheet,
                icon: const Icon(Icons.camera_alt_outlined, size: 18, color: kPrimaryDark),
                label: Text(
                  pickedImage != null || widget.product?['image_url'] != null
                      ? 'Ganti Foto Sembako'
                      : 'Ambil / Unggah Foto Produk',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryDark,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Data Utama Produk
            _sectionContainer(
              title: 'Informasi Produk',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Nama Sembako Pokok *'),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Misal: Beras Premium Raja Ramos 5kg',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nama sembako wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  _label('Kategori Sembako *'),
                  DropdownButtonFormField<int>(
                    value: categoryId,
                    decoration: const InputDecoration(),
                    items: categories.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text(c['name'] as String),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => categoryId = v),
                    validator: (v) => v == null ? 'Pilih kategori' : null,
                  ),
                  const SizedBox(height: 14),

                  _label('Satuan Kemasan / Takaran *'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: popularUnits.map((u) {
                      final selected = unit == u;
                      return ChoiceChip(
                        label: Text(u),
                        selected: selected,
                        onSelected: (_) => setState(() => unit = u),
                        selectedColor: kPrimaryLight,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          color: selected ? kPrimaryDark : kTextPrimary,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Harga & Stok
            _sectionContainer(
              title: 'Harga & Jumlah Stok',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Harga Normal (Rp) *'),
                            TextFormField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'Misal: 74000'),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Harga Promo (Rp)'),
                            TextFormField(
                              controller: promoPriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Opsional (diskon)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Jumlah Stok di Kios *'),
                            TextFormField(
                              controller: stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'Misal: 20'),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Pengaturan Tampilan
            _sectionContainer(
              title: 'Pengaturan Etalase',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: kPrimary,
                    title: Text(
                      'Tampilkan di Etalase (Aktif)',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'Jika mati, pembeli tidak akan melihat produk ini di katalog',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: kTextSecondary,
                      ),
                    ),
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                  ),
                  const Divider(height: 12, color: kBorder),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFFFF5722),
                    title: Text(
                      'Masuk ke Bagian Flash Sale',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'Tampil di baris teratas promo spesial beranda',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: kTextSecondary,
                      ),
                    ),
                    value: isFlashSale,
                    onChanged: (v) => setState(() => isFlashSale = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. Deskripsi (Opsional)
            _sectionContainer(
              title: 'Keterangan Tambahan (Opsional)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Misal: Beras pulen wangi, panen baru, tanpa pengawet atau pemutih.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  saving ? 'Menyimpan Sembako...' : (isEdit ? 'Simpan Perubahan' : 'Tambahkan ke Katalog Toko'),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (pickedImageBytes != null) {
      return Image.memory(
        pickedImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    if (!kIsWeb && pickedImage != null) {
      return Image.file(
        File(pickedImage!.path),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    if (widget.product?['image_url'] != null) {
      return NetImage(widget.product!['image_url'] as String?, fit: BoxFit.cover);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kPrimaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_a_photo_rounded, color: kPrimaryDark, size: 36),
        ),
        const SizedBox(height: 10),
        Text(
          'Sentuh untuk Ambil / Unggah Foto',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
            fontSize: 13,
          ),
        ),
        Text(
          'Kamera langsung atau galeri HP (Maks. 5MB)',
          style: GoogleFonts.plusJakartaSans(
            color: kTextSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          t,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: kTextPrimary,
          ),
        ),
      );

  Widget _sectionContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: kPrimaryDark,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

