/// Aniq (explicit), alohida (granular), versiyalangan va qaytarib olinadigan
/// rozilik. O'zbekiston "Shaxsga doir ma'lumotlar to'g'risida"gi Qonuni
/// (O'RQ-547) va HIPAA (§164.508 avtorizatsiya) talablariga mos ravishda
/// har bir maqsad uchun alohida rozilik olinadi.
enum ConsentScope {
  /// Foydalanish shartlari.
  terms(required: true),

  /// Shaxsga doir ma'lumotlarni qayta ishlash (O'RQ-547).
  personalData(required: true),

  /// Sog'liq haqidagi ma'lumotlarni (maxsus toifa) qayta ishlash.
  healthData(required: true),

  /// Alomatlarni sun'iy intellekt orqali tahlil qilish.
  aiProcessing(required: false),

  /// Ma'lumotni O'zbekistondan tashqaridagi serverga (Google Cloud) uzatish.
  crossBorderTransfer(required: false),

  /// Reklama/xabarnomalar.
  marketing(required: false);

  const ConsentScope({required this.required});
  final bool required;

  static ConsentScope parse(String s) => ConsentScope.values.firstWhere(
    (v) => v.name == s,
    orElse: () => throw FormatException('Noma\'lum rozilik: $s'),
  );
}

/// Rozilik matnlarining joriy versiyasi. Matn o'zgarsa versiya oshiriladi va
/// foydalanuvchidan rozilik qayta so'raladi.
const currentConsentVersions = <ConsentScope, String>{
  ConsentScope.terms: '2026-11-01',
  ConsentScope.personalData: '2026-11-01',
  ConsentScope.healthData: '2026-11-01',
  ConsentScope.aiProcessing: '2026-11-01',
  ConsentScope.crossBorderTransfer: '2026-11-01',
  ConsentScope.marketing: '2026-11-01',
};

class ConsentRecord {
  ConsentRecord({
    required this.userId,
    required this.scope,
    required this.version,
    required this.granted,
    required this.at,
    this.ip,
    this.userAgent,
  });

  final String userId;
  final ConsentScope scope;
  final String version;
  final bool granted;
  final DateTime at;
  final String? ip;
  final String? userAgent;

  Map<String, dynamic> toJson() => {
    'scope': scope.name,
    'version': version,
    'granted': granted,
    'at': at.toIso8601String(),
  };
}

/// Rozilik tarixi o'chirilmaydi — har bir berish/qaytarib olish yangi yozuv.
/// Joriy holat = har bir scope bo'yicha eng oxirgi yozuv.
class ConsentService {
  final List<ConsentRecord> _history = [];

  Future<void> record(ConsentRecord r) async {
    final expected = currentConsentVersions[r.scope];
    if (r.granted && r.version != expected) {
      throw StateError('Eskirgan rozilik versiyasi: ${r.scope.name}');
    }
    _history.add(r);
  }

  Future<Map<ConsentScope, ConsentRecord>> current(String userId) async {
    final out = <ConsentScope, ConsentRecord>{};
    for (final r in _history.where((r) => r.userId == userId)) {
      out[r.scope] = r;
    }
    return out;
  }

  /// Rozilik amalda bo'lishi uchun: oxirgi yozuv `granted` va versiya joriy.
  Future<bool> has(String userId, ConsentScope scope) async {
    final r = (await current(userId))[scope];
    return r != null && r.granted && r.version == currentConsentVersions[scope];
  }

  Future<bool> hasAllRequired(String userId) async {
    for (final s in ConsentScope.values.where((s) => s.required)) {
      if (!await has(userId, s)) return false;
    }
    return true;
  }

  Future<List<ConsentScope>> missing(String userId) async => [
    for (final s in ConsentScope.values)
      if (!await has(userId, s)) s,
  ];

  Future<List<ConsentRecord>> history(String userId) async =>
      _history.where((r) => r.userId == userId).toList();
}
