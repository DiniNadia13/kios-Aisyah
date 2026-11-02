import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'common.dart';

class ReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic>? paymentInfo;

  const ReceiptScreen({
    super.key,
    required this.order,
    this.paymentInfo,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool printing = false;

  Map<String, dynamic> get o => widget.order;
  Map<String, dynamic>? get p => widget.paymentInfo;

  String get storeName => p?['store_name'] ?? 'KIOS AISYHA';
  String get storeAddress => p?['store_address'] ?? 'Pusat Sembako Segar & Terlengkap';
  String get storePhone => p?['store_phone'] ?? '0821-5430-6904';

  Future<Uint8List> _generatePdf() async {
    final doc = pw.Document();
    final items = (o['items'] as List?) ?? [];

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        margin: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Center(
                child: pw.Text(
                  storeName.toUpperCase(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  storeAddress,
                  style: const pw.TextStyle(fontSize: 6.5),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Center(
                child: pw.Text('WA: $storePhone', style: const pw.TextStyle(fontSize: 6.5)),
              ),
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.8),
              pw.Text('No. Nota : ${o['code']}', style: const pw.TextStyle(fontSize: 7)),
              pw.Text(
                'Waktu    : ${o['created_at'] != null ? o['created_at'].toString().substring(0, 16) : '-'}',
                style: const pw.TextStyle(fontSize: 6.5),
              ),
              pw.Text(
                'Pemesan  : ${o['recipient'] ?? '-'} (${o['phone'] ?? '-'})',
                style: const pw.TextStyle(fontSize: 6.5),
              ),
              pw.Text(
                'Metode   : ${o['delivery_method'] == 'pickup' ? 'Ambil di Toko' : 'Diantar'}',
                style: const pw.TextStyle(fontSize: 6.5),
              ),
              if (o['address'] != null)
                pw.Text('Alamat   : ${o['address']}', style: const pw.TextStyle(fontSize: 6.5)),
              pw.Divider(thickness: 0.5),
              ...items.map((it) {
                final name = it['name'] ?? 'Item';
                final qty = it['quantity'] ?? 1;
                final sub = it['subtotal'] ?? 0;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text('$name (x$qty)', style: const pw.TextStyle(fontSize: 7)),
                      ),
                      pw.Text(rp(sub), style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                );
              }),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 6.5)),
                  pw.Text(rp(o['subtotal'] ?? 0), style: const pw.TextStyle(fontSize: 6.5)),
                ],
              ),
              if ((o['discount'] ?? 0) > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Diskon', style: const pw.TextStyle(fontSize: 6.5)),
                    pw.Text('-${rp(o['discount'])}', style: const pw.TextStyle(fontSize: 6.5)),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Ongkir', style: const pw.TextStyle(fontSize: 6.5)),
                  pw.Text(
                    o['shipping_fee'] == 0 ? 'GRATIS' : rp(o['shipping_fee']),
                    style: const pw.TextStyle(fontSize: 6.5),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text(rp(o['total'] ?? 0), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Bayar: ${o['payment_method']?.toString().toUpperCase()} [${o['payment_status'] == 'paid' ? 'LUNAS' : 'BELUM LUNAS'}]',
                style: const pw.TextStyle(fontSize: 6.5),
              ),
              pw.Divider(thickness: 0.8),
              pw.Center(
                child: pw.Text(
                  '*** TERIMA KASIH ***',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Belanja Sembako Hemat & Berkah',
                  style: const pw.TextStyle(fontSize: 6),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Kios Aisyha siap melayani kebutuhan dapur Anda',
                  style: const pw.TextStyle(fontSize: 5.5),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  String _generatePlainText() {
    final items = (o['items'] as List?) ?? [];
    final sb = StringBuffer()
      ..writeln('================================')
      ..writeln('         $storeName')
      ..writeln('  $storeAddress')
      ..writeln('     WA: $storePhone')
      ..writeln('================================')
      ..writeln('No. Nota : ${o['code']}');
    if (o['created_at'] != null) {
      sb.writeln('Tanggal  : ${o['created_at'].toString().substring(0, 16)}');
    }
    sb.writeln('Pemesan  : ${o['recipient'] ?? '-'} (${o['phone'] ?? '-'})');
    sb.writeln('Metode   : ${o['delivery_method'] == 'pickup' ? 'Ambil di Toko' : 'Diantar ke Rumah'}');
    if (o['address'] != null) {
      sb.writeln('Alamat   : ${o['address']}');
    }
    sb.writeln('--------------------------------');
    for (final it in items) {
      final name = it['name'] ?? 'Item';
      final qty = it['quantity'] ?? 1;
      final sub = it['subtotal'] ?? 0;
      sb.writeln('$name');
      sb.writeln('  ${qty}x = ${rp(sub)}');
    }
    sb.writeln('--------------------------------');
    sb.writeln('Subtotal : ${rp(o['subtotal'] ?? 0)}');
    if ((o['discount'] ?? 0) > 0) {
      sb.writeln('Diskon   : -${rp(o['discount'])}');
    }
    sb.writeln('Ongkir   : ${o['shipping_fee'] == 0 ? "GRATIS" : rp(o['shipping_fee'])}');
    sb.writeln('--------------------------------');
    sb.writeln('TOTAL    : ${rp(o['total'] ?? 0)}');
    sb.writeln('Bayar    : ${o['payment_method']?.toString().toUpperCase()} [${o['payment_status'] == 'paid' ? 'LUNAS' : 'BELUM LUNAS'}]');
    if (o['note'] != null && o['note'].toString().isNotEmpty) {
      sb.writeln('Catatan  : ${o['note']}');
    }
    sb.writeln('================================');
    sb.writeln('     *** TERIMA KASIH ***');
    sb.writeln('  Belanja Sembako Hemat & Berkah');
    sb.writeln('================================');
    return sb.toString();
  }

  Future<void> _printReceipt() async {
    setState(() => printing = true);
    try {
      final pdfBytes = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Struk_${o['code']}',
      );
    } catch (e) {
      if (mounted) snack(context, 'Gagal mencetak: $e');
    } finally {
      if (mounted) setState(() => printing = false);
    }
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _generatePlainText()));
    snack(context, 'Teks struk berhasil disalin ke clipboard!', isSuccess: true);
  }

  void _shareToWhatsapp() {
    final text = _generatePlainText();
    final customerPhone = o['phone']?.toString() ?? storePhone;
    openWhatsapp(message: text, phone: customerPhone, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final items = (o['items'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Text(
          'Struk Kasir Kios Aisyha',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Salin Teks Nota',
            onPressed: _copyText,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Bagikan ke WhatsApp',
            onPressed: _shareToWhatsapp,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Kertas Struk Thermal Kasir
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 18, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo/Ikon Kios
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, color: kPrimaryDark, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    storeName.toUpperCase(),
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    storeAddress,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(fontSize: 11, color: kTextSecondary),
                  ),
                  Text(
                    'WA: $storePhone',
                    style: GoogleFonts.spaceMono(fontSize: 11, color: kTextSecondary),
                  ),
                  const SizedBox(height: 14),
                  _dashDivider(),
                  const SizedBox(height: 12),

                  // Data Nota
                  _kvRow('No. Nota', o['code'] ?? '-'),
                  if (o['created_at'] != null)
                    _kvRow('Tanggal', o['created_at'].toString().substring(0, 16)),
                  _kvRow('Pelanggan', '${o['recipient'] ?? '-'} (${o['phone'] ?? '-'})'),
                  _kvRow('Metode', o['delivery_method'] == 'pickup' ? 'Ambil di Toko' : 'Diantar Kurir 🛵'),
                  if (o['address'] != null)
                    _kvRow('Alamat', o['address']),
                  const SizedBox(height: 12),
                  _dashDivider(),
                  const SizedBox(height: 12),

                  // Item Belanja
                  for (final it in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  it['name'] ?? 'Item',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: kTextPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                rp(it['subtotal'] ?? 0),
                                style: GoogleFonts.spaceMono(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '  ${it['quantity']}x @ ${rp(it['price'] ?? 0)}',
                            style: GoogleFonts.spaceMono(fontSize: 11, color: kTextSecondary),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                  _dashDivider(),
                  const SizedBox(height: 12),

                  // Kalkulasi Total
                  _kvRow('Subtotal', rp(o['subtotal'] ?? 0)),
                  if ((o['discount'] ?? 0) > 0)
                    _kvRow('Diskon Voucher', '-${rp(o['discount'])}', isGreen: true),
                  _kvRow(
                    'Ongkos Kirim',
                    o['shipping_fee'] == 0 ? 'GRATIS' : rp(o['shipping_fee']),
                    isGreen: o['shipping_fee'] == 0,
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1.5, color: Color(0xFF0F172A)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: GoogleFonts.spaceMono(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        rp(o['total'] ?? 0),
                        style: GoogleFonts.spaceMono(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _kvRow(
                    'Metode Bayar',
                    '${o['payment_method']?.toString().toUpperCase()} [${o['payment_status'] == 'paid' ? 'LUNAS' : 'BELUM LUNAS'}]',
                  ),
                  if (o['note'] != null && o['note'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _kvRow('Catatan', o['note']),
                    ),

                  const SizedBox(height: 20),
                  _dashDivider(),
                  const SizedBox(height: 14),

                  // Footer Struk
                  Text(
                    '*** TERIMA KASIH ***',
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Belanja Sembako Hemat & Berkah\nBarang yang dibeli dapat ditukar jika rusak saat diterima.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(fontSize: 10, color: kTextSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  // Barcode dekoratif
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Text(
                      '||| | ||||| || |||| ||| ||||||| |||',
                      style: GoogleFonts.spaceMono(
                        fontSize: 18,
                        letterSpacing: 4,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Cetak & Aksi
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: printing ? null : _printReceipt,
                    icon: printing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.print_rounded, size: 20),
                    label: Text(
                      printing ? 'Menghubungkan...' : 'Cetak Thermal (PDF / Printer)',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _shareToWhatsapp,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: Text(
                      'Kirim Struk ke WhatsApp',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.all(13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.content_copy_rounded, size: 20, color: kTextPrimary),
                  tooltip: 'Salin Teks Nota',
                  onPressed: _copyText,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _dashDivider() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? const Color(0xFF94A3B8) : Colors.transparent,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _kvRow(String k, String v, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: GoogleFonts.spaceMono(fontSize: 11.5, color: kTextSecondary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceMono(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isGreen ? const Color(0xFF059669) : kTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
