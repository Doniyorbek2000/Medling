import 'dart:convert';

import '../core/http_utils.dart';
import '../persistence/changes.dart';
import '../security/field_encryption.dart';

/// Bemorning tibbiy profili (allergiyalar, surunkali kasalliklar, dorilar).
/// Butun profil bitta shifrlangan blob sifatida saqlanadi.
class MedicalProfile {
  MedicalProfile({
    this.fullName = '',
    this.birthDate,
    this.sex,
    this.bloodType,
    this.heightCm,
    this.weightKg,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.medications = const [],
  });

  final String fullName;
  final DateTime? birthDate;
  final String? sex;
  final String? bloodType;
  final int? heightCm;
  final int? weightKg;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> medications;

  static const bloodTypes = {
    'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', //
  };

  static List<String> _list(Object? v) {
    final l = (v as List? ?? const [])
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (l.length > 30 || l.any((s) => s.length > 120)) {
      throw ApiException(400, 'invalid_profile', 'Ro\'yxat juda uzun');
    }
    return l;
  }

  static MedicalProfile fromJson(Map<String, dynamic> j) {
    final birth = j['birthDate'] == null
        ? null
        : DateTime.parse(j['birthDate'] as String);
    if (birth != null && (birth.isAfter(DateTime.now()) || birth.year < 1900)) {
      throw ApiException(400, 'invalid_profile', 'birthDate');
    }
    final sex = j['sex'] as String?;
    if (sex != null && sex != 'male' && sex != 'female') {
      throw ApiException(400, 'invalid_profile', 'sex');
    }
    final blood = j['bloodType'] as String?;
    if (blood != null && !bloodTypes.contains(blood)) {
      throw ApiException(400, 'invalid_profile', 'bloodType');
    }
    final name = (j['fullName'] as String? ?? '').trim();
    if (name.length > 120) throw ApiException(400, 'invalid_profile', 'name');
    return MedicalProfile(
      fullName: name,
      birthDate: birth,
      sex: sex,
      bloodType: blood,
      heightCm: j['heightCm'] as int?,
      weightKg: j['weightKg'] as int?,
      allergies: _list(j['allergies']),
      chronicConditions: _list(j['chronicConditions']),
      medications: _list(j['medications']),
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'birthDate': birthDate?.toIso8601String().substring(0, 10),
    'sex': sex,
    'bloodType': bloodType,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'allergies': allergies,
    'chronicConditions': chronicConditions,
    'medications': medications,
  };
}

class MedicalProfileService {
  MedicalProfileService(this.encryption);
  final FieldEncryption encryption;
  final _store = <String, String>{};

  String _aad(String userId) => 'profile:$userId';

  Future<MedicalProfile> get(String userId) async {
    final enc = _store[userId];
    if (enc == null) return MedicalProfile();
    return MedicalProfile.fromJson(
      jsonDecode(await encryption.decrypt(enc, aad: _aad(userId)))
          as Map<String, dynamic>,
    );
  }

  Future<MedicalProfile> put(String userId, Map<String, dynamic> j) async {
    final p = MedicalProfile.fromJson(j);
    final enc = await encryption.encrypt(
      jsonEncode(p.toJson()),
      aad: _aad(userId),
    );
    _store[userId] = enc;
    changes.save(
      'medical_profiles',
      userId,
      () => (columns: const <String, Object?>{}, data: {'enc': enc}),
    );
    return p;
  }

  void delete(String userId) {
    _store.remove(userId);
    changes.delete('medical_profiles', 'id', userId);
  }

  void restore(List<Map<String, dynamic>> rows) {
    for (final r in rows) {
      _store[r['id'] as String] = (r['data'] as Map)['enc'] as String;
    }
  }
}
