import 'dart:convert';
import 'dart:io';

/// Barcha maxfiy kalitlar FAQAT muhit o'zgaruvchilaridan (yoki Secret Manager'dan)
/// o'qiladi. Ular hech qachon mobil ilovaga yoki repozitoriyga tushmasligi kerak.
class AppConfig {
  AppConfig({
    required this.port,
    required this.jwtSecret,
    required this.dataKeys,
    required this.activeKeyId,
    required this.gcpProject,
    required this.gcpLocation,
    required this.medModel,
    required this.clickServiceId,
    required this.clickMerchantId,
    required this.clickSecretKey,
    required this.paymeMerchantId,
    required this.paymeKey,
    required this.paymeTestMode,
    required this.stripeSecretKey,
    required this.publicBaseUrl,
  });

  final int port;
  final String jwtSecret;

  /// keyId -> 32 baytli AES-256 kalit. Kalit rotatsiyasi uchun bir nechta kalit
  /// saqlanadi; yangi yozuvlar [activeKeyId] bilan shifrlanadi.
  final Map<String, List<int>> dataKeys;
  final String activeKeyId;

  final String gcpProject;
  final String gcpLocation;
  final String medModel;

  final String clickServiceId;
  final String clickMerchantId;
  final String clickSecretKey;

  final String paymeMerchantId;
  final String paymeKey;
  final bool paymeTestMode;

  final String stripeSecretKey;
  final String publicBaseUrl;

  static AppConfig fromEnvironment([Map<String, String>? env]) {
    final e = env ?? Platform.environment;
    String req(String k) {
      final v = e[k];
      if (v == null || v.isEmpty) {
        throw StateError('Muhit o\'zgaruvchisi yo\'q: $k');
      }
      return v;
    }

    // MEDLINK_DATA_KEYS format: "k1:<base64>,k2:<base64>"
    final keys = <String, List<int>>{};
    for (final part in req('MEDLINK_DATA_KEYS').split(',')) {
      final idx = part.indexOf(':');
      final id = part.substring(0, idx).trim();
      final bytes = base64.decode(part.substring(idx + 1).trim());
      if (bytes.length != 32) {
        throw StateError('$id kaliti 32 bayt (AES-256) bo\'lishi kerak');
      }
      keys[id] = bytes;
    }
    final active = req('MEDLINK_ACTIVE_KEY_ID');
    if (!keys.containsKey(active)) {
      throw StateError('Faol kalit topilmadi: $active');
    }
    final jwt = req('MEDLINK_JWT_SECRET');
    if (jwt.length < 32) {
      throw StateError('MEDLINK_JWT_SECRET kamida 32 belgi bo\'lishi kerak');
    }

    return AppConfig(
      port: int.parse(e['PORT'] ?? '8080'),
      jwtSecret: jwt,
      dataKeys: keys,
      activeKeyId: active,
      gcpProject: e['GCP_PROJECT'] ?? '',
      gcpLocation: e['GCP_LOCATION'] ?? 'us-central1',
      medModel: e['MEDLINK_MED_MODEL'] ?? 'medlm-large',
      clickServiceId: e['CLICK_SERVICE_ID'] ?? '',
      clickMerchantId: e['CLICK_MERCHANT_ID'] ?? '',
      clickSecretKey: e['CLICK_SECRET_KEY'] ?? '',
      paymeMerchantId: e['PAYME_MERCHANT_ID'] ?? '',
      paymeKey: e['PAYME_KEY'] ?? '',
      paymeTestMode: (e['PAYME_TEST_MODE'] ?? 'true') == 'true',
      stripeSecretKey: e['STRIPE_SECRET_KEY'] ?? '',
      publicBaseUrl: e['MEDLINK_PUBLIC_BASE_URL'] ?? 'https://api.medlink.uz',
    );
  }
}
