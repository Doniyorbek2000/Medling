import 'package:uuid/uuid.dart';

import '../core/http_utils.dart';
import '../security/field_encryption.dart';
import 'specialties.dart';

/// Shifokor profili holati. Faqat `approved` profillar bemorlarga ko'rinadi.
enum ModerationStatus { pending, approved, rejected, suspended }

class DoctorProfile {
  DoctorProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.specialty,
    required this.experienceYears,
    required this.clinic,
    required this.city,
    required this.priceUzs,
    required this.licenseNumberEnc,
    required this.documentRefsEnc,
    this.bio = '',
    this.languages = const ['uz', 'ru'],
    this.status = ModerationStatus.pending,
    this.rating = 0,
    this.reviewCount = 0,
  });

  final String id;
  final String userId;
  final String fullName;
  final String specialty;
  final int experienceYears;
  final String clinic;
  final String city;
  final int priceUzs;
  final String bio;
  final List<String> languages;

  /// Litsenziya raqami va hujjatlar (diplom, sertifikat) — shifrlangan.
  final String licenseNumberEnc;
  final String documentRefsEnc;

  ModerationStatus status;
  String? moderatorId;
  String? moderationNote;
  DateTime? moderatedAt;
  double rating;
  int reviewCount;

  Map<String, dynamic> toPublicJson() => {
    'id': id,
    'fullName': fullName,
    'specialty': specialty,
    'specialtyName': specialties[specialty],
    'experienceYears': experienceYears,
    'clinic': clinic,
    'city': city,
    'priceUzs': priceUzs,
    'bio': bio,
    'languages': languages,
    'rating': rating,
    'reviewCount': reviewCount,
    'verified': status == ModerationStatus.approved,
  };
}

/// Shifokorlar bazasi va moderatsiya jarayoni:
///   ariza (pending) -> admin tekshiruvi -> approved | rejected
///   approved -> suspended (shikoyat/litsenziya muddati tugashi)
/// Har bir qaror moderator ID'si, vaqti va izohi bilan saqlanadi.
class DoctorService {
  DoctorService(this.encryption);
  final FieldEncryption encryption;
  final _doctors = <String, DoctorProfile>{};

  Iterable<DoctorProfile> get all => _doctors.values;

  Future<DoctorProfile> apply(String userId, Map<String, dynamic> j) async {
    if (_doctors.values.any(
      (d) => d.userId == userId && d.status != ModerationStatus.rejected,
    )) {
      throw ApiException(409, 'already_applied');
    }
    final specialty = j['specialty'] as String?;
    if (!specialties.containsKey(specialty)) {
      throw ApiException(400, 'invalid_specialty');
    }
    final fullName = (j['fullName'] as String? ?? '').trim();
    final license = (j['licenseNumber'] as String? ?? '').trim();
    final docs = (j['documentRefs'] as List? ?? const []).cast<String>();
    if (fullName.length < 5 || license.length < 4 || docs.isEmpty) {
      throw ApiException(
        400,
        'incomplete_application',
        'F.I.Sh., litsenziya raqami va hujjatlar majburiy',
      );
    }
    final id = const Uuid().v4();
    final d = DoctorProfile(
      id: id,
      userId: userId,
      fullName: fullName,
      specialty: specialty!,
      experienceYears: j['experienceYears'] as int? ?? 0,
      clinic: j['clinic'] as String? ?? '',
      city: j['city'] as String? ?? 'Toshkent',
      priceUzs: j['priceUzs'] as int? ?? 0,
      bio: j['bio'] as String? ?? '',
      licenseNumberEnc: await encryption.encrypt(
        license,
        aad: 'doctor:$id:license',
      ),
      documentRefsEnc: await encryption.encrypt(
        docs.join('\n'),
        aad: 'doctor:$id:docs',
      ),
    );
    _doctors[id] = d;
    return d;
  }

  DoctorProfile? byId(String id) => _doctors[id];

