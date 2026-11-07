import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiError implements Exception {
  ApiError(this.status, this.code, [this.message]);
  final int status;
  final String code;
  final String? message;

  bool get consentRequired => status == 451;

  /// Foydalanuvchiga ko'rsatiladigan xabar.
  String get userMessage => switch (code) {
    'otp_invalid' => 'Kod noto\'g\'ri',
    'otp_expired' => 'Kod muddati o\'tgan. Qayta so\'rang',
    'otp_attempts_exceeded' => 'Urinishlar soni tugadi. Qayta so\'rang',
    'rate_limited' => 'Juda ko\'p so\'rov. Birozdan so\'ng urinib ko\'ring',
    'consent_required' => 'Buning uchun rozilik kerak',
    'slot_unavailable' => 'Bu vaqt band. Boshqa vaqtni tanlang',
    'already_applied' => 'Siz allaqachon ariza topshirgansiz',
    'network' => 'Internet aloqasi yo\'q',
    _ => message ?? 'Xatolik yuz berdi ($code)',
  };

  @override
  String toString() => 'ApiError($status, $code)';
}

/// HTTP mijozi. Token faqat xotirada va flutter_secure_storage'da saqlanadi.
/// Tibbiy javoblar diskka keshlanmaydi.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _http = client ?? http.Client(),
      _base = Uri.parse(baseUrl ?? AppConfig.apiBase) {
    final local =
        _base.host == '10.0.2.2' ||
        _base.host == 'localhost' ||
        _base.host == '127.0.0.1';
    if (_base.scheme != 'https' && !local) {
      throw StateError('MedLink API faqat HTTPS orqali ishlaydi');
    }
  }

  final http.Client _http;
  final Uri _base;
  String? token;
  void Function()? onUnauthorized;

  Future<Map<String, dynamic>> get(String path, [Map<String, String>? query]) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = _base.replace(path: path, queryParameters: query);
    final req = http.Request(method, uri)
      ..headers.addAll({
        'accept': 'application/json',
        if (body != null) 'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      });
    if (body != null) req.body = jsonEncode(body);

    http.Response res;
    try {
      res = await http.Response.fromStream(
        await _http.send(req).timeout(const Duration(seconds: 60)),
      );
    } catch (_) {
      throw ApiError(0, 'network');
    }
    final decoded = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    if (res.statusCode == 401 && token != null) onUnauthorized?.call();
    final err = decoded['error'] as Map<String, dynamic>?;
    throw ApiError(
      res.statusCode,
      err?['code'] as String? ?? 'http_${res.statusCode}',
      err?['message'] as String?,
    );
  }
}
