import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth.dart';

/// Eskiz.uz SMS shlyuzi orqali OTP yuborish.
///
/// Eskiz kabinetida SMS shabloni oldindan tasdiqlangan bo'lishi shart
/// (masalan: "MedLink: tasdiqlash kodi {code}. Kodni hech kimga bermang.").
/// Hujjat: https://documenter.getpostman.com/view/663428/RzfmES4z
class EskizOtpSender implements OtpSender {
  EskizOtpSender({
    required this.client,
    required this.email,
    required this.password,
    this.from = '4546',
    this.template =
        'MedLink: tasdiqlash kodi {code}. Kodni hech kimga bermang.',
    this.baseUrl = 'https://notify.eskiz.uz/api',
  });

  final http.Client client;
  final String email;
  final String password;
  final String from;
  final String template;
  final String baseUrl;

  String? _token;

  Future<String> _login() async {
    final res = await client.post(
      Uri.parse('$baseUrl/auth/login'),
      body: {'email': email, 'password': password},
    );
    if (res.statusCode != 200) {
      throw StateError('Eskiz login xatosi: ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return _token = (j['data'] as Map<String, dynamic>)['token'] as String;
  }

  Future<http.Response> _send(String token, String phone, String code) =>
      client.post(
        Uri.parse('$baseUrl/message/sms/send'),
        headers: {'authorization': 'Bearer $token'},
        body: {
          // Eskiz "+" belgisisiz format kutadi: 998901234567.
          'mobile_phone': phone.replaceAll('+', ''),
          'message': template.replaceAll('{code}', code),
          'from': from,
        },
      );

  @override
  Future<void> send(String phone, String code) async {
    var res = await _send(_token ?? await _login(), phone, code);
    if (res.statusCode == 401) {
      // Token muddati tugagan — qayta kirib, bir marta takrorlaymiz.
      res = await _send(await _login(), phone, code);
    }
    if (res.statusCode != 200) {
      throw StateError('Eskiz SMS xatosi: ${res.statusCode}');
    }
  }
}
