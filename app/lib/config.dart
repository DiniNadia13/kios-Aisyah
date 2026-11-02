import 'package:flutter/foundation.dart';

/// Alamat server API Laravel.
///
/// - Web (Chrome)     : http://127.0.0.1:8000/api
/// - Emulator Android : http://10.0.2.2:8000/api
/// - HP asli          : http://IP-KOMPUTER:8000/api  (satu WiFi)
/// - Produksi         : https://domain-anda.com/api
const String apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api',
);

/// Nomor WhatsApp toko (format internasional tanpa +).
const String storeWhatsapp = '6282154306904';
