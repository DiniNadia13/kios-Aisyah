import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'common.dart';

class PaymentInfoCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic>? paymentInfo;

  const PaymentInfoCard({
    super.key,
    required this.order,
    this.paymentInfo,
  });

  Map<String, dynamic>? get p => paymentInfo;

  String get bankName => p?['bank_name'] ?? 'BCA';
  String get bankAccount => p?['bank_account'] ?? '82154306904';
  String get bankHolder => p?['bank_holder'] ?? 'Kios Aisyha';
  String? get qrisImage => p?['qris_image'];
  String get storePhone => p?['store_phone'] ?? '0821-5430-6904';

  void _copyAccount(BuildContext context) {
    Clipboard.setData(ClipboardData(text: bankAccount));
    snack(context, 'Nomor rekening $bankAccount disalin!', isSuccess: true);
  }

  void _sendProofViaWhatsapp(BuildContext context) {
    final code = order['code'] ?? '';
    final total = rp(order['total'] ?? 0);
    final method = order['payment_method']?.toString().toUpperCase() ?? 'TRANSFER';

    final msg = StringBuffer()
      ..writeln('Halo Kios Aisyha, saya ingin konfirmasi pembayaran:')
      ..writeln('📦 *No. Pesanan:* $code')
      ..writeln('👤 *Pemesan:* ${order['recipient'] ?? 'Pelanggan'}')
      ..writeln('💰 *Total Tagihan:* $total')
      ..writeln('💳 *Metode:* $method')
      ..writeln('\nSaya melampirkan foto bukti pembayaran/transfer. Mohon segera dicek dan dikirim ya!');

    openWhatsapp(
      message: msg.toString(),
      phone: storePhone,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final method = order['payment_method']?.toString() ?? 'cod';
    final isTransfer = method == 'transfer';
    final isQris = method == 'qris';
    final isUnpaid = order['payment_status'] != 'paid';

    if (!isTransfer && !isQris) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isTransfer ? Icons.account_balance_rounded : Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTransfer ? 'Instruksi Transfer Bank' : 'Instruksi Pembayaran QRIS',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: kTextPrimary,
                      ),
                    ),
                    Text(
                      isUnpaid ? 'Menunggu Pembayaran' : 'Pembayaran Sudah Diterima ✓',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isUnpaid ? const Color(0xFFD97706) : kPrimaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (isTransfer) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bank Tujuan:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextSecondary),
                      ),
                      Text(
                        bankName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nomor Rekening:',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary),
                          ),
                          SelectableText(
                            bankAccount,
                            style: GoogleFonts.spaceMono(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryDark,
                            ),
                          ),
                          Text(
                            'a.n $bankHolder',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: kTextSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _copyAccount(context),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Salin'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (isQris) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    if (qrisImage != null && qrisImage!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          qrisImage!,
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _qrisPlaceholder(),
                        ),
                      )
                    else
                      _qrisPlaceholder(),
                    const SizedBox(height: 8),
                    Text(
                      'Pindai QRIS ini dari GoPay, OVO, Dana, BCA, dll.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Text(
            'Langkah Verifikasi:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1. Transfer tepat sesuai total: ${rp(order['total'] ?? 0)}\n'
            '2. Simpan atau screenshot bukti pembayaran Anda\n'
            '3. Klik tombol hijau di bawah untuk mengirim bukti ke WhatsApp Kios Aisyha.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: kTextSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _sendProofViaWhatsapp(context),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(
                'Kirim Bukti Bayar ke WhatsApp Toko',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrisPlaceholder() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2_rounded, size: 64, color: Color(0xFF64748B)),
          const SizedBox(height: 6),
          Text(
            'QRIS Kios Aisyha',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
