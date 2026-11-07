import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../core/http_utils.dart';
import '../doctors/doctors.dart';
import '../security/field_encryption.dart';

enum AppointmentStatus { awaitingPayment, confirmed, completed, cancelled }

class Appointment {
  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.startsAt,
    required this.priceUzs,
    required this.reasonEnc,
    this.triageId,
    this.type = 'clinic',
  });

  final String id;
  final String patientId;
  final String doctorId;
  final DateTime startsAt;
  final int priceUzs;
  final String reasonEnc;
  final String? triageId;

  /// `clinic` — klinikada, `online` — video konsultatsiya.
  final String type;
  AppointmentStatus status = AppointmentStatus.awaitingPayment;
  final DateTime createdAt = DateTime.now().toUtc();
  Review? review;

  /// Server push eslatmasi yuborilganmi (takror yubormaslik uchun).
  bool reminderSent = false;

  /// Shifokor xulosasi (tashxis, tavsiyalar, retsept) — shifrlangan JSON.
  String? conclusionEnc;
  DateTime? conclusionAt;

  /// Shifokor video xonaga birinchi marta kirganda bemorga xabar beriladi.
  bool doctorJoinedVideo = false;

  bool get isOnline => type == 'online';
}

/// Retseptdagi bitta dori.
class Prescription {
  Prescription({
    required this.drug,
    required this.dose,
    required this.frequency,
    required this.durationDays,
    this.notes = '',
  });

  final String drug;
  final String dose;
  final String frequency;
  final int durationDays;
  final String notes;

  static Prescription fromJson(Map<String, dynamic> j) {
    String str(String k, int max) {
      final v = (j[k] as String? ?? '').trim();
      if (v.length > max) throw ApiException(400, 'invalid_conclusion', k);
      return v;
    }

    final p = Prescription(
      drug: str('drug', 120),
      dose: str('dose', 60),
      frequency: str('frequency', 120),
      durationDays: j['durationDays'] as int? ?? 0,
      notes: str('notes', 300),
    );
    if (p.drug.isEmpty || p.durationDays < 0 || p.durationDays > 365) {
      throw ApiException(400, 'invalid_conclusion', 'prescription');
    }
    return p;
  }

  Map<String, dynamic> toJson() => {
    'drug': drug,
    'dose': dose,
    'frequency': frequency,
    'durationDays': durationDays,
    'notes': notes,
  };
}

class Review {
  Review({
    required this.rating,
    required this.comment,
    required this.authorName,
  });
  final int rating;
  final String comment;

  /// Faqat ism (familiyasiz) ko'rsatiladi.
  final String authorName;
  final DateTime at = DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'comment': comment,
    'authorName': authorName,
    'at': at.toIso8601String(),
  };
}

/// Qabullarni boshqarish. Slotlar 30 daqiqalik, ish vaqti 09:00–18:00
/// (Toshkent vaqti, UTC+5). To'lanmagan bron 15 daqiqadan keyin bo'shatiladi.
class AppointmentService {
  AppointmentService(this.doctors, this.encryption);
  final DoctorService doctors;
  final FieldEncryption encryption;
  final _items = <String, Appointment>{};

  /// Bildirishnomalar uchun hodisalar (main/server'da ulanadi).
  void Function(Appointment a)? onConfirmed;
  void Function(Appointment a, String actorUserId)? onCancelled;
  void Function(Appointment a)? onConclusion;

  static const slot = Duration(minutes: 30);
  static const holdFor = Duration(minutes: 15);
  static const tashkent = Duration(hours: 5);

  Appointment? byId(String id) => _items[id];

  bool _blocks(Appointment a) =>
      a.status == AppointmentStatus.confirmed ||
      (a.status == AppointmentStatus.awaitingPayment &&
          DateTime.now().toUtc().difference(a.createdAt) < holdFor);

