import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../config.dart';
import '../sound_helper.dart';
import '../state.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_settings_screen.dart';
import 'auth_screen.dart';
import 'common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!auth.loggedIn) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          title: Text(
            'Akun Saya',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: Center(
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
                  child: const Icon(Icons.person_outline_rounded, size: 56, color: kPrimaryDark),
                ),
                const SizedBox(height: 18),
                Text(
                  'Masuk ke Akun Anda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Simpan alamat pengiriman, gunakan voucher promo, dan pantau pesanan sembako Anda.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextSecondary),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Masuk / Daftar Akun'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = auth.user!;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          'Akun Saya',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF047857), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (user['phone'] ?? '') as String,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFD1FAE5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Khusus Akun Admin: Panel Pemilik Kios
          if (auth.isAdmin) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBBF7D0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF047857)],
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'PANEL PEMILIK KIOS (ADMIN)',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _menuTile(
                    icon: Icons.receipt_long_rounded,
                    iconColor: kPrimaryDark,
                    title: 'Kelola Pesanan Masuk',
                    subtitle: 'Setujui pesanan pelanggan & status kurir',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56, color: kBorder),
                  _menuTile(
                    icon: Icons.inventory_2_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: 'Kelola Produk & Foto Sembako',
                    subtitle: 'Tambah barang baru, unggah foto, ubah harga & stok',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56, color: kBorder),
                  _menuTile(
                    icon: Icons.store_mall_directory_rounded,
                    iconColor: const Color(0xFFD97706),
                    title: 'Pengaturan Toko & Rekening Bayar',
                    subtitle: 'Atur rekening BCA/BRI/Mandiri, barcode QRIS, dan ongkir',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56, color: kBorder),
                  _menuTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFFE11D48),
                    title: 'Tes Suara & Notifikasi Pesanan',
                    subtitle: 'Uji bel kasir & aktifkan izin notifikasi browser',
                    onTap: () {
                      playOrderChime(
                        orderCode: 'TEST-01',
                        customerName: 'Uji Coba Admin',
                        total: 'Rp50.000',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF047857),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: const Text(
                            '🔔 Bel kasir berbunyi! Jika browser meminta izin notifikasi, klik "Izinkan / Allow".',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Menu Options
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                _menuTile(
                  icon: Icons.location_on_outlined,
                  title: 'Alamat Pengiriman',
                  subtitle: 'Atur alamat antar rumah atau kantor',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressListScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 56, color: kBorder),
                _menuTile(
                  icon: Icons.support_agent_rounded,
                  title: 'Bantuan & WhatsApp Toko',
                  subtitle: 'Hubungi Kios Aisyha langsung via WA',
                  onTap: () => snack(context, 'WhatsApp Kios Aisyha: +$storeWhatsapp'),
                ),
                const Divider(height: 1, indent: 56, color: kBorder),
                _menuTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Tentang Kios Aisyha',
                  subtitle: 'Versi 1.0.0 • Sembako Murah & Terpercaya',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Tombol Keluar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: _menuTile(
              icon: Icons.logout_rounded,
              iconColor: Colors.red.shade600,
              title: 'Keluar dari Akun',
              subtitle: 'Hapus sesi login di perangkat ini',
              titleColor: Colors.red.shade600,
              onTap: () => auth.logout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: (iconColor ?? kPrimary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? kPrimary, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
          color: titleColor ?? kTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: kTextSecondary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: kTextSecondary, size: 20),
      onTap: onTap,
    );
  }
}

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  List<Json>? list;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.get('/addresses') as List;
      if (mounted) setState(() => list = r.map((e) => Json.from(e as Map)).toList());
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          'Daftar Alamat',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddressFormScreen()),
          );
          if (ok == true) _load();
        },
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(
          'Tambah Alamat',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: list == null
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : list!.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kPrimaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_off_rounded, size: 48, color: kPrimaryDark),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Belum Ada Alamat Tersimpan',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tambahkan alamat agar mempermudah kurir mengantar sembako Anda.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final a = list![i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kPrimaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.home_rounded, color: kPrimaryDark, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      a['label'] as String,
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('• ${a['recipient']}', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: kTextSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  a['full_address'] as String,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: kTextPrimary),
                                ),
                                Text(
                                  a['phone'] as String,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: kTextSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                            onPressed: () async {
                              await Api.delete('/addresses/${a['id']}');
                              _load();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final label = TextEditingController(text: 'Rumah');
  final recipient = TextEditingController();
  final phone = TextEditingController();
  final full = TextEditingController();
  List<Json> zones = [];
  int? zoneId;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    () async {
      try {
        final r = await Api.get('/shipping-zones') as List;
        if (mounted) setState(() => zones = r.map((e) => Json.from(e as Map)).toList());
      } catch (_) {}
    }();
  }

  Future<void> _save() async {
    setState(() => busy = true);
    try {
      await Api.post('/addresses', {
        'label': label.text.trim(),
        'recipient': recipient.text.trim(),
        'phone': phone.text.trim(),
        'full_address': full.text.trim(),
        'shipping_zone_id': zoneId,
        'is_default': true,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Tambah Alamat Baru',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          _fieldLabel('Label Alamat'),
          TextField(controller: label, decoration: const InputDecoration(hintText: 'Contoh: Rumah, Kos, Toko')),
          const SizedBox(height: 14),
          _fieldLabel('Nama Penerima'),
          TextField(controller: recipient, decoration: const InputDecoration(hintText: 'Nama lengkap penerima')),
          const SizedBox(height: 14),
          _fieldLabel('Nomor Telepon'),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'No. HP aktif')),
          const SizedBox(height: 14),
          _fieldLabel('Alamat Lengkap'),
          TextField(controller: full, maxLines: 3, decoration: const InputDecoration(hintText: 'Jalan, nomor rumah, RT/RW, patokan')),
          if (zones.isNotEmpty) ...[
            const SizedBox(height: 14),
            _fieldLabel('Area Pengiriman'),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(hintText: 'Pilih area'),
              items: [
                for (final z in zones)
                  DropdownMenuItem(
                    value: z['id'] as int,
                    child: Text('${z['name']} (${rp(z['fee'])})'),
                  ),
              ],
              onChanged: (v) => zoneId = v,
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: busy ? null : _save,
            child: Text(
              busy ? 'Menyimpan Alamat...' : 'Simpan Alamat',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: kTextPrimary),
      ),
    );
  }
}
