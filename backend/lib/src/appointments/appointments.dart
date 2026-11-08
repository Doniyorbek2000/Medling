import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../core/http_utils.dart';
import '../doctors/doctors.dart';
import '../persistence/changes.dart';
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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final String patientId;
  final String doctorId;
  DateTime startsAt;
  final int priceUzs;
  final String reasonEnc;
  final String? triageId;

  /// `clinic` — klinikada, `online` — video konsultatsiya.
  final String type;
  AppointmentStatus status = AppointmentStatus.awaitingPayment;
  final DateTime createdAt;
  Review? review;

  /// Server push eslatmasi yuborilganmi (takror yubormaslik uchun).
  bool reminderSent = false;

  /// Shifokor xulosasi (tashxis, tavsiyalar, retsept) — shifrlangan JSON.
  String? conclusionEnc;
  DateTime? conclusionAt;

  /// Shifokor video xonaga birinchi marta kirganda bemorga xabar beriladi.
  bool doctorJoinedVideo = false;

  /// Bemor qabul vaqtini necha marta ko'chirgan.
  int rescheduleCount = 0;

  bool get isOnline => type == 'online';
}

/// Pul qaytarish siyosati: shifokor bekor qilsa — har doim; bemor qabuldan
/// kamida 24 soat oldin bekor qilsa — to'liq. Aks holda qaytarilmaydi.
/// Qaytariladigan bo'lsa — sabab, aks holda null.
String? refundReason(Appointment a, String cancelledByRole, DateTime now) {
  if (cancelledByRole == 'doctor') return 'doctor_cancelled';
  if (cancelledByRole == 'admin') return 'admin_cancelled';
  if (a.startsAt.difference(now) >= const Duration(hours: 24)) {
    return 'patient_cancelled_early';
  }
  return null;
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
    DateTime? at,
    this.hidden = false,
    this.hiddenReason,
  }) : at = at ?? DateTime.now().toUtc();
  final int rating;

  /// Admin yashirgan sharh (haqorat, shaxsiy ma'lumot, reklama). Reytingga
  /// kirmaydi va ommaviy ro'yxatda ko'rinmaydi; bemorning o'zi ko'radi.
  bool hidden;
  String? hiddenReason;
  final String comment;

  /// Faqat ism (familiyasiz) ko'rsatiladi.
  final String authorName;
  final DateTime at;

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
  void Function(Appointment a, DateTime previous)? onRescheduled;

  /// Vaqtni ko'chirish qoidasi: qabulgacha kamida 24 soat qolganda va
  /// ko'pi bilan 2 marta (pul qaytarish qoidasi bilan bir xil chegara).
  static const changeDeadline = Duration(hours: 24);
  static const maxReschedules = 2;

  static const slot = Duration(minutes: 30);
  static const holdFor = Duration(minutes: 15);
  static const tashkent = Duration(hours: 5);

  Appointment? byId(String id) => _items[id];

  Iterable<Appointment> get all => _items.values;

  bool _blocks(Appointment a) =>
      a.status == AppointmentStatus.confirmed ||
      (a.status == AppointmentStatus.awaitingPayment &&
          DateTime.now().toUtc().difference(a.createdAt) < holdFor);

  /// Shifokor jadvali bo'yicha bo'sh slotlar ([dayUtc] — Toshkent sanasi).
  List<DateTime> freeSlots(String doctorId, DateTime dayUtc) {
    final d = doctors.byId(doctorId);
    final localDay = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day);
    if (d == null ||
        !d.workDays.contains(localDay.weekday) ||
        d.isDayOff(localDay)) {
      return const [];
    }
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
    persist(a);
    return a;
  }

  void markPaid(String id) {
    final a = _items[id];
    if (a != null && a.status == AppointmentStatus.awaitingPayment) {
      a.status = AppointmentStatus.confirmed;
      persist(a);
      onConfirmed?.call(a);
    }
  }

  /// Qabulni bazaga yozish uchun belgilaydi.
  void persist(Appointment a) => changes.save(
    'appointments',
    a.id,
    () => (
      columns: {
        'patient_id': a.patientId,
        'doctor_id': a.doctorId,
        'starts_at': a.startsAt,
        'status': a.status.name,
      },
      data: {
        'priceUzs': a.priceUzs,
        'reasonEnc': a.reasonEnc,
        'triageId': a.triageId,
        'type': a.type,
        'createdAt': a.createdAt.toIso8601String(),
        'review': a.review == null
            ? null
            : {
                ...a.review!.toJson(),
                'at': a.review!.at.toIso8601String(),
                'hidden': a.review!.hidden,
                'hiddenReason': a.review!.hiddenReason,
              },
        'reminderSent': a.reminderSent,
        'conclusionEnc': a.conclusionEnc,
        'conclusionAt': a.conclusionAt?.toIso8601String(),
        'doctorJoinedVideo': a.doctorJoinedVideo,
        'rescheduleCount': a.rescheduleCount,
      },
    ),
  );

  /// Ishga tushganda bazadan tiklash.
  void restore(List<Map<String, dynamic>> rows) {
    for (final r in rows) {
      final j = r['data'] as Map<String, dynamic>;
      final rv = j['review'] as Map<String, dynamic>?;
      final a =
          Appointment(
              id: r['id'] as String,
              patientId: r['patient_id'] as String,
              doctorId: r['doctor_id'] as String,
              startsAt: (r['starts_at'] as DateTime).toUtc(),
              priceUzs: j['priceUzs'] as int,
              reasonEnc: j['reasonEnc'] as String,
              triageId: j['triageId'] as String?,
              type: j['type'] as String? ?? 'clinic',
              createdAt: DateTime.parse(j['createdAt'] as String),
            )
            ..status = AppointmentStatus.values.byName(r['status'] as String)
            ..reminderSent = j['reminderSent'] as bool? ?? false
            ..conclusionEnc = j['conclusionEnc'] as String?
            ..conclusionAt = j['conclusionAt'] == null
                ? null
                : DateTime.parse(j['conclusionAt'] as String)
            ..doctorJoinedVideo = j['doctorJoinedVideo'] as bool? ?? false
            ..rescheduleCount = j['rescheduleCount'] as int? ?? 0
            ..review = rv == null
                ? null
                : Review(
                    rating: rv['rating'] as int,
                    comment: rv['comment'] as String,
                    authorName: rv['authorName'] as String,
                    at: DateTime.parse(rv['at'] as String),
                    hidden: rv['hidden'] as bool? ?? false,
                    hiddenReason: rv['hiddenReason'] as String?,
                  );
      _items[a.id] = a;
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
    persist(a);
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

  /// [bySystem] — admin yoki tizim (hisob bloklanganda, shifokor
  /// to'xtatilganda): ishtirokchi tekshiruvi o'tkazilmaydi.
  void cancel(String id, String actorUserId, {bool bySystem = false}) {
    final a = _items[id] ?? (throw ApiException(404, 'not_found'));
    final d = doctors.byId(a.doctorId);
    if (!bySystem && a.patientId != actorUserId && d?.userId != actorUserId) {
      throw ApiException(403, 'forbidden');
    }
    if (a.status == AppointmentStatus.completed) {
      throw ApiException(409, 'already_completed');
    }
    // Faqat tasdiqlangan qabul bekor qilinsa xabar beriladi (to'lanmagan
    // bron haqida shifokor bilmagan).
    final wasConfirmed = a.status == AppointmentStatus.confirmed;
    a.status = AppointmentStatus.cancelled;
    persist(a);
    if (wasConfirmed) onCancelled?.call(a, actorUserId);
  }

  /// Bemor qabulni shu shifokorning boshqa bo'sh vaqtiga ko'chiradi.
  /// To'lov saqlanadi; eslatmalar yangi vaqt bo'yicha qayta yuboriladi.
  Appointment reschedule(
    String id,
    String patientId,
    DateTime newStartsAt, {
    DateTime? now,
  }) {
    final a = _items[id] ?? (throw ApiException(404, 'not_found'));
    if (a.patientId != patientId) throw ApiException(403, 'forbidden');
    if (a.status != AppointmentStatus.confirmed &&
        a.status != AppointmentStatus.awaitingPayment) {
      throw ApiException(409, 'not_reschedulable');
    }
    final n = (now ?? DateTime.now()).toUtc();
    if (a.startsAt.difference(n) < changeDeadline) {
      throw ApiException(409, 'too_late_to_reschedule');
    }
    if (a.rescheduleCount >= maxReschedules) {
      throw ApiException(409, 'reschedule_limit');
    }
    final d = doctors.byId(a.doctorId);
    if (d == null ||
        d.status != ModerationStatus.approved ||
        !d.offers(a.type)) {
      throw ApiException(409, 'doctor_unavailable');
    }
    final t = newStartsAt.toUtc();
    if (t == a.startsAt ||
        !freeSlots(a.doctorId, t.add(tashkent)).contains(t)) {
      throw ApiException(409, 'slot_unavailable');
    }
    final previous = a.startsAt;
    a
      ..startsAt = t
      ..rescheduleCount += 1
      ..reminderSent = false
      ..doctorJoinedVideo = false;
    persist(a);
    if (a.status == AppointmentStatus.confirmed) {
      onRescheduled?.call(a, previous);
    }
    return a;
  }

  /// Bemor yoki shifokorning kelgusi faol qabullari (hisob o'chirilganda).
  List<Appointment> activeFor({String? patientId, String? doctorId}) => [
    for (final a in _items.values)
      if ((patientId != null && a.patientId == patientId ||
              doctorId != null && a.doctorId == doctorId) &&
          (a.status == AppointmentStatus.confirmed ||
              a.status == AppointmentStatus.awaitingPayment))
        a,
  ];

  /// Hisob o'chirilganda bemor sharhidagi ism olib tashlanadi.
  void anonymizeReviews(String patientId) {
    for (final a in _items.values) {
      final r = a.review;
      if (a.patientId == patientId && r != null) {
        a.review = Review(
          rating: r.rating,
          comment: r.comment,
          authorName: '—',
          at: r.at,
          hidden: r.hidden,
          hiddenReason: r.hiddenReason,
        );
        persist(a);
      }
    }
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
    persist(a);
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
    persist(a);
    doctors.persist(d);
  }

  List<Review> reviewsFor(String doctorId) => [
    for (final a in _items.values)
      if (a.doctorId == doctorId && a.review != null && !a.review!.hidden)
        a.review!,
  ]..sort((x, y) => y.at.compareTo(x.at));

  /// Admin uchun: shifokorning barcha sharhlari (yashirilganlari bilan).
  List<Appointment> reviewedFor(String doctorId) => [
    for (final a in _items.values)
      if (a.doctorId == doctorId && a.review != null) a,
  ]..sort((x, y) => y.review!.at.compareTo(x.review!.at));

  /// Sharhni yashirish/qaytarish. Shifokor reytingi qayta hisoblanadi.
  Appointment setReviewHidden(
    String id, {
    required bool hidden,
    String? reason,
  }) {
    final a = _items[id];
    final r = a?.review;
    if (a == null || r == null) throw ApiException(404, 'not_found');
    if (r.hidden == hidden) return a;
    final d = doctors.byId(a.doctorId)!;
    if (hidden) {
      d.rating = d.reviewCount <= 1
          ? 0
          : (d.rating * d.reviewCount - r.rating) / (d.reviewCount - 1);
      d.reviewCount = d.reviewCount <= 1 ? 0 : d.reviewCount - 1;
    } else {
      d.rating = (d.rating * d.reviewCount + r.rating) / (d.reviewCount + 1);
      d.reviewCount++;
    }
    r
      ..hidden = hidden
      ..hiddenReason = hidden ? reason : null;
    persist(a);
    doctors.persist(d);
    return a;
  }

  /// To'lanmagan bronlar bron muddati tugagach bekor qilinadi (ro'yxatda
  /// "to'lov kutilmoqda" bo'lib qolib ketmasligi uchun). Qaytaradi: bekor
  /// qilinganlar.
  List<Appointment> expireUnpaid(DateTime now) {
    final out = <Appointment>[];
    for (final a in _items.values) {
      if (a.status == AppointmentStatus.awaitingPayment &&
          now.difference(a.createdAt) > holdFor + paymentGrace) {
        a.status = AppointmentStatus.cancelled;
        persist(a);
        out.add(a);
      }
    }
    return out;
  }

  /// To'lov sahifasida boshlangan to'lov yakunlanishi uchun qo'shimcha vaqt.
  static const paymentGrace = Duration(minutes: 15);

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
    'reschedulesLeft': maxReschedules - a.rescheduleCount,
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
