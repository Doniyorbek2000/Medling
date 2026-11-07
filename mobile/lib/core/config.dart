/// API manzili build vaqtida beriladi:
///   flutter run --dart-define=MEDLINK_API=https://api.medlink.uz
/// Faqat HTTPS qabul qilinadi (lokal emulyator bundan mustasno).
class AppConfig {
  static const apiBase = String.fromEnvironment(
    'MEDLINK_API',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const emergencyPhone = '103';

  /// Foydalanuvchi faol bo'lmasa sessiya yopiladi.
  static const idleTimeout = Duration(minutes: 10);
}
