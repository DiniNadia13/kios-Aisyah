import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  static String? token;

  static Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic _handle(http.Response r) {
    dynamic body;
    try {
      body = jsonDecode(r.body);
    } catch (_) {}
    if (r.statusCode >= 200 && r.statusCode < 300) return body;

    var msg = 'Terjadi kesalahan (${r.statusCode})';
    if (body is Map) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        msg = (first is List && first.isNotEmpty ? first.first : first).toString();
      } else if (body['message'] != null) {
        msg = body['message'].toString();
      }
    }
    throw ApiException(msg);
  }

  static Future<dynamic> _send(Future<http.Response> Function() call) async {
    try {
      final r = await call().timeout(const Duration(seconds: 20));
      return _handle(r);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server. Periksa internet Anda.');
    } on http.ClientException {
      throw ApiException('Tidak dapat terhubung ke server. Periksa internet Anda.');
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Koneksi bermasalah, coba lagi.');
    }
  }

  static Future<dynamic> get(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$apiBase$path').replace(queryParameters: query);
    return _send(() => http.get(uri, headers: _headers));
  }

  static Future<dynamic> post(String path, [Object? data]) {
    return _send(() => http.post(Uri.parse('$apiBase$path'),
        headers: _headers, body: jsonEncode(data ?? {})));
  }

  static Future<dynamic> delete(String path) {
    return _send(() => http.delete(Uri.parse('$apiBase$path'), headers: _headers));
  }

  static Future<dynamic> uploadMultipart(
    String path, {
    required Map<String, String> fields,
    String? fileField,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final uri = Uri.parse('$apiBase$path');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Accept'] = 'application/json';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';

    req.fields.addAll(fields);

    if (fileField != null) {
      if (fileBytes != null && fileName != null) {
        req.files.add(http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName,
        ));
      } else if (filePath != null) {
        req.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      }
    }

    try {
      final streamed = await req.send().timeout(const Duration(seconds: 40));
      final resp = await http.Response.fromStream(streamed);
      return _handle(resp);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server. Periksa internet Anda.');
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengunggah foto produk.');
    }
  }
}

