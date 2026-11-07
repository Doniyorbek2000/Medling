class Doctor {
  Doctor.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      fullName = j['fullName'] as String,
      specialty = j['specialty'] as String,
      specialtyName = j['specialtyName'] as String? ?? '',
      experienceYears = j['experienceYears'] as int? ?? 0,
      clinic = j['clinic'] as String? ?? '',
      city = j['city'] as String? ?? '',
      priceUzs = j['priceUzs'] as int? ?? 0,
      bio = j['bio'] as String? ?? '',
      rating = (j['rating'] as num? ?? 0).toDouble(),
      reviewCount = j['reviewCount'] as int? ?? 0,
      verified = j['verified'] as bool? ?? false;

  final String id;
  final String fullName;
  final String specialty;
  final String specialtyName;
  final int experienceYears;
  final String clinic;
  final String city;
  final int priceUzs;
  final String bio;
  final double rating;
  final int reviewCount;
  final bool verified;

  String get initials => fullName
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0])
      .join();
}

/// Backend bilan mos mutaxassislik kodlari.
const specialtyCodes = [
  'therapist',
  'pediatrician',
  'cardiologist',
  'neurologist',
  'gastroenterologist',
  'pulmonologist',
  'endocrinologist',
  'dermatologist',
  'ent',
  'ophthalmologist',
  'gynecologist',
  'urologist',
  'traumatologist',
  'psychiatrist',
];

enum Urgency { emergency, urgent, routine, selfCare }

class TriageResult {
  TriageResult.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      urgency = Urgency.values.firstWhere(
        (u) => u.name == j['urgency'],
        orElse: () => Urgency.urgent,
      ),
      conditions = [
        for (final c in (j['conditions'] as List? ?? const []))
          (
            name: c['name'] as String,
            likelihood: c['likelihood'] as String,
            rationale: c['rationale'] as String,
          ),
      ],
      specialties = (j['recommendedSpecialties'] as List? ?? const [])
          .cast<String>(),
      redFlags = (j['redFlags'] as List? ?? const []).cast<String>(),
      advice = j['advice'] as String? ?? '',
      disclaimer = j['disclaimer'] as String? ?? '';

  final String id;
  final Urgency urgency;
  final List<({String name, String likelihood, String rationale})> conditions;
  final List<String> specialties;
  final List<String> redFlags;
  final String advice;
  final String disclaimer;
}

class Appointment {
  Appointment.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      doctor = j['doctor'] == null
          ? null
          : Doctor.fromJson(j['doctor'] as Map<String, dynamic>),
      // UTC sifatida saqlanadi; ko'rsatishda Toshkent vaqtiga o'tkaziladi.
      startsAt = DateTime.parse(j['startsAt'] as String).toUtc(),
      priceUzs = j['priceUzs'] as int,
      status = j['status'] as String,
      reason = j['reason'] as String? ?? '',
      review = j['review'] == null
          ? null
          : Review.fromJson(j['review'] as Map<String, dynamic>);

  final String id;
  final Doctor? doctor;
  final DateTime startsAt;
  final int priceUzs;
  final String status;
  final String reason;
  final Review? review;

  bool get isUpcoming =>
      (status == 'confirmed' || status == 'awaitingPayment') &&
      startsAt.isAfter(DateTime.now().subtract(const Duration(minutes: 30)));
}

class Review {
  Review.fromJson(Map<String, dynamic> j)
    : rating = j['rating'] as int,
      comment = j['comment'] as String? ?? '',
      authorName = j['authorName'] as String? ?? '',
      at = DateTime.parse(j['at'] as String).toLocal();

  final int rating;
  final String comment;
  final String authorName;
  final DateTime at;
}

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

  MedicalProfile.fromJson(Map<String, dynamic> j)
    : fullName = j['fullName'] as String? ?? '',
      birthDate = j['birthDate'] == null
          ? null
          : DateTime.parse(j['birthDate'] as String),
      sex = j['sex'] as String?,
      bloodType = j['bloodType'] as String?,
      heightCm = j['heightCm'] as int?,
      weightKg = j['weightKg'] as int?,
      allergies = (j['allergies'] as List? ?? const []).cast<String>(),
      chronicConditions = (j['chronicConditions'] as List? ?? const [])
          .cast<String>(),
      medications = (j['medications'] as List? ?? const []).cast<String>();

  final String fullName;
  final DateTime? birthDate;
  final String? sex;
  final String? bloodType;
  final int? heightCm;
  final int? weightKg;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> medications;

  int? get ageYears {
    final b = birthDate;
    if (b == null) return null;
    final now = DateTime.now();
    var age = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      age--;
    }
    return age;
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

class TriageHistoryItem {
  TriageHistoryItem.fromJson(Map<String, dynamic> j)
    : input = j['input'] as String? ?? '',
      at = DateTime.parse(j['at'] as String).toLocal(),
      result = TriageResult.fromJson(j);

  final String input;
  final DateTime at;
  final TriageResult result;
}

class DoctorApplication {
  DoctorApplication.fromJson(Map<String, dynamic> j)
    : doctor = Doctor.fromJson(j),
      status = j['status'] as String,
      moderationNote = j['moderationNote'] as String?;

  final Doctor doctor;
  final String status;
  final String? moderationNote;
}

class ConsentDoc {
  ConsentDoc.fromJson(Map<String, dynamic> j)
    : scope = j['scope'] as String,
      required = j['required'] as bool,
      version = j['version'] as String,
      granted = j['granted'] as bool;

  final String scope;
  final bool required;
  final String version;
  bool granted;
}
