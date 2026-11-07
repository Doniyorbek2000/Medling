import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

enum UserRole { patient, doctor, admin }

/// Sessiya holati. Token Keychain / Android Keystore'da (shifrlangan) saqlanadi.
class Session extends ChangeNotifier {
  Session(this.api, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    api.onUnauthorized = logout;
  }

  final ApiClient api;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'medlink.token';
  static const _roleKey = 'medlink.role';

  bool loading = true;
  String? token;
  UserRole role = UserRole.patient;
  List<String> missingConsents = const [];

  bool get loggedIn => token != null;
  bool get needsConsent => missingConsents.any(
    const {'terms', 'personalData', 'healthData'}.contains,
  );

  Future<void> restore() async {
    try {
      token = await _storage.read(key: _tokenKey);
      final r = await _storage.read(key: _roleKey);
      role = UserRole.values.firstWhere(
        (v) => v.name == r,
        orElse: () => UserRole.patient,
      );
      if (token != null) {
        api.token = token;
        // Token muddati o'tgan bo'lsa — 401 orqali logout chaqiriladi.
        final res = await api.post('/v1/auth/refresh');
        await _setToken(res['token'] as String);
        await refreshConsents();
      }
    } catch (_) {
      await logout();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> requestOtp(String phone) =>
      api.post('/v1/auth/otp/request', {'phone': phone});

  Future<void> verifyOtp(String phone, String code) async {
    final res = await api.post('/v1/auth/otp/verify', {
      'phone': phone,
      'code': code,
    });
    final user = res['user'] as Map<String, dynamic>;
    role = UserRole.values.firstWhere((v) => v.name == user['role']);
    missingConsents = (res['missingConsents'] as List).cast<String>();
    await _setToken(res['token'] as String);
    await _storage.write(key: _roleKey, value: role.name);
    notifyListeners();
  }

  Future<void> _setToken(String t) async {
    token = t;
    api.token = t;
    await _storage.write(key: _tokenKey, value: t);
  }

  Future<void> refreshConsents() async {
    final res = await api.get('/v1/consents');
    missingConsents = [
      for (final d in (res['documents'] as List))
        if (d['granted'] != true) d['scope'] as String,
    ];
    notifyListeners();
  }

  void updateMissing(List<String> missing) {
    missingConsents = missing;
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    api.token = null;
    missingConsents = const [];
    await _storage.deleteAll();
    notifyListeners();
  }
}
