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
      verified = j['verified'] as bool? ?? false,
      clinicEnabled = j['clinicEnabled'] as bool? ?? true,
      onlineEnabled = j['onlineEnabled'] as bool? ?? false,
      onlinePriceUzs = j['onlinePriceUzs'] as int? ?? 0,
      workDays = (j['workDays'] as List? ?? const [1, 2, 3, 4, 5, 6])
          .cast<int>()
          .toSet(),
      startHour = j['startHour'] as int? ?? 9,
      endHour = j['endHour'] as int? ?? 18;

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
  final bool clinicEnabled;
  final bool onlineEnabled;
  final int onlinePriceUzs;
  final Set<int> workDays;
  final int startHour;
  final int endHour;

  int priceFor(String type) => type == 'online' ? onlinePriceUzs : priceUzs;

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
          : Review.fromJson(j['review'] as Map<String, dynamic>),
      type = j['type'] as String? ?? 'clinic',
      conclusion = j['conclusion'] == null
          ? null
          : Conclusion.fromJson(j['conclusion'] as Map<String, dynamic>),
      myRole = j['myRole'] as String?,
      patientName = j['patientName'] as String?,
      refundStatus = j['refundStatus'] as String? ?? 'none',
      reschedulesLeft = j['reschedulesLeft'] as int? ?? 0,
      videoAvailable = j['videoAvailable'] as bool? ?? false;

  final String id;
  final Doctor? doctor;
  final DateTime startsAt;
  final int priceUzs;
  final String status;
  final String reason;
  final Review? review;

  /// `clinic` yoki `online`.
  final String type;
  final Conclusion? conclusion;

  /// `patient` | `doctor` — faqat GET /v1/appointments/{id} javobida.
  final String? myRole;

  /// Faqat shifokorga: bemor ismi (tibbiy profildan).
  final String? patientName;

  /// `none` | `requested` | `refunded`.
  final String refundStatus;

  /// Bemor bekor qilsa pul qaytariladimi (qabulgacha kamida 24 soat).
  bool refundableByPatientAt(DateTime now) =>
      startsAt.difference(now) >= const Duration(hours: 24);

  /// Bemor yana necha marta vaqtni ko'chira oladi (server qoidasi: 2).
  final int reschedulesLeft;

  /// Ko'chirish qoidasi serverdagi bilan bir xil: faol qabul, 24 soat oldin,
  /// limit tugamagan.
  bool canRescheduleAt(DateTime now) =>
      (status == 'confirmed' || status == 'awaitingPayment') &&
      reschedulesLeft > 0 &&
      refundableByPatientAt(now);
  final bool videoAvailable;

  bool get isOnline => type == 'online';

  /// Video xona ochiq bo'ladigan oraliq (server bilan bir xil).
  static const earlyJoin = Duration(minutes: 10);
  static const lateJoin = Duration(minutes: 60);

  bool videoOpenAt(DateTime now) =>
      isOnline &&
      status == 'confirmed' &&
      !now.isBefore(startsAt.subtract(earlyJoin)) &&
      now.isBefore(startsAt.add(lateJoin));

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

class Prescription {
  Prescription({
    required this.drug,
    this.dose = '',
    this.frequency = '',
    this.durationDays = 0,
    this.notes = '',
  });

  Prescription.fromJson(Map<String, dynamic> j)
    : drug = j['drug'] as String? ?? '',
      dose = j['dose'] as String? ?? '',
      frequency = j['frequency'] as String? ?? '',
      durationDays = j['durationDays'] as int? ?? 0,
      notes = j['notes'] as String? ?? '';

  final String drug;
  final String dose;
  final String frequency;
  final int durationDays;
  final String notes;

  Map<String, dynamic> toJson() => {
    'drug': drug,
    'dose': dose,
    'frequency': frequency,
    'durationDays': durationDays,
    'notes': notes,
  };
}

/// Shifokor xulosasi: tashxis, tavsiyalar, retsept.
class Conclusion {
  Conclusion({
    required this.diagnosis,
    this.recommendations = '',
    this.prescriptions = const [],
    this.followUpDays,
    this.at,
  });

  Conclusion.fromJson(Map<String, dynamic> j)
    : diagnosis = j['diagnosis'] as String? ?? '',
      recommendations = j['recommendations'] as String? ?? '',
      prescriptions = [
        for (final p in (j['prescriptions'] as List? ?? const []))
          Prescription.fromJson(p as Map<String, dynamic>),
      ],
      followUpDays = j['followUpDays'] as int?,
      at = j['at'] == null ? null : DateTime.parse(j['at'] as String).toLocal();

  final String diagnosis;
  final String recommendations;
  final List<Prescription> prescriptions;
  final int? followUpDays;
  final DateTime? at;

