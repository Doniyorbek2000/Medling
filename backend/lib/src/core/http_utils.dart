import 'dart:convert';

import 'package:shelf/shelf.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonOk(Object? body, {int status = 200}) =>
    Response(status, body: jsonEncode(body), headers: _jsonHeaders);

Response jsonError(int status, String code, [String? message]) => Response(
  status,
  body: jsonEncode({
    'error': {'code': code, 'message': ?message},
  }),
  headers: _jsonHeaders,
);

Future<Map<String, dynamic>> readJson(Request req) async {
  final raw = await req.readAsString();
  if (raw.isEmpty) return {};
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('JSON obyekt kutilgan');
  }
  return decoded;
}

class ApiException implements Exception {
  ApiException(this.status, this.code, [this.message]);
  final int status;
  final String code;
  final String? message;
}

/// Xatolarni xavfsiz javobga aylantiradi: ichki tafsilotlar (stack trace,
/// shaxsiy ma'lumotlar) hech qachon mijozga qaytarilmaydi.
Middleware errorMiddleware(void Function(Object, StackTrace) log) =>
    (inner) => (req) async {
      try {
        return await inner(req);
      } on HijackException {
        // WebSocket ulanishi — shelf_io o'zi boshqaradi.
        rethrow;
      } on ApiException catch (e) {
        return jsonError(e.status, e.code, e.message);
      } on FormatException {
        return jsonError(400, 'bad_request', 'Noto\'g\'ri so\'rov formati');
      } catch (e, st) {
        log(e, st);
        return jsonError(500, 'internal_error');
      }
    };

/// Xavfsizlik sarlavhalari va keshni taqiqlash (tibbiy ma'lumot proksi/
/// brauzer keshida qolmasligi uchun).
Middleware securityHeaders() =>
    (inner) => (req) async {
      final res = await inner(req);
      return res.change(
        headers: {
          'strict-transport-security': 'max-age=63072000; includeSubDomains',
          'x-content-type-options': 'nosniff',
          'x-frame-options': 'DENY',
          'cache-control': 'no-store',
          'referrer-policy': 'no-referrer',
        },
      );
    };
