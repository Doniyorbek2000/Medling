import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

enum UserRole { patient, doctor, admin }

/// Sessiya holati. Token Keychain / Android Keystore'da (shifrlangan) saqlanadi.
///
/// JWT 15 daqiqa amal qiladi, shuning uchun faol sessiyada token har
/// [refreshEvery] da yangilanadi. Foydalanuvchi faol bo'lmasa, IdleGuard
/// sessiyani undan oldin yopadi.
class Session extends ChangeNotifier {
  Session(this.api, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    api.onUnauthorized = logout;
  }

  final ApiClient api;
  final FlutterSecureStorage _storage;
  Timer? _refreshTimer;

  static const _tokenKey = 'medlink.token';
  static const refreshEvery = Duration(minutes: 10);
  static const requiredConsents = {'terms', 'personalData', 'healthData'};

  bool loading = true;
  String? token;
  String? userId;
  UserRole role = UserRole.patient;
  List<String> missingConsents = const [];

  bool get loggedIn => token != null;
  bool get needsConsent => missingConsents.any(requiredConsents.contains);
  bool hasConsent(String scope) => !missingConsents.contains(scope);

  Future<void> restore() async {
    try {
      final saved = await _storage.read(key: _tokenKey);
      if (saved != null) {
        api.token = saved;
        token = saved;
        await refreshToken();
        await reloadMe();
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
    _applyUser(
      user['id'] as String,
      user['role'] as String,
      (res['missingConsents'] as List).cast<String>(),
    );
    await _setToken(res['token'] as String);
    notifyListeners();
  }

  /// Rol (masalan, moderatsiyadan keyin "doctor") va rozilik holatini yangilaydi.
  Future<void> reloadMe() async {
    final me = await api.get('/v1/me');
    _applyUser(
      me['id'] as String,
      me['role'] as String,
      (me['missingConsents'] as List).cast<String>(),
    );
    notifyListeners();
  }

  void _applyUser(String id, String r, List<String> missing) {
    userId = id;
    role = UserRole.values.firstWhere(
      (v) => v.name == r,
      orElse: () => UserRole.patient,
    );
    missingConsents = missing;
  }

  Future<void> refreshToken() async {
    final res = await api.post('/v1/auth/refresh');
    await _setToken(res['token'] as String);
  }

  Future<void> _setToken(String t) async {
    token = t;
    api.token = t;
    await _storage.write(key: _tokenKey, value: t);
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshEvery, (_) {
      refreshToken().catchError((Object _) {});
    });
  }

  void updateMissing(List<String> missing) {
    missingConsents = missing;
    notifyListeners();
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    token = null;
    userId = null;
    api.token = null;
    role = UserRole.patient;
    missingConsents = const [];
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