  /// Shifokor jadvali bo'yicha bo'sh slotlar ([dayUtc] — Toshkent sanasi).
  List<DateTime> freeSlots(String doctorId, DateTime dayUtc) {
    final d = doctors.byId(doctorId);
    final localDay = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day);
    if (d == null || !d.workDays.contains(localDay.weekday)) return const [];
    final taken = _items.values
        .where((a) => a.doctorId == doctorId && _blocks(a))
        .map((a) => a.startsAt)
        .toSet();
    final now = DateTime.now().toUtc();
    return [
      for (
        var t = localDay.add(Duration(hours: d.startHour)).subtract(tashkent);
        t.isBefore(localDay.add(Duration(hours: d.endHour)).subtract(tashkent));
        t = t.add(slot)
      )
        if (t.isAfter(now) && !taken.contains(t)) t,
    ];
  }

  Future<Appointment> book({
    required String patientId,
    required String doctorId,
    required DateTime startsAt,
    required String reason,
    String? triageId,
    String type = 'clinic',
  }) async {
    final d = doctors.byId(doctorId);
    if (d == null || d.status != ModerationStatus.approved) {
      throw ApiException(404, 'doctor_not_found');
    }
    if ((type != 'clinic' && type != 'online') || !d.offers(type)) {
      throw ApiException(400, 'consultation_type_unavailable');
    }
    final t = startsAt.toUtc();
    if (!freeSlots(doctorId, t.add(tashkent)).contains(t)) {
      throw ApiException(409, 'slot_unavailable');
    }
    final id = const Uuid().v4();
    final a = Appointment(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      startsAt: t,
      priceUzs: d.priceFor(type),
      triageId: triageId,
      type: type,
      reasonEnc: await encryption.encrypt(reason, aad: 'appt:$id:reason'),
    );
    _items[id] = a;
    return a;
  }

  void markPaid(String id) {
    final a = _items[id];
    if (a != null && a.status == AppointmentStatus.awaitingPayment) {
      a.status = AppointmentStatus.confirmed;
      onConfirmed?.call(a);
    }
  }

  /// Bemor yoki shu qabul shifokori bo'lsa — rolini qaytaradi.
  String? participantRole(Appointment a, String userId) {
    if (a.patientId == userId) return 'patient';
    if (doctors.byId(a.doctorId)?.userId == userId) return 'doctor';
    return null;
  }

  Appointment requireParticipant(String id, String userId) {
    final a = _items[id] ?? (throw ApiException(404, 'not_found'));
    if (participantRole(a, userId) == null) {
      throw ApiException(403, 'forbidden');
    }
    return a;
  }

  /// Shifokor xulosasi. Qabul boshlangandan keyin yoziladi va qabulni
  /// yakunlaydi. Xulosani faqat shu qabul shifokori o'zgartira oladi.
  Future<void> setConclusion(
    String id,
    String doctorUserId,
    Map<String, dynamic> j, {
    DateTime? now,
  }) async {
    final a = _items[id] ?? (throw ApiException(404, 'not_found'));
    if (doctors.byId(a.doctorId)?.userId != doctorUserId) {
      throw ApiException(403, 'forbidden');
    }
    if (a.status != AppointmentStatus.confirmed &&
        a.status != AppointmentStatus.completed) {
      throw ApiException(409, 'not_confirmed');
    }
    if ((now ?? DateTime.now()).toUtc().isBefore(a.startsAt)) {
      throw ApiException(409, 'not_started');
    }
    final diagnosis = (j['diagnosis'] as String? ?? '').trim();
    final recommendations = (j['recommendations'] as String? ?? '').trim();
    if (diagnosis.isEmpty ||
        diagnosis.length > 500 ||
        recommendations.length > 4000) {
      throw ApiException(400, 'invalid_conclusion');
    }
    final prescriptions = [
      for (final p in (j['prescriptions'] as List? ?? const []))
        Prescription.fromJson(p as Map<String, dynamic>),
    ];
    if (prescriptions.length > 20) {
      throw ApiException(400, 'invalid_conclusion', 'prescriptions');
    }
    final followUp = j['followUpDays'] as int?;
    final payload = jsonEncode({
      'diagnosis': diagnosis,
      'recommendations': recommendations,
      'prescriptions': [for (final p in prescriptions) p.toJson()],
      'followUpDays': followUp,
    });
    a
      ..conclusionEnc = await encryption.encrypt(
        payload,
        aad: 'appt:${a.id}:conclusion',
      )
      ..conclusionAt = DateTime.now().toUtc()
      ..status = AppointmentStatus.completed;
    onConclusion?.call(a);
  }

  /// Boshlanishiga [lead] dan kam qolgan, eslatma yuborilmagan qabullar.
  List<Appointment> dueForReminder(DateTime now, Duration lead) => [
    for (final a in _items.values)
      if (a.status == AppointmentStatus.confirmed &&
          !a.reminderSent &&
          a.startsAt.isAfter(now) &&
          a.startsAt.difference(now) <= lead)
        a,
  ];

  void cancel(String id, String actorUserId) {
    final a = _items[id] ?? (throw ApiException(404, 'not_found'));
    final d = doctors.byId(a.doctorId);
    if (a.patientId != actorUserId && d?.userId != actorUserId) {
      throw ApiException(403, 'forbidden');
    }
    if (a.status == AppointmentStatus.completed) {
      throw ApiException(409, 'already_completed');
    }
    // Faqat tasdiqlangan qabul bekor qilinsa xabar beriladi (to'lanmagan
    // bron haqida shifokor bilmagan).
    final wasConfirmed = a.status == AppointmentStatus.confirmed;
    a.status = AppointmentStatus.cancelled;
    if (wasConfirmed) onCancelled?.call(a, actorUserId);
  }

  /// Shifokor qabulni yakunlaydi (faqat to'langan va boshlangan qabul).
  void complete(String id, String doctorUserId) {
    final a = _items[id] ?? (throw ApiException(404, 'not_found'));
    if (doctors.byId(a.doctorId)?.userId != doctorUserId) {
      throw ApiException(403, 'forbidden');
    }
    if (a.status != AppointmentStatus.confirmed) {
      throw ApiException(409, 'not_confirmed');
    }
    if (DateTime.now().toUtc().isBefore(a.startsAt)) {
      throw ApiException(409, 'not_started');
    }
    a.status = AppointmentStatus.completed;
  }

  /// Bemor yakunlangan qabul uchun bir marta baho qoldiradi.
  void addReview(
    String id,
    String patientId, {
    required int rating,
    required String comment,
    required String authorName,
  }) {
    final a = _items[id] ?? (throw ApiException(404, 'not_found'));
    if (a.patientId != patientId) throw ApiException(403, 'forbidden');
    if (a.status != AppointmentStatus.completed) {
      throw ApiException(409, 'not_completed');
    }
    if (a.review != null) throw ApiException(409, 'already_reviewed');
    if (rating < 1 || rating > 5 || comment.length > 1000) {
      throw ApiException(400, 'invalid_review');
    }
    a.review = Review(
      rating: rating,
      comment: comment.trim(),
      authorName: authorName,
    );
    final d = doctors.byId(a.doctorId)!;
    d.rating = (d.rating * d.reviewCount + rating) / (d.reviewCount + 1);
    d.reviewCount++;
  }

  List<Review> reviewsFor(String doctorId) => [
    for (final a in _items.values)
      if (a.doctorId == doctorId && a.review != null) a.review!,
  ]..sort((x, y) => y.at.compareTo(x.at));

  List<Appointment> forPatient(String userId) =>
      _items.values.where((a) => a.patientId == userId).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  List<Appointment> forDoctor(String doctorId) =>
      _items.values.where((a) => a.doctorId == doctorId).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  Future<Map<String, dynamic>> toJson(Appointment a) async => {
    'id': a.id,
    'doctor': doctors.byId(a.doctorId)?.toPublicJson(),
    'startsAt': a.startsAt.toIso8601String(),
    'priceUzs': a.priceUzs,
    'status': a.status.name,
    'reason': await encryption.decrypt(a.reasonEnc, aad: 'appt:${a.id}:reason'),
    'triageId': a.triageId,
    'type': a.type,
    'review': a.review?.toJson(),
    'conclusion': a.conclusionEnc == null
        ? null
        : {
            ...jsonDecode(
              await encryption.decrypt(
                a.conclusionEnc!,
                aad: 'appt:${a.id}:conclusion',
              ),
            ) as Map<String, dynamic>,
            'at': a.conclusionAt!.toIso8601String(),
          },
  };
}
