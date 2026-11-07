import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Maydon darajasidagi shifrlash (AES-256-GCM).
///
/// Har bir tibbiy maydon (alomatlar, AI xulosasi, shifokor izohlari, litsenziya
/// hujjatlari) bazaga yozilishidan OLDIN shifrlanadi. Format:
///
///     enc:v1:KEY_ID:BASE64(nonce | ciphertext | mac)
///
/// `aad` (associated data) yozuv identifikatori va maydon nomini shifrga
/// bog'laydi — shu sababli bir yozuvning shifrlangan maydonini boshqa yozuvga
/// ko'chirib qo'yish (swap hujumi) dekriptsiyada aniqlanadi.
class FieldEncryption {
  FieldEncryption(this._keys, this._activeKeyId)
    : assert(_keys.containsKey(_activeKeyId));

  final Map<String, List<int>> _keys;
  final String _activeKeyId;
  final _algo = AesGcm.with256bits();

  static const _prefix = 'enc:v1:';

  Future<String> encrypt(String plaintext, {required String aad}) async {
    final key = SecretKey(_keys[_activeKeyId]!);
    final box = await _algo.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: _algo.newNonce(),
      aad: utf8.encode(aad),
    );
    return '$_prefix$_activeKeyId:${base64.encode(box.concatenation())}';
  }

  Future<String> decrypt(String token, {required String aad}) async {
    if (!token.startsWith(_prefix)) {
      throw const FormatException('Shifrlanmagan qiymat');
    }
    final rest = token.substring(_prefix.length);
    final sep = rest.indexOf(':');
    final keyId = rest.substring(0, sep);
    final keyBytes = _keys[keyId];
    if (keyBytes == null) throw StateError('Noma\'lum kalit: $keyId');
    final box = SecretBox.fromConcatenation(
      base64.decode(rest.substring(sep + 1)),
      nonceLength: _algo.nonceLength,
      macLength: _algo.macAlgorithm.macLength,
    );
    final clear = await _algo.decrypt(
      box,
      secretKey: SecretKey(keyBytes),
      aad: utf8.encode(aad),
    );
    return utf8.decode(clear);
  }

  /// Eski kalit bilan shifrlangan yozuvni faol kalitga o'tkazish (rotatsiya).
  Future<String> reencrypt(String token, {required String aad}) async =>
      encrypt(await decrypt(token, aad: aad), aad: aad);

  bool needsRotation(String token) =>
      !token.startsWith('$_prefix$_activeKeyId:');
}