  /// Faqat ishlab chiqish rejimi uchun: tasdiqlangan demo shifokorlar.
  Future<void> seedDemo() async {
    const demo = [
      (
        'Karimova Dilnoza Rustamovna',
        'therapist',
        12,
        'Shifo Med',
        150000,
        4.8,
        124,
      ),
      (
        'Abdullayev Jasur Akmalovich',
        'cardiologist',
        18,
        'Respublika kardiologiya markazi',
        250000,
        4.9,
        210,
      ),
      (
        'Yusupova Malika Botirovna',
        'pediatrician',
        9,
        'Bolalar poliklinikasi №5',
        140000,
        4.7,
        98,
      ),
      (
        'Rahimov Sardor Ilhomovich',
        'neurologist',
        15,
        'Neuro Clinic',
        220000,
        4.6,
        76,
      ),
      (
        'Tursunova Nigora Shavkatovna',
        'gynecologist',
        11,
        'Ayollar salomatligi markazi',
        200000,
        4.8,
        143,
      ),
      (
        'Ergashev Bobur Hamidovich',
        'dermatologist',
        7,
        'Derma Plus',
        180000,
        4.5,
        51,
      ),
      ('Saidova Gulnora Anvarovna', 'ent', 14, 'LOR Klinika', 170000, 4.7, 88),
      (
        'Nazarov Otabek Farhodovich',
        'gastroenterologist',
        10,
        'MedLife',
        210000,
        4.6,
        64,
      ),
    ];
    var i = 0;
    for (final (name, spec, exp, clinic, price, rating, reviews) in demo) {
      final d = await apply('demo-${i++}', {
        'fullName': name,
        'specialty': spec,
        'licenseNumber': 'DEMO-${1000 + i}',
        'documentRefs': ['demo://license'],
        'experienceYears': exp,
        'clinic': clinic,
        'city': 'Toshkent',
        'priceUzs': price,
        'bio':
            '$exp yillik tajribaga ega shifokor. O\'zbek va rus tillarida '
            'qabul qiladi.',
      });
      d
        ..status = ModerationStatus.approved
        ..rating = rating
        ..reviewCount = reviews;
    }
  }

  DoctorProfile? byUser(String userId) =>
      _doctors.values.where((d) => d.userId == userId).lastOrNull;

  List<DoctorProfile> search({String? specialty, String? city, String? q}) =>
      _doctors.values
          .where((d) => d.status == ModerationStatus.approved)
          .where((d) => specialty == null || d.specialty == specialty)
          .where((d) => city == null || d.city == city)
          .where(
            (d) =>
                q == null ||
                d.fullName.toLowerCase().contains(q.toLowerCase()) ||
                d.clinic.toLowerCase().contains(q.toLowerCase()),
          )
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

  List<DoctorProfile> pending() => _doctors.values
      .where((d) => d.status == ModerationStatus.pending)
      .toList();

  /// Moderator uchun to'liq ma'lumot (shifrlangan maydonlar ochiladi).
  Future<Map<String, dynamic>> moderationView(DoctorProfile d) async => {
    ...d.toPublicJson(),
    'status': d.status.name,
    'licenseNumber': await encryption.decrypt(
      d.licenseNumberEnc,
      aad: 'doctor:${d.id}:license',
    ),
    'documentRefs': (await encryption.decrypt(
      d.documentRefsEnc,
      aad: 'doctor:${d.id}:docs',
    )).split('\n'),
  };

  DoctorProfile moderate(
    String doctorId,
    String moderatorId,
    ModerationStatus decision,
    String? note,
  ) {
    final d = _doctors[doctorId] ?? (throw ApiException(404, 'not_found'));
    const allowed = {
      ModerationStatus.pending: {
        ModerationStatus.approved,
        ModerationStatus.rejected,
      },
      ModerationStatus.approved: {ModerationStatus.suspended},
      ModerationStatus.suspended: {ModerationStatus.approved},
    };
    if (!(allowed[d.status]?.contains(decision) ?? false)) {
      throw ApiException(
        409,
        'invalid_transition',
        '${d.status.name} -> ${decision.name}',
      );
    }
    if (decision == ModerationStatus.rejected &&
        (note == null || note.trim().isEmpty)) {
      throw ApiException(400, 'note_required', 'Rad etish sababi majburiy');
    }
    d
      ..status = decision
      ..moderatorId = moderatorId
      ..moderationNote = note
      ..moderatedAt = DateTime.now().toUtc();
    return d;
  }
}
