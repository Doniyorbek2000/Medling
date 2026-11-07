import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Foydalanuvchi sozlamalari: til, mavzu, biometrik qulf, onboarding.
class AppSettings extends ChangeNotifier {
  AppSettings({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const supportedLocales = [Locale('uz'), Locale('ru'), Locale('en')];

  Locale? locale; // null — tizim tili
  ThemeMode themeMode = ThemeMode.system;
  bool biometricLock = false;
  bool onboardingDone = false;

  Future<void> load() async {
    try {
      final all = await _storage.readAll();
      final code = all['settings.locale'];
      locale = code == null ? null : Locale(code);
      themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == all['settings.theme'],
        orElse: () => ThemeMode.system,
      );
      biometricLock = all['settings.biometric'] == 'true';
      onboardingDone = all['settings.onboarding'] == 'true';
    } catch (_) {
      // Saqlash joyi buzilgan bo'lsa — standart sozlamalar.
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale? l) async {
    locale = l;
    notifyListeners();
    if (l == null) {
      await _storage.delete(key: 'settings.locale');
    } else {
      await _storage.write(key: 'settings.locale', value: l.languageCode);
    }
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    await _storage.write(key: 'settings.theme', value: m.name);
  }

  Future<void> setBiometricLock(bool v) async {
    biometricLock = v;
    notifyListeners();
    await _storage.write(key: 'settings.biometric', value: '$v');
  }

  Future<void> completeOnboarding() async {
    onboardingDone = true;
    notifyListeners();
    await _storage.write(key: 'settings.onboarding', value: 'true');
  }
}
