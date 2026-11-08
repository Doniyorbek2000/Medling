// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../core/http_utils.dart';
import '../persistence/changes.dart';
import '../security/field_encryption.dart';

enum Role { patient, doctor, admin }

class User {
  User({
    required this.id,
    required this.phoneHash,
    required this.phoneEnc,
    required this.role,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();
  final String id;
  final DateTime createdAt;

  /// Admin tomonidan bloklangan (kira olmaydi, tokenlari ishlamaydi).
  bool blocked = false;
  String? blockReason;

  /// Qidiruv uchun HMAC-SHA256 (telefon raqami ochiq saqlanmaydi).
  final String phoneHash;

  /// Aloqa uchun shifrlangan raqam.
  final String phoneEnc;
  Role role;
}

/// SMS provayder (masalan Eskiz.uz yoki Play Mobile) uchun interfeys.
abstract class OtpSender {
  Future<void> send(String phone, String code);
}

class _OtpEntry {
  _OtpEntry(this.codeHash, this.expires);
  final String codeHash;
  final DateTime expires;
  int attempts = 0;
}

class AuthService {
  AuthService({
    required String jwtSecret,
    required this.encryption,
    required this.otpSender,
    Set<String> adminPhones = const <String>{},
    Random? random,
  }) : _jwtKey = SecretKey(jwtSecret),
       _hmacKey = utf8.encode('otp-hmac:$jwtSecret'),
       _adminPhones = adminPhones,
       _random = random ?? Random.secure();

  final SecretKey _jwtKey;
  final List<int> _hmacKey;
  final Set<String> _adminPhones;
  final Random _random;
  final FieldEncryption encryption;
  final OtpSender otpSender;

  final _users = <String, User>{};
  final _otps = <String, _OtpEntry>{};

  static const otpTtl = Duration(minutes: 5);
  static const maxOtpAttempts = 5;
  static const accessTtl = Duration(minutes: 15);

  static final _phoneRe = RegExp(r'^\+998\d{9}$');

  String _hash(String v) =>
      Hmac(sha256, _hmacKey).convert(utf8.encode(v)).toString();

  User? userById(String id) => _users[id];

  int get userCount => _users.length;

  /// Foydalanuvchini bazaga yozish uchun belgilaydi (yangi yoki rol o'zgardi).
  void saveUser(User u) => changes.save(
    'users',
    u.id,
    () => (
      columns: {'phone_hash': u.phoneHash, 'role': u.role.name},
      data: {
        'phoneEnc': u.phoneEnc,
        'createdAt': u.createdAt.toIso8601String(),
        'blocked': u.blocked,
        'blockReason': u.blockReason,
      },
    ),
  );

  Iterable<User> get users => _users.values;

  /// Admin qidiruvi: to'liq raqam bo'yicha (raqam ochiq saqlanmaydi, shuning
  /// uchun faqat xesh orqali aniq moslik).
  User? byPhone(String phone) {
    if (!_phoneRe.hasMatch(phone)) return null;
    final h = _hash(phone);
    return _users.values.where((u) => u.phoneHash == h).firstOrNull;
  }

  /// Admin uchun yashirilgan raqam: +99890***4567.
  Future<String> maskedPhone(User u) async {
    try {
      final p = await encryption.decrypt(u.phoneEnc, aad: 'user:${u.id}:phone');
      return p.length < 8
          ? '***'
          : '${p.substring(0, 6)}***${p.substring(p.length - 4)}';
    } catch (_) {
      return '***';
    }
  }

  void setBlocked(User u, {required bool blocked, String? reason}) {
    u
      ..blocked = blocked
      ..blockReason = blocked ? reason : null;
    saveUser(u);
  }

  /// Hisobni o'chirish: foydalanuvchi tizimdan o'chiriladi (barcha tokenlar
  /// darhol yaroqsiz), telefon raqami (shifrlangan va xeshi) yo'q qilinadi.
  /// Qator bazada qoladi — qonun bo'yicha saqlanadigan yozuvlar (to'lovlar,
  /// tibbiy xulosalar, audit) unga bog'langan, lekin endi shaxsni aniqlamaydi.
  /// Shu raqam bilan qayta kirilsa — yangi, bo'sh hisob ochiladi.
  void deleteUser(User u) {
    _users.remove(u.id);
    changes.save(
      'users',
      u.id,
      () => (
        columns: {'phone_hash': 'deleted:${u.id}', 'role': u.role.name},
        data: {
          'phoneEnc': '',
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
        },
      ),
    );
  }

  /// Ishga tushganda bazadan tiklash (o'chirilgan hisoblar tiklanmaydi).
  void restoreUsers(List<Map<String, dynamic>> rows) {
    for (final r in rows) {
      if ((r['phone_hash'] as String).startsWith('deleted:')) continue;
      final j = r['data'] as Map;
      final u =
          User(
              id: r['id'] as String,
              phoneHash: r['phone_hash'] as String,
              phoneEnc: j['phoneEnc'] as String,
              role: Role.values.byName(r['role'] as String),
              createdAt: j['createdAt'] == null
                  ? null
                  : DateTime.parse(j['createdAt'] as String),
            )
            ..blocked = j['blocked'] as bool? ?? false
            ..blockReason = j['blockReason'] as String?;
      _users[u.id] = u;
    }
  }

  Future<void> requestOtp(String phone) async {
    if (!_phoneRe.hasMatch(phone)) {
      throw ApiException(400, 'invalid_phone', 'Format: +998XXXXXXXXX');
    }
    final code = List.generate(6, (_) => _random.nextInt(10)).join();
    _otps[_hash(phone)] = _OtpEntry(_hash(code), DateTime.now().add(otpTtl));
    await otpSender.send(phone, code);
  }

  Future<({String token, User user})> verifyOtp(
    String phone,
    String code,
  ) async {
    final key = _hash(phone);
    final entry = _otps[key];
    if (entry == null || DateTime.now().isAfter(entry.expires)) {
      throw ApiException(401, 'otp_expired');
    }
    if (++entry.attempts > maxOtpAttempts) {
      _otps.remove(key);
      throw ApiException(429, 'otp_attempts_exceeded');
    }
    // Vaqtga bog'liq bo'lmagan taqqoslash.
    final a = entry.codeHash, b = _hash(code);
    var diff = a.length ^ b.length;
    for (var i = 0; i < a.length && i < b.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    if (diff != 0) throw ApiException(401, 'otp_invalid');
    _otps.remove(key);

    var user = _users.values.where((u) => u.phoneHash == key).firstOrNull;
    if (user != null && user.blocked) {
      throw ApiException(
        403,
        'account_blocked',
        'Hisob bloklangan. Qo\'llab-quvvatlash xizmatiga murojaat qiling',
      );
    }
    if (user == null) {
      final id = const Uuid().v4();
      user = User(
        id: id,
        phoneHash: key,
        phoneEnc: await encryption.encrypt(phone, aad: 'user:$id:phone'),
        role: _adminPhones.contains(phone) ? Role.admin : Role.patient,
      );
      _users[id] = user;
      saveUser(user);
    }
    return (token: issueToken(user), user: user);
  }

  String issueToken(User user) => JWT(
    {'role': user.role.name},
    subject: user.id,
    issuer: 'medlink',
  ).sign(_jwtKey, expiresIn: accessTtl);

  /// So'rovdagi Bearer tokenni tekshiradi va foydalanuvchini kontekstga qo'yadi.
  Middleware middleware() =>
      (inner) => (req) async {
        final h = req.headers['authorization'];
        User? user;
        if (h != null && h.startsWith('Bearer ')) {
          try {
            final jwt = JWT.verify(h.substring(7), _jwtKey, issuer: 'medlink');
            user = _users[jwt.subject];
            // Bloklangan hisob tokenlari darhol ishlamay qoladi.
            if (user != null && user.blocked) user = null;
          } on JWTException {
            // Noto'g'ri token — anonim sifatida davom etadi.
          }
        }
        return inner(user == null ? req : req.change(context: {'user': user}));
      };
}

User requireUser(Request req, [Set<Role>? roles]) {
  final u = req.context['user'] as User?;
  if (u == null) throw ApiException(401, 'unauthorized');
  if (roles != null && !roles.contains(u.role)) {
    throw ApiException(403, 'forbidden');
  }
  return u;
}
