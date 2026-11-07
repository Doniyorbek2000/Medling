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

class Specialty {
  Specialty(this.code, this.name);
  final String code;
  final String name;
}

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
      startsAt = DateTime.parse(j['startsAt'] as String).toLocal(),
      priceUzs = j['priceUzs'] as int,
      status = j['status'] as String,
      reason = j['reason'] as String? ?? '';

  final String id;
  final Doctor? doctor;
  final DateTime startsAt;
  final int priceUzs;
  final String status;
  final String reason;
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
