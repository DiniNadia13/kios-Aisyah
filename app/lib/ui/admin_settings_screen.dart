import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../api.dart';
import '../state.dart';
import 'common.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool loading = true;
  bool saving = false;

  final storeName = TextEditingController();
  final storePhone = TextEditingController();
  final storeWhatsapp = TextEditingController();
  final storeHours = TextEditingController();
  final storeAddress = TextEditingController();

  final bankName = TextEditingController();
  final bankAccount = TextEditingController();
  final bankHolder = TextEditingController();
  final qrisName = TextEditingController();

  final freeShippingMin = TextEditingController();
  final defaultShippingFee = TextEditingController();

  String? currentQrisImage;
  File? newQrisFile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final r = Json.from(await Api.get('/admin/settings') as Map);
      storeName.text = r['store_name'] ?? 'Kios Aisyha';
      storePhone.text = r['store_phone'] ?? '0821-5430-6904';
      storeWhatsapp.text = r['store_whatsapp'] ?? '6282154306904';
      storeHours.text = r['store_hours'] ?? '07:00 - 21:00 WIB';
      storeAddress.text = r['store_address'] ?? 'Jl. Pemuda Sembako No. 8, Kios Aisyha';

      bankName.text = r['store_bank_name'] ?? 'BCA';
      bankAccount.text = r['store_bank_account'] ?? '';
      bankHolder.text = r['store_bank_holder'] ?? 'Kios Aisyha';
      qrisName.text = r['store_qris_name'] ?? 'Kios Aisyha';

      freeShippingMin.text = (r['free_shipping_min'] ?? 150000).toString();
      defaultShippingFee.text = (r['default_shipping_fee'] ?? 8000).toString();
      currentQrisImage = r['store_qris_image'];
    } catch (e) {
      if (mounted) snack(context, 'Gagal memuat pengaturan: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickQrisImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
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
                'Upload Barcode QRIS Toko',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: kPrimary),
                title: const Text('Pilih dari Galeri Foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: kPrimary),
                title: const Text('Foto Barcode dengan Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final file = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (file != null) {
      setState(() => newQrisFile = File(file.path));
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final fields = {
        'store_name': storeName.text.trim(),
        'store_phone': storePhone.text.trim(),
        'store_whatsapp': storeWhatsapp.text.trim(),
        'store_hours': storeHours.text.trim(),
        'store_address': storeAddress.text.trim(),
        'store_bank_name': bankName.text.trim(),
        'store_bank_account': bankAccount.text.trim(),
        'store_bank_holder': bankHolder.text.trim(),
        'store_qris_name': qrisName.text.trim(),
        'free_shipping_min': freeShippingMin.text.trim(),
        'default_shipping_fee': defaultShippingFee.text.trim(),
      };

      if (newQrisFile != null) {
        await Api.uploadMultipart(
          '/admin/settings',
          fields: fields,
          fileField: 'qris_photo',
          filePath: newQrisFile!.path,
          fileName: 'qris_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else {
        await Api.post('/admin/settings', fields);
      }

      if (mounted) {
        snack(context, 'Pengaturan toko & rekening berhasil disimpan!', isSuccess: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) snack(context, 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Toko & Rekening')),
        body: const Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          'Pengaturan Toko & Rekening',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Informasi Rekening Pembayaran
            _sectionCard(
              title: 'Rekening Bank Pembayaran',
              icon: Icons.account_balance_rounded,
              child: Column(
                children: [
                  _field('Nama Bank', bankName, 'Contoh: BCA / BRI / Mandiri'),
                  const SizedBox(height: 12),
                  _field('Nomor Rekening', bankAccount, 'Contoh: 82154306904', isNumber: true),
                  const SizedBox(height: 12),
                  _field('Atas Nama (Pemilik)', bankHolder, 'Contoh: Kios Aisyha'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Barcode QRIS Toko
            _sectionCard(
              title: 'Barcode QRIS Toko',
              icon: Icons.qr_code_2_rounded,
              child: Column(
                children: [
                  _field('Nama Tampilan QRIS', qrisName, 'Contoh: Kios Aisyha (NMID: ...)'),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        if (newQrisFile != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(newQrisFile!, height: 160, fit: BoxFit.contain),
                          )
                        else if (currentQrisImage != null && currentQrisImage!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(currentQrisImage!, height: 160, fit: BoxFit.contain),
                          )
                        else
                          Column(
                            children: [
                              const Icon(Icons.qr_code_scanner_rounded, size: 64, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 6),
                              Text(
                                'Belum ada foto barcode QRIS',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextSecondary),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _pickQrisImage,
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: Text(
                            newQrisFile != null || currentQrisImage != null ? 'Ganti Foto Barcode' : 'Upload Foto QRIS',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Profil Toko & WhatsApp
            _sectionCard(
              title: 'Profil Toko & Kontak',
              icon: Icons.storefront_rounded,
              child: Column(
                children: [
                  _field('Nama Toko', storeName, 'Kios Aisyha'),
                  const SizedBox(height: 12),
                  _field('Nomor WhatsApp Penerima Pesanan', storeWhatsapp, '6282154306904', isNumber: true),
                  const SizedBox(height: 12),
                  _field('Nomor Telepon Toko', storePhone, '0821-5430-6904'),
                  const SizedBox(height: 12),
                  _field('Jam Operasional', storeHours, '07:00 - 21:00 WIB'),
                  const SizedBox(height: 12),
                  _field('Alamat Lengkap Kios', storeAddress, 'Jl. Pemuda Sembako No. 8, Kios Aisyha', maxLines: 2),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Pengaturan Ongkir
            _sectionCard(
              title: 'Ketentuan Ongkir',
              icon: Icons.local_shipping_outlined,
              child: Column(
                children: [
                  _field('Syarat Min. Belanja Gratis Ongkir (Rp)', freeShippingMin, '150000', isNumber: true),
                  const SizedBox(height: 12),
                  _field('Ongkir Standar Jika Di Bawah Syarat (Rp)', defaultShippingFee, '8000', isNumber: true),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: saving ? null : _save,
                child: Text(
                  saving ? 'Menyimpan...' : 'Simpan Semua Pengaturan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
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

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: kPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, String hint, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }
}
