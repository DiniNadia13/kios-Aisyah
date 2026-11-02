import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import 'common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final pass = TextEditingController();
  bool register = false;
  bool busy = false;

  Future<void> _submit() async {
    final auth = context.read<AuthState>();
    setState(() => busy = true);
    try {
      if (register) {
        await auth.register(name.text.trim(), phone.text.trim(), pass.text);
      } else {
        await auth.login(phone.text.trim(), pass.text);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, e.toString());
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          register ? 'Daftar Akun Baru' : 'Masuk ke Akun',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.storefront_rounded, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kios Aisyha',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              register
                  ? 'Daftar untuk menikmati belanja sembako murah & gratis ongkir'
                  : 'Silakan masuk dengan nomor HP Anda',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 32),
            if (register) ...[
              Text(
                'Nama Lengkap',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: kTextPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: name,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Contoh: Siti Aisyah',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: kTextSecondary),
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Nomor WhatsApp / HP',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: kTextPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Contoh: 081234567890',
                prefixIcon: const Icon(Icons.phone_outlined, color: kTextSecondary),
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Password',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: kTextPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: pass,
              obscureText: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Minimal 6 karakter',
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: kTextSecondary),
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: busy ? null : _submit,
              child: Text(
                busy ? 'Memproses...' : (register ? 'Daftar Sekarang' : 'Masuk Sekarang'),
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(
                register ? 'Sudah punya akun? Masuk di sini' : 'Belum punya akun? Daftar gratis di sini',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: kPrimaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