  Map<String, dynamic> toJson() => {
    'diagnosis': diagnosis,
    'recommendations': recommendations,
    'prescriptions': [for (final p in prescriptions) p.toJson()],
    'followUpDays': ?followUpDays,
  };
}

class ChatMessage {
  ChatMessage.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      seq = j['seq'] as int,
      senderRole = j['senderRole'] as String,
      mine = j['mine'] as bool,
      text = j['text'] as String,
      at = DateTime.parse(j['at'] as String).toLocal(),
      attachment = j['attachment'] == null
          ? null
          : ChatAttachment.fromJson(j['attachment'] as Map<String, dynamic>);

  final String id;
  final int seq;
  final String senderRole;
  final bool mine;
  final String text;
  final DateTime at;
  final ChatAttachment? attachment;
}

class ChatAttachment {
  ChatAttachment.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      mime = j['mime'] as String,
      size = j['size'] as int;

  final String id;
  final String name;
  final String mime;
  final int size;

  bool get isImage => mime.startsWith('image/');
}

/// Shifokor ish jadvali va konsultatsiya turlari.
class DoctorSettings {
  DoctorSettings({
    required this.clinicEnabled,
    required this.priceUzs,
    required this.onlineEnabled,
    required this.onlinePriceUzs,
    required this.workDays,
    required this.startHour,
    required this.endHour,
  });

  DoctorSettings.fromJson(Map<String, dynamic> j)
    : clinicEnabled = j['clinicEnabled'] as bool,
      priceUzs = j['priceUzs'] as int,
      onlineEnabled = j['onlineEnabled'] as bool,
      onlinePriceUzs = j['onlinePriceUzs'] as int,
      workDays = (j['workDays'] as List).cast<int>().toSet(),
      startHour = j['startHour'] as int,
      endHour = j['endHour'] as int;

  bool clinicEnabled;
  int priceUzs;
  bool onlineEnabled;
  int onlinePriceUzs;
  Set<int> workDays;
  int startHour;
  int endHour;

  Map<String, dynamic> toJson() => {
    'clinicEnabled': clinicEnabled,
    'priceUzs': priceUzs,
    'onlineEnabled': onlineEnabled,
    'onlinePriceUzs': onlinePriceUzs,
    'workDays': workDays.toList()..sort(),
    'startHour': startHour,
    'endHour': endHour,
  };
}

/// Shifokor uchun: qabul oldidan bemor haqida ma'lumot.
class PatientInfo {
  PatientInfo.fromJson(Map<String, dynamic> j)
    : profile = MedicalProfile.fromJson(j['profile'] as Map<String, dynamic>),
      triage = j['triage'] == null
          ? null
          : TriageResult.fromJson(j['triage'] as Map<String, dynamic>),
      triageInput = (j['triage'] as Map<String, dynamic>?)?['input'] as String?;

  final MedicalProfile profile;
  final TriageResult? triage;
  final String? triageInput;
}

/// Admin paneli ko'rsatkichlari.
class AdminStats {
  AdminStats.fromJson(Map<String, dynamic> j)
    : users = j['users'] as int,
      doctorsApproved = j['doctorsApproved'] as int,
      doctorsPending = j['doctorsPending'] as int,
      appointmentsByStatus = (j['appointmentsByStatus'] as Map)
          .cast<String, int>(),
      appointmentsToday = j['appointmentsToday'] as int,
      onlineShare = j['onlineShare'] as int,
      revenue30dUzs = j['revenue30dUzs'] as int,
      refundsPending = j['refundsPending'] as int,
      refundsPendingUzs = j['refundsPendingUzs'] as int;

  final int users;
  final int doctorsApproved;
  final int doctorsPending;
  final Map<String, int> appointmentsByStatus;
  final int appointmentsToday;
  final int onlineShare;
  final int revenue30dUzs;
  final int refundsPending;
  final int refundsPendingUzs;
}

/// Admin: qaytarilishi kerak bo'lgan to'lov.
class RefundRequest {
  RefundRequest.fromJson(Map<String, dynamic> j)
    : orderId = j['id'] as String,
      appointmentId = j['appointmentId'] as String,
      amountUzs = j['amountUzs'] as int,
      provider = j['provider'] as String,
      providerTxnId = j['providerTxnId'] as String?,
      reason = j['reason'] as String? ?? '',
      requestedAt = DateTime.parse(j['requestedAt'] as String).toLocal(),
      appointmentStartsAt = j['appointmentStartsAt'] == null
          ? null
          : DateTime.parse(j['appointmentStartsAt'] as String).toUtc();

  final String orderId;
  final String appointmentId;
  final int amountUzs;
  final String provider;
  final String? providerTxnId;
  final String reason;
  final DateTime requestedAt;
  final DateTime? appointmentStartsAt;
}
