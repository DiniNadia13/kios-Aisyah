import 'package:flutter/foundation.dart';

/// Alamat server API Laravel.
/// Otomatis mendeteksi environment:
/// - Chrome di Android Studio (localhost) -> http://127.0.0.1:8000/api
/// - Emulator Android -> http://10.0.2.2:8000/api
/// - Web GitHub Pages / HP Asli Publik -> https://locale-architecture-addressed-looksmart.trycloudflare.com/api
String get apiBase {
  const env = String.fromEnvironment('API_BASE');
  if (env.isNotEmpty) return env;

  if (kIsWeb) {
    final host = Uri.base.host;
    if (host == 'localhost' || host == '127.0.0.1' || host.isEmpty) {
      return 'http://127.0.0.1:8000/api';
    }
    // Jika di domain publik / hosting
    return 'https://kiosaisyha.my.id/api';
  }

  // HP Asli / Emulator Android mengarah langsung ke domain resmi 24 jam
  return 'https://kiosaisyha.my.id/api';
}

/// Nomor WhatsApp toko (format internasional tanpa +).
const String storeWhatsapp = '6282154306904';
