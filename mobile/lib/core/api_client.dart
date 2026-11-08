import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:web_socket_channel/web_socket_channel.dart';

import 'config.dart';
import 'live_socket.dart';

class ApiError implements Exception {
  ApiError(this.status, this.code, [this.message]);
  final int status;
  final String code;
  final String? message;

  bool get consentRequired => status == 451;

  bool get isNetwork => code == 'network';

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

  /// WebSocket ochuvchi (testlarda almashtiriladi; null — real vaqt o'chiq).
  WebSocketChannel? Function(Uri uri, String token)? socketFactory =
      openLiveSocket;

  /// Real vaqt ulanishi. Mavjud bo'lmasa null (chaqiruvchi so'rovlarga
  /// o'tadi).
  WebSocketChannel? openSocket(String path) {
    final t = token;
    final f = socketFactory;
    if (t == null || f == null) return null;
    final uri = _base.replace(
      scheme: _base.scheme == 'https' ? 'wss' : 'ws',
      path: path,
    );
    try {
      return f(uri, t);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> get(String path, [Map<String, String>? query]) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  /// Fayl yuklash (xom baytlar).
  Future<Map<String, dynamic>> postBytes(
    String path,
    List<int> bytes, {
    Map<String, String> headers = const {},
  }) async {
    final req = http.Request('POST', _base.replace(path: path))
      ..headers.addAll({
        'accept': 'application/json',
        'content-type': 'application/octet-stream',
        if (token != null) 'authorization': 'Bearer $token',
        ...headers,
      })
      ..bodyBytes = bytes;
    return _decode(await _execute(req));
  }

  /// Fayl yuklab olish (xom baytlar).
  Future<Uint8List> getBytes(String path) async {
    final req = http.Request('GET', _base.replace(path: path))
      ..headers.addAll({if (token != null) 'authorization': 'Bearer $token'});
    final res = await _execute(req);
    if (res.statusCode == 200) return res.bodyBytes;
    _decode(res); // xatoni ApiError sifatida otadi
    throw ApiError(res.statusCode, 'http_${res.statusCode}');
  }

  Future<http.Response> _execute(http.Request req) async {
    try {
      return await http.Response.fromStream(
        await _http.send(req).timeout(const Duration(seconds: 60)),
      );
    } catch (_) {
      throw ApiError(0, 'network');
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
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
