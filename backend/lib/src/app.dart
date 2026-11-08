import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'ai/triage_service.dart';
import 'appointments/appointments.dart';
import 'audit/audit_log.dart';
import 'auth/auth.dart';
import 'consent/consent.dart';
import 'core/http_utils.dart';
import 'doctors/doctors.dart';
import 'doctors/specialties.dart';
import 'legal/legal.dart';
import 'payments/click.dart';
import 'payments/orders.dart';
import 'payments/payme.dart';
import 'payments/wallet.dart';
import 'consultations/attachments.dart';
import 'consultations/chat.dart';
import 'consultations/video.dart';
import 'notifications/notifications.dart';
import 'profile/medical_profile.dart';

class MedLinkApi {
  MedLinkApi({
    required this.auth,
    required this.consents,
    required this.triage,
    required this.doctors,
    required this.appointments,
    required this.orders,
    required this.click,
    required this.payme,
    required this.wallet,
    required this.audit,
    required this.profiles,
    required this.devices,
    required this.notifications,
    required this.chat,
    required this.video,
    AttachmentService? attachments,
    required this.publicBaseUrl,
    this.trustProxy = false,
    LegalInfo legal = const LegalInfo(),
  }) : legal = LegalPages(legal),
       attachments =
           attachments ??
           AttachmentService(
             appointments: appointments,
             chat: chat,
             encryption: chat.encryption,
             store: MemoryAttachmentStore(),
           );

  final AuthService auth;
  final ConsentService consents;
  final TriageService triage;
  final DoctorService doctors;
  final AppointmentService appointments;
  final OrderRepository orders;
  final ClickMerchant click;
  final PaymeMerchant payme;
  final WalletGateway wallet;
  final AuditLog audit;
  final MedicalProfileService profiles;
  final DeviceRegistry devices;
  final NotificationService notifications;
  final ChatService chat;
  final VideoTokenIssuer video;
  final AttachmentService attachments;
  final String publicBaseUrl;
  final bool trustProxy;
  final LegalPages legal;

  final _rate = <String, List<DateTime>>{};

  /// WebSocket ulanishining eng uzoq muddati (access token muddati).
  static const liveMaxAge = AuthService.accessTtl;

  /// Oddiy sliding-window limitlovchi (OTP brute-force'ga qarshi).
  /// Mijoz IP manzili. Load balancer / Cloud Run ortida barcha so'rovlar bir
  /// IP'dan kelgandek ko'rinadi — shuning uchun [trustProxy] yoqilgan bo'lsa,
  /// `X-Forwarded-For` dagi birinchi manzil olinadi. Faqat ishonchli proksi
  /// ortida yoqing (aks holda sarlavhani soxtalashtirish mumkin).
  String clientIp(Request req) {
    if (trustProxy) {
      final xff = req.headers['x-forwarded-for'];
      if (xff != null && xff.trim().isNotEmpty) {
        return xff.split(',').first.trim();
      }
    }
    return (req.context['shelf.io.connection_info'] as dynamic)
                ?.remoteAddress
                ?.address
            as String? ??
        'unknown';
  }

  void _limit(Request req, String bucket, int max, Duration window) =>
      _limitKey('$bucket:${clientIp(req)}', max, window);

  void _limitKey(String key, int max, Duration window) {
    final now = DateTime.now();
    final hits = (_rate[key] ??= [])
      ..removeWhere((t) => now.difference(t) > window);
    if (hits.length >= max) throw ApiException(429, 'rate_limited');
    hits.add(now);
  }

  Future<void> _requireConsents(
    User u, [
    List<ConsentScope> extra = const [],
  ]) async {
    if (!await consents.hasAllRequired(u.id)) {
      throw ApiException(
        451,
        'consent_required',
        'Majburiy rozilik berilmagan yoki eskirgan',
      );
    }
    for (final s in extra) {
      if (!await consents.has(u.id, s)) {
        throw ApiException(451, 'consent_required', s.name);
      }
    }
  }

  /// Admin paneli uchun umumiy ko'rsatkichlar (shaxsiy ma'lumotsiz).
  Map<String, dynamic> _stats() {
    final now = DateTime.now().toUtc();
    final monthAgo = now.subtract(const Duration(days: 30));
    final allDoctors = doctors.all.toList();
    final appts = appointments.all.toList();
    final paid = orders.all.where(
      (o) => o.status == OrderStatus.paid || o.status == OrderStatus.refunded,
    );
    final byStatus = <String, int>{
      for (final s in AppointmentStatus.values)
        s.name: appts.where((a) => a.status == s).length,
    };
    final tashkentToday = DateTime.utc(
      now.add(const Duration(hours: 5)).year,
      now.add(const Duration(hours: 5)).month,
      now.add(const Duration(hours: 5)).day,
    ).subtract(const Duration(hours: 5));
    return {
      'users': auth.userCount,
      'doctorsApproved': allDoctors
          .where((d) => d.status == ModerationStatus.approved)
          .length,
      'doctorsPending': allDoctors
          .where((d) => d.status == ModerationStatus.pending)
          .length,
      'appointmentsByStatus': byStatus,
      'appointmentsToday': appts
          .where(
            (a) =>
                a.status == AppointmentStatus.confirmed &&
                !a.startsAt.isBefore(tashkentToday) &&
                a.startsAt.isBefore(tashkentToday.add(const Duration(days: 1))),
          )
          .length,
      'onlineShare': appts.isEmpty
          ? 0
          : (appts.where((a) => a.isOnline).length / appts.length * 100)
                .round(),
      'revenue30dUzs': paid
          .where((o) => (o.paidAt ?? now).isAfter(monthAgo))
          .where((o) => o.status == OrderStatus.paid)
          .fold<int>(0, (s, o) => s + o.amountUzs),
      'refundsPending': orders.pendingRefunds().length,
      'refundsPendingUzs': orders.pendingRefunds().fold<int>(
        0,
        (s, o) => s + o.amountUzs,
      ),
    };
  }

  /// Bekor qilish va pul qaytarish qoidasi (bitta joyda). [role] — bekor
  /// qilgan tomon. Natija: `none`, `requested` (admin navbatida) yoki
  /// `refunded` (Google Pay / Apple Pay — darhol avtomatik).
  Future<String> _cancelWithRefund(Appointment a, User u, String role) async {
    final wasConfirmed = a.status == AppointmentStatus.confirmed;
    appointments.cancel(a.id, u.id, bySystem: role == 'admin');
    final paid = orders.paidOrderFor(a.id);
    final reason = refundReason(a, role, DateTime.now().toUtc());
    if (!wasConfirmed || paid == null || reason == null) return 'none';
    orders.requestRefund(paid, reason);
    if (isWallet(paid.provider) && await wallet.refund(paid)) {
      _refunded(paid);
      return 'refunded';
    }
    return 'requested';
  }

  void _refunded(PaymentOrder o) {
    orders.completeRefund(o);
    notifications.notify(
      o.userId,
      PushKind.refundCompleted,
      data: {'type': 'appointment', 'appointmentId': o.appointmentId},
    );
  }

  Map<String, dynamic> _doctorStats(DoctorProfile d) {
    final now = DateTime.now().toUtc();
    final monthAgo = now.subtract(const Duration(days: 30));
    final mine = appointments.forDoctor(d.id);
    final local = now.add(AppointmentService.tashkent);
    final todayStart = DateTime.utc(
      local.year,
      local.month,
      local.day,
    ).subtract(AppointmentService.tashkent);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final earned = orders.all.where(
      (o) =>
          o.status == OrderStatus.paid &&
          (o.paidAt ?? o.createdAt).isAfter(monthAgo) &&
          appointments.byId(o.appointmentId)?.doctorId == d.id,
    );
    return {
      'upcoming': mine
          .where(
            (a) =>
                a.status == AppointmentStatus.confirmed &&
                a.startsAt.isAfter(now),
          )
          .length,
      'today': mine
          .where(
            (a) =>
                a.status == AppointmentStatus.confirmed &&
                !a.startsAt.isBefore(todayStart) &&
                a.startsAt.isBefore(todayEnd),
          )
          .length,
      'completed30d': mine
          .where(
            (a) =>
                a.status == AppointmentStatus.completed &&
                a.startsAt.isAfter(monthAgo),
          )
          .length,
      'earnings30dUzs': earned.fold<int>(0, (s, o) => s + o.amountUzs),
      'awaitingConclusion': mine
          .where(
            (a) =>
                a.status == AppointmentStatus.confirmed &&
                a.startsAt.isBefore(now) &&
                a.conclusionEnc == null,
          )
          .length,
      'rating': d.rating,
      'reviewCount': d.reviewCount,
    };
  }

  Future<Map<String, dynamic>> _userView(User x) async => {
    'id': x.id,
    'role': x.role.name,
    'phone': await auth.maskedPhone(x),
    'createdAt': x.createdAt.toIso8601String(),
    'blocked': x.blocked,
    'blockReason': x.blockReason,
    'appointments': appointments.forPatient(x.id).length,
    'doctorId': doctors.byUser(x.id)?.id,
  };

  /// Shifokorga bemor ismi (tibbiy profildan; to'ldirilmagan bo'lsa null).
  /// To'lanmagan bron uchun ko'rsatilmaydi.
  Future<String?> _patientName(Appointment a) async {
    if (a.status == AppointmentStatus.awaitingPayment) return null;
    final name = (await profiles.get(a.patientId)).fullName;
    return name.isEmpty ? null : name;
  }

  Future<void> _audit(User u, String action, String resource, [String? id]) =>
      audit.record(
        AuditEvent(
          actorId: u.id,
          action: action,
          resource: resource,
          resourceId: id,
        ),
      );

  Handler get handler {
    final r = Router()
      ..get('/health', (Request _) => jsonOk({'ok': true}))
      // Ommaviy hujjatlar (do'kon sahifasi va ilova shu havolani ochadi).
      ..get('/legal/privacy', legal.privacy)
      ..get('/legal/terms', legal.terms)
      // ---------------- Auth ----------------
      ..post('/v1/auth/otp/request', (Request req) async {
        _limit(req, 'otp', 20, const Duration(minutes: 10));
        final j = await readJson(req);
        // Bitta raqamga SMS "bombardimon"idan himoya — IP'dan qat'i nazar.
        _limitKey('otp-phone:${j['phone']}', 5, const Duration(minutes: 10));
        await auth.requestOtp('${j['phone']}');
        return jsonOk({'sent': true});
      })
      ..post('/v1/auth/otp/verify', (Request req) async {
        _limit(req, 'otp-verify', 10, const Duration(minutes: 10));
        final j = await readJson(req);
        final res = await auth.verifyOtp('${j['phone']}', '${j['code']}');
        return jsonOk({
          'token': res.token,
          'user': {'id': res.user.id, 'role': res.user.role.name},
          'missingConsents': (await consents.missing(res.user.id))
              .map((s) => s.name)
              .toList(),
        });
      })
      ..post('/v1/auth/refresh', (Request req) {
        final u = requireUser(req);
        return jsonOk({'token': auth.issueToken(u)});
      })
      ..get('/v1/me', (Request req) async {
        final u = requireUser(req);
        return jsonOk({
          'id': u.id,
          'role': u.role.name,
          'missingConsents': (await consents.missing(u.id))
              .map((s) => s.name)
              .toList(),
        });
      })
      // ---------------- Bildirishnomalar tarixi ----------------
      ..get('/v1/me/notifications', (Request req) {
        final u = requireUser(req);
        final lang = req.url.queryParameters['lang'] ?? 'uz';
        return jsonOk({
          'unread': notifications.inbox.unread(u.id),
          'items': [
            for (final i in notifications.inbox.list(u.id)) i.toJson(lang),
          ],
        });
      })
      ..post('/v1/me/notifications/read', (Request req) async {
        final u = requireUser(req);
        final j = await readJson(req);
        final ids = (j['ids'] as List?)?.whereType<String>().toSet();
        final n = notifications.inbox.markRead(u.id, ids);
        return jsonOk({
          'marked': n,
          'unread': notifications.inbox.unread(u.id),
        });
      })
      // ---------------- Push qurilmalari ----------------
      ..post('/v1/me/devices', (Request req) async {
        final u = requireUser(req);
        final j = await readJson(req);
        devices.register(
          userId: u.id,
          token: '${j['token'] ?? ''}',
          platform: '${j['platform'] ?? ''}',
          locale: '${j['locale'] ?? 'uz'}',
        );
        return jsonOk({'registered': true});
      })
      ..post('/v1/me/devices/remove', (Request req) async {
        // Token URL'da emas, tanada yuboriladi (loglarga tushmasligi uchun).
        final u = requireUser(req);
        devices.unregister(u.id, '${(await readJson(req))['token'] ?? ''}');
        return jsonOk({'removed': true});
      })
      // ---------------- Tibbiy profil ----------------
      ..get('/v1/me/profile', (Request req) async {
        final u = requireUser(req);
        await _requireConsents(u);
        await _audit(u, 'profile.read', 'profile', u.id);
        return jsonOk((await profiles.get(u.id)).toJson());
      })
      ..put('/v1/me/profile', (Request req) async {
        final u = requireUser(req);
        await _requireConsents(u);
        final p = await profiles.put(u.id, await readJson(req));
        await _audit(u, 'profile.update', 'profile', u.id);
        return jsonOk(p.toJson());
      })
      // ---------------- Rozilik ----------------
      ..get('/v1/consents', (Request req) async {
        final u = requireUser(req);
        final cur = await consents.current(u.id);
        return jsonOk({
          'documents': [
            for (final s in ConsentScope.values)
              {
                'scope': s.name,
                'required': s.required,
                'version': currentConsentVersions[s],
                'granted': await consents.has(u.id, s),
                'decidedAt': cur[s]?.at.toIso8601String(),
              },
          ],
        });
      })
      ..post('/v1/consents', (Request req) async {
        final u = requireUser(req);
        final j = await readJson(req);
        // Rozilik dalili sifatida mijozning haqiqiy IP'si saqlanadi.
        final ip = clientIp(req);
        for (final d in (j['decisions'] as List).cast<Map<String, dynamic>>()) {
          final scope = ConsentScope.parse(d['scope'] as String);
          try {
            await consents.record(
              ConsentRecord(
                userId: u.id,
                scope: scope,
                version: d['version'] as String,
                granted: d['granted'] as bool,
                at: DateTime.now().toUtc(),
                ip: ip,
                userAgent: req.headers['user-agent'],
              ),
            );
          } on StateError catch (e) {
            throw ApiException(409, 'consent_version_mismatch', e.message);
          }
          // AI roziligi qaytarib olinsa — AI tahlillari ham o'chiriladi.
          if (scope == ConsentScope.aiProcessing && d['granted'] == false) {
            triage.deleteAll(u.id);
          }
        }
        await _audit(u, 'consent.update', 'consent');
        return jsonOk({
          'missingConsents': (await consents.missing(u.id))
              .map((s) => s.name)
              .toList(),
        });
      })
      // ---------------- AI triaj ----------------
      ..post('/v1/triage', (Request req) async {
        final u = requireUser(req, {Role.patient, Role.doctor, Role.admin});
        await _requireConsents(u, [
          ConsentScope.aiProcessing,
          ConsentScope.crossBorderTransfer,
        ]);
        _limit(req, 'triage:${u.id}', 20, const Duration(hours: 1));
        final input = TriageInput.fromJson(await readJson(req));
        final result = await triage.analyze(u.id, input);
        await _audit(u, 'triage.create', 'triage', result.id);
        return jsonOk(result.toJson());
      })
      ..get('/v1/triage/history', (Request req) async {
        final u = requireUser(req);
        await _requireConsents(u);
        await _audit(u, 'triage.read', 'triage');
        return jsonOk({'items': await triage.history(u.id)});
      })
      // ---------------- Shifokorlar ----------------
      ..get(
        '/v1/specialties',
        (Request _) => jsonOk({
          'items': [
            for (final e in specialties.entries)
              {'code': e.key, 'name': e.value},
          ],
        }),
      )
      ..get('/v1/doctors', (Request req) {
        final q = req.url.queryParameters;
        return jsonOk({
          'items': doctors
              .search(specialty: q['specialty'], city: q['city'], q: q['q'])
              .map((d) => d.toPublicJson())
              .toList(),
        });
      })
      ..get('/v1/doctors/me', (Request req) async {
        final u = requireUser(req);
        final d = doctors.byUser(u.id);
        if (d == null) throw ApiException(404, 'not_found');
        return jsonOk({
          ...d.toPublicJson(),
          'status': d.status.name,
          'moderationNote': d.moderationNote,
        });
      })
      ..post('/v1/doctors/apply', (Request req) async {
        final u = requireUser(req);
        await _requireConsents(u);
        final d = await doctors.apply(u.id, await readJson(req));
        await _audit(u, 'doctor.apply', 'doctor', d.id);
        return jsonOk({'id': d.id, 'status': d.status.name}, status: 201);
      })
      ..get('/v1/doctors/<id>', (Request req, String id) {
        final d = doctors.byId(id);
        if (d == null || d.status != ModerationStatus.approved) {
          throw ApiException(404, 'not_found');
        }
        return jsonOk(d.toPublicJson());
      })
      ..get(
        '/v1/doctors/<id>/reviews',
        (Request req, String id) => jsonOk({
          'items': [for (final r in appointments.reviewsFor(id)) r.toJson()],
        }),
      )
      ..get('/v1/doctors/<id>/slots', (Request req, String id) {
        final date = DateTime.parse(
          req.url.queryParameters['date'] ?? (throw const FormatException()),
        );
        return jsonOk({
          'items': appointments
              .freeSlots(id, date)
              .map((t) => t.toIso8601String())
              .toList(),
        });
      })
      ..get('/v1/doctor/appointments', (Request req) async {
        final u = requireUser(req, {Role.doctor});
        final d =
            doctors.byUser(u.id) ?? (throw ApiException(404, 'not_found'));
        await _audit(u, 'appointment.list', 'appointment');
        return jsonOk({
          'items': [
            for (final a in appointments.forDoctor(d.id))
              if (a.status != AppointmentStatus.awaitingPayment)
                {
                  ...await appointments.toJson(a),
                  'patientName': await _patientName(a),
                  'videoAvailable': video.configured && a.isOnline,
                },
          ],
        });
      })
      ..post('/v1/doctor/appointments/<id>/complete', (
        Request req,
        String id,
      ) async {
        final u = requireUser(req, {Role.doctor});
        appointments.complete(id, u.id);
        await _audit(u, 'appointment.complete', 'appointment', id);
        return jsonOk({'id': id, 'status': 'completed'});
      })
      // ---------------- Moderatsiya (admin) ----------------
      ..get('/v1/admin/doctors/pending', (Request req) async {
        final u = requireUser(req, {Role.admin});
        await _audit(u, 'doctor.moderation.list', 'doctor');
        return jsonOk({
          'items': [
            for (final d in doctors.pending()) await doctors.moderationView(d),
          ],
        });
      })
      ..post('/v1/admin/doctors/<id>/moderate', (Request req, String id) async {
        final u = requireUser(req, {Role.admin});
        final j = await readJson(req);
        final decision = ModerationStatus.values.firstWhere(
          (s) => s.name == j['decision'],
          orElse: () => throw ApiException(400, 'invalid_decision'),
        );
        final d = doctors.moderate(id, u.id, decision, j['note'] as String?);
        final owner = auth.userById(d.userId);
        if (owner != null && owner.role != Role.admin) {
          owner.role = d.status == ModerationStatus.approved
              ? Role.doctor
              : Role.patient;
          auth.saveUser(owner);
        }
        var refunds = 0;
        if (decision == ModerationStatus.suspended) {
          // Kelgusi qabullar bekor qilinadi, bemorlarga pul to'liq qaytadi.
          for (final a in appointments.activeFor(doctorId: d.id)) {
            if (await _cancelWithRefund(a, u, 'admin') != 'none') refunds++;
          }
          notifications.notify(
            d.userId,
            PushKind.doctorSuspended,
            data: {'type': 'doctor_application'},
          );
        }
        if (decision == ModerationStatus.approved ||
            decision == ModerationStatus.rejected) {
          notifications.notify(
            d.userId,
            decision == ModerationStatus.approved
                ? PushKind.doctorApproved
                : PushKind.doctorRejected,
            data: {'type': 'doctor_application'},
          );
        }
        await _audit(u, 'doctor.moderate.${decision.name}', 'doctor', id);
        return jsonOk({
          'id': d.id,
          'status': d.status.name,
          'refunds': refunds,
        });
      })
      ..get('/v1/admin/refunds', (Request req) async {
        final u = requireUser(req, {Role.admin});
        await _audit(u, 'refund.list', 'order');
        return jsonOk({
          'items': [
            for (final o in orders.pendingRefunds())
              {
                ...o.toJson(),
                'providerTxnId': o.providerTxnId,
                'reason': o.refundReason,
                'requestedAt': o.refundRequestedAt!.toIso8601String(),
                'appointmentStartsAt': appointments
                    .byId(o.appointmentId)
                    ?.startsAt
                    .toIso8601String(),
              },
          ],
        });
      })
      ..post('/v1/admin/refunds/<id>/complete', (Request req, String id) async {
        final u = requireUser(req, {Role.admin});
        final o = orders.byId(id);
        if (o == null || o.refundStatus != RefundStatus.requested) {
          throw ApiException(404, 'not_found');
        }
        // Google Pay / Apple Pay: avtomatik urinish muvaffaqiyatsiz bo'lgan
        // bo'lsa — admin qayta urinadi (Stripe orqali). Click/Payme — kabinetda
        // qaytarilgach belgilanadi.
        if (isWallet(o.provider) && !await wallet.refund(o)) {
          throw ApiException(502, 'refund_failed');
        }
        _refunded(o);
        await _audit(u, 'refund.complete', 'order', id);
        return jsonOk(o.toJson());
      })
      ..get('/v1/admin/doctors', (Request req) async {
        final u = requireUser(req, {Role.admin});
        final q = req.url.queryParameters;
        final status = q['status'];
        final text = (q['q'] ?? '').trim().toLowerCase();
        final list =
            doctors.all
                .where((d) => status == null || d.status.name == status)
                .where(
                  (d) =>
                      text.isEmpty ||
                      d.fullName.toLowerCase().contains(text) ||
                      d.clinic.toLowerCase().contains(text),
                )
                .toList()
              ..sort((a, b) => a.fullName.compareTo(b.fullName));
        await _audit(u, 'doctor.admin.list', 'doctor');
        return jsonOk({
          'total': list.length,
          'items': [
            for (final d in list.take(200))
              {
                ...d.toPublicJson(),
                'status': d.status.name,
                'moderationNote': d.moderationNote,
                'upcoming': appointments.activeFor(doctorId: d.id).length,
              },
          ],
        });
      })
      ..get('/v1/admin/doctors/<id>', (Request req, String id) async {
        final u = requireUser(req, {Role.admin});
        final d = doctors.byId(id) ?? (throw ApiException(404, 'not_found'));
        await _audit(u, 'doctor.admin.read', 'doctor', id);
        return jsonOk({
          ...await doctors.moderationView(d),
          'moderationNote': d.moderationNote,
          'moderatedAt': d.moderatedAt?.toIso8601String(),
          'stats': _doctorStats(d),
          'reviews': [
            for (final a in appointments.reviewedFor(d.id))
              {
                'appointmentId': a.id,
                ...a.review!.toJson(),
                'hidden': a.review!.hidden,
                'hiddenReason': a.review!.hiddenReason,
              },
          ],
        });
      })
      ..post('/v1/admin/reviews/<id>/hide', (Request req, String id) async {
        final u = requireUser(req, {Role.admin});
        final j = await readJson(req);
        final hidden = j['hidden'] as bool? ?? true;
        final reason = (j['reason'] as String? ?? '').trim();
        if (hidden && reason.isEmpty) {
          throw ApiException(400, 'note_required');
        }
        final a = appointments.setReviewHidden(
          id,
          hidden: hidden,
          reason: reason,
        );
        await _audit(u, hidden ? 'review.hide' : 'review.unhide', 'review', id);
        return jsonOk({
          'appointmentId': a.id,
          'hidden': a.review!.hidden,
          'doctorRating': doctors.byId(a.doctorId)!.rating,
        });
      })
      ..get('/v1/admin/users', (Request req) async {
        final u = requireUser(req, {Role.admin});
        final q = req.url.queryParameters;
        final text = (q['q'] ?? '').replaceAll(' ', '');
        final role = q['role'];
        final blocked = q['blocked'] == 'true';
        Iterable<User> list;
        if (text.startsWith('+')) {
          final found = auth.byPhone(text);
          list = found == null ? const [] : [found];
        } else {
          list = auth.users.where((x) => text.isEmpty || x.id.startsWith(text));
        }
        final filtered =
            list
                .where((x) => role == null || x.role.name == role)
                .where((x) => !blocked || x.blocked)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _audit(u, 'user.admin.list', 'user');
        return jsonOk({
          'total': filtered.length,
          'items': [for (final x in filtered.take(100)) await _userView(x)],
        });
      })
      ..post('/v1/admin/users/<id>/block', (Request req, String id) async {
        final u = requireUser(req, {Role.admin});
        final target =
            auth.userById(id) ?? (throw ApiException(404, 'not_found'));
        final j = await readJson(req);
        final block = j['blocked'] as bool? ?? true;
        final reason = (j['reason'] as String? ?? '').trim();
        if (target.id == u.id || target.role == Role.admin) {
          throw ApiException(409, 'cannot_block_admin');
        }
        if (block && reason.isEmpty) throw ApiException(400, 'note_required');
        var refunds = 0;
        if (block && !target.blocked) {
          // Kelgusi qabullar bekor qilinadi (pul to'liq qaytadi), shifokor
          // profili to'xtatiladi, push qurilmalari o'chiriladi.
          for (final a in appointments.activeFor(patientId: target.id)) {
            if (await _cancelWithRefund(a, u, 'admin') != 'none') refunds++;
          }
          final d = doctors.byUser(target.id);
          if (d != null && d.status == ModerationStatus.approved) {
            for (final a in appointments.activeFor(doctorId: d.id)) {
              if (await _cancelWithRefund(a, u, 'admin') != 'none') refunds++;
            }
            doctors.moderate(d.id, u.id, ModerationStatus.suspended, reason);
            target.role = Role.patient;
          }
          await notifications.notify(target.id, PushKind.accountBlocked);
          devices.removeUser(target.id);
        }
        auth.setBlocked(target, blocked: block, reason: reason);
        await _audit(u, block ? 'user.block' : 'user.unblock', 'user', id);
        return jsonOk({...await _userView(target), 'refunds': refunds});
      })
      ..get('/v1/admin/appointments', (Request req) async {
        final u = requireUser(req, {Role.admin});
        final q = req.url.queryParameters;
        final status = q['status'];
        final doctorId = q['doctorId'];
        final list =
            appointments.all
                .where((a) => status == null || a.status.name == status)
                .where((a) => doctorId == null || a.doctorId == doctorId)
                .toList()
              ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
        await _audit(u, 'appointment.admin.list', 'appointment');
        // Shikoyat sababi va xulosa (tibbiy mazmun) adminga ko'rsatilmaydi.
        return jsonOk({
          'total': list.length,
          'items': [
            for (final a in list.take(200))
              {
                'id': a.id,
                'startsAt': a.startsAt.toIso8601String(),
                'status': a.status.name,
                'type': a.type,
                'priceUzs': a.priceUzs,
                'patientId': a.patientId,
                'doctor': switch (doctors.byId(a.doctorId)) {
                  final d? => {
                    'id': d.id,
                    'fullName': d.fullName,
                    'specialty': d.specialty,
                  },
                  null => null,
                },
                'paid': orders.paidOrderFor(a.id) != null,
                'refundStatus': orders.refundFor(a.id).name,
                'hasConclusion': a.conclusionEnc != null,
                'rescheduleCount': a.rescheduleCount,
              },
          ],
        });
      })
      ..get('/v1/admin/payments', (Request req) async {
        final u = requireUser(req, {Role.admin});
        final q = req.url.queryParameters;
        final list =
            orders.all
                .where(
                  (o) => q['status'] == null || o.status.name == q['status'],
                )
                .where(
                  (o) =>
                      q['provider'] == null || o.provider.name == q['provider'],
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _audit(u, 'payment.admin.list', 'order');
        return jsonOk({
          'total': list.length,
          'sumPaidUzs': list
              .where((o) => o.status == OrderStatus.paid)
              .fold<int>(0, (s, o) => s + o.amountUzs),
          'items': [
            for (final o in list.take(200))
              {
                ...o.toJson(),
                'createdAt': o.createdAt.toIso8601String(),
                'paidAt': o.paidAt?.toIso8601String(),
                'providerTxnId': o.providerTxnId,
                'refundReason': o.refundReason,
              },
          ],
        });
      })
      ..get('/v1/admin/audit', (Request req) async {
        final u = requireUser(req, {Role.admin});
        final q = req.url.queryParameters;
        final limit = (int.tryParse(q['limit'] ?? '') ?? 100).clamp(1, 500);
        final events = await audit.recent(
          actorId: q['actorId'],
          actionPrefix: q['action'],
          limit: limit,
        );
        await _audit(u, 'audit.read', 'audit');
        return jsonOk({
          'items': [for (final e in events) e.toJson()],
        });
      })
      ..get('/v1/admin/stats', (Request req) async {
        final u = requireUser(req, {Role.admin});
        await _audit(u, 'stats.read', 'admin');
        return jsonOk(_stats());
      })
      // ---------------- Qabullar ----------------
      ..post('/v1/appointments', (Request req) async {
        final u = requireUser(req);
        await _requireConsents(u);
        final j = await readJson(req);
        final a = await appointments.book(
          patientId: u.id,
          doctorId: j['doctorId'] as String,
          startsAt: DateTime.parse(j['startsAt'] as String),
          reason: (j['reason'] as String? ?? '').trim(),
          triageId: j['triageId'] as String?,
          type: j['type'] as String? ?? 'clinic',
        );
        await _audit(u, 'appointment.create', 'appointment', a.id);
        return jsonOk(await appointments.toJson(a), status: 201);
      })
      ..get('/v1/appointments', (Request req) async {
        final u = requireUser(req);
        await _requireConsents(u);
        await _audit(u, 'appointment.list', 'appointment');
        return jsonOk({
          'items': [
            for (final a in appointments.forPatient(u.id))
              {
                ...await appointments.toJson(a),
                'videoAvailable': video.configured && a.isOnline,
              },
          ],
        });
      })
      // ---------------- Onlayn konsultatsiya ----------------
      ..get('/v1/appointments/<id>', (Request req, String id) async {
        final u = requireUser(req);
        final a = appointments.requireParticipant(id, u.id);
        await _audit(u, 'appointment.read', 'appointment', id);
        final role = appointments.participantRole(a, u.id);
        return jsonOk({
          ...await appointments.toJson(a),
          'myRole': role,
          'refundStatus': orders.refundFor(a.id).name,
          'videoAvailable': video.configured && a.isOnline,
          if (role == 'doctor') 'patientName': await _patientName(a),
        });
      })
      ..get('/v1/appointments/<id>/messages', (Request req, String id) async {
        final u = requireUser(req);
        final after = int.tryParse(req.url.queryParameters['after'] ?? '') ?? 0;
        final res = await chat.list(id, u.id, after: after);
        if (after == 0) await _audit(u, 'chat.read', 'appointment', id);
        return jsonOk(res);
      })
      ..post('/v1/appointments/<id>/messages', (Request req, String id) async {
        final u = requireUser(req);
        _limit(req, 'chat:${u.id}', 30, const Duration(minutes: 1));
        final m = await chat.send(
          id,
          u.id,
          '${(await readJson(req))['text'] ?? ''}',
        );
        await _audit(u, 'chat.send', 'appointment', id);
        return jsonOk(await chat.toJson(m, u.id), status: 201);
      })
      ..post('/v1/appointments/<id>/attachments', (
        Request req,
        String id,
      ) async {
        final u = requireUser(req);
        _limit(req, 'upload:${u.id}', 20, const Duration(minutes: 10));
        // Hajm chegarasi: butun faylni o'qishdan oldin to'xtatamiz.
        final declared = int.tryParse(req.headers['content-length'] ?? '');
        if (declared != null && declared > AttachmentService.maxBytes) {
          throw ApiException(413, 'file_too_large');
        }
        final builder = BytesBuilder(copy: false);
        await for (final chunk in req.read()) {
          builder.add(chunk);
          if (builder.length > AttachmentService.maxBytes) {
            throw ApiException(413, 'file_too_large');
          }
        }
        final name = req.headers['x-file-name'];
        final m = await attachments.upload(
          id,
          u.id,
          builder.takeBytes(),
          fileName: name == null ? null : Uri.decodeComponent(name),
        );
        await _audit(u, 'attachment.upload', 'appointment', id);
        return jsonOk(await chat.toJson(m, u.id), status: 201);
      })
      ..get('/v1/appointments/<id>/attachments/<att>', (
        Request req,
        String id,
        String att,
      ) async {
        final u = requireUser(req);
        final (meta, bytes) = await attachments.download(id, att, u.id);
        await _audit(u, 'attachment.read', 'attachment', att);
        return Response.ok(
          bytes,
          headers: {
            'content-type': meta.mime,
            'content-length': '${bytes.length}',
            'content-disposition': 'inline',
          },
        );
      })
      // Real vaqtdagi chat: server yangi xabarlarni darhol yuboradi (xabar
      // yuborish — oddiy POST orqali, bazaga yozilishi kafolatlangan).
      // Token sarlavhada (URL'da emas — loglarga tushmasligi uchun).
      // Ulanish [liveMaxAge] dan keyin yopiladi: mijoz yangi token bilan
      // qayta ulanadi, shu bilan muddati o'tgan token ishlashda qolmaydi.
      ..get('/v1/appointments/<id>/live', (Request req, String id) {
        final u = requireUser(req);
        appointments.requireParticipant(id, u.id);
        return webSocketHandler((WebSocketChannel ws, String? _) {
          final sub = chat.live(id).listen((m) async {
            ws.sink.add(
              jsonEncode({
                'type': 'message',
                'message': await chat.toJson(m, u.id),
              }),
            );
          });
          final timer = Timer(liveMaxAge, () => ws.sink.close(4001, 'reauth'));
          ws.sink.add(jsonEncode({'type': 'ready'}));
          ws.stream.listen(
            (_) {}, // mijozdan faqat ping keladi
            onDone: () {
              sub.cancel();
              timer.cancel();
            },
            onError: (Object _) {
              sub.cancel();
              timer.cancel();
            },
            cancelOnError: true,
          );
        }, pingInterval: const Duration(seconds: 25))(req);
      })
      ..post('/v1/appointments/<id>/video', (Request req, String id) async {
        final u = requireUser(req);
        final a = appointments.requireParticipant(id, u.id);
        final role = appointments.participantRole(a, u.id)!;
        final t = video.issue(a, userId: u.id, role: role);
        if (role == 'doctor' && !a.doctorJoinedVideo) {
          a.doctorJoinedVideo = true;
          appointments.persist(a);
          notifications.notify(
            a.patientId,
            PushKind.consultationStarted,
            data: {'type': 'video', 'appointmentId': a.id},
          );
        }
        await _audit(u, 'video.join', 'appointment', id);
        return jsonOk({
          'url': t.url,
          'token': t.token,
          'room': t.room,
          'expiresAt': t.expiresAt.toIso8601String(),
        });
      })
      ..get('/v1/doctor/appointments/<id>/patient', (
        Request req,
        String id,
      ) async {
        // Shifokor qabul oldidan bemorning tibbiy profili va AI tahlilini
        // ko'radi (bemor "sog'liq ma'lumotlari" roziligida shu ko'zda tutilgan).
        final u = requireUser(req, {Role.doctor});
        final a = appointments.requireParticipant(id, u.id);
        if (appointments.participantRole(a, u.id) != 'doctor' ||
            a.status == AppointmentStatus.cancelled ||
            a.status == AppointmentStatus.awaitingPayment) {
          throw ApiException(403, 'forbidden');
        }
        await _audit(u, 'patient.read', 'appointment', id);
        return jsonOk({
          'profile': (await profiles.get(a.patientId)).toJson(),
          'triage': a.triageId == null
              ? null
              : await triage.byId(a.patientId, a.triageId!),
        });
      })
      ..put('/v1/doctor/appointments/<id>/conclusion', (
        Request req,
        String id,
      ) async {
        final u = requireUser(req, {Role.doctor});
        await appointments.setConclusion(id, u.id, await readJson(req));
        await _audit(u, 'conclusion.write', 'appointment', id);
        return jsonOk(await appointments.toJson(appointments.byId(id)!));
      })
      ..get('/v1/doctor/stats', (Request req) async {
        final u = requireUser(req, {Role.doctor});
        final d =
            doctors.byUser(u.id) ?? (throw ApiException(404, 'not_found'));
        return jsonOk(_doctorStats(d));
      })
      ..get('/v1/doctor/settings', (Request req) {
        final u = requireUser(req, {Role.doctor});
        final d =
            doctors.byUser(u.id) ?? (throw ApiException(404, 'not_found'));
        return jsonOk(d.settingsJson());
      })
      ..put('/v1/doctor/settings', (Request req) async {
        final u = requireUser(req, {Role.doctor});
        final d =
            doctors.byUser(u.id) ?? (throw ApiException(404, 'not_found'));
        doctors.updateSettings(d, await readJson(req));
        await _audit(u, 'doctor.settings', 'doctor', d.id);
        return jsonOk(d.settingsJson());
      })
      ..post('/v1/appointments/<id>/review', (Request req, String id) async {
        final u = requireUser(req);
        final j = await readJson(req);
        final name = (await profiles.get(u.id)).fullName.split(' ');
        appointments.addReview(
          id,
          u.id,
          rating: j['rating'] as int,
          comment: j['comment'] as String? ?? '',
          // Familiya emas, faqat ism ko'rsatiladi.
          authorName: name.length > 1 ? name[1] : 'Bemor',
        );
        await _audit(u, 'appointment.review', 'appointment', id);
        return jsonOk({'ok': true});
      })
      ..post('/v1/appointments/<id>/cancel', (Request req, String id) async {
        final u = requireUser(req);
        final a = appointments.requireParticipant(id, u.id);
        final role = appointments.participantRole(a, u.id)!;
        final refund = await _cancelWithRefund(a, u, role);
        await _audit(u, 'appointment.cancel', 'appointment', id);
        return jsonOk({'id': id, 'status': 'cancelled', 'refund': refund});
      })
      ..post('/v1/appointments/<id>/reschedule', (
        Request req,
        String id,
      ) async {
        final u = requireUser(req);
        final j = await readJson(req);
        final raw = j['startsAt'];
        final t = raw is String ? DateTime.tryParse(raw) : null;
        if (t == null) throw ApiException(400, 'invalid_time');
        final a = appointments.reschedule(id, u.id, t);
        await _audit(u, 'appointment.reschedule', 'appointment', id);
        return jsonOk({
          ...await appointments.toJson(a),
          'myRole': 'patient',
          'refundStatus': orders.refundFor(a.id).name,
        });
      })
      // ---------------- To'lovlar ----------------
      ..post('/v1/payments/checkout', (Request req) async {
        final u = requireUser(req);
        final j = await readJson(req);
        final a = _ownedUnpaid(u, j['appointmentId'] as String?);
        final provider = PaymentProvider.values.firstWhere(
          (p) => p.name == j['provider'],
          orElse: () => throw ApiException(400, 'invalid_provider'),
        );
        if (provider != PaymentProvider.click &&
            provider != PaymentProvider.payme) {
          throw ApiException(400, 'use_wallet_endpoint');
        }
        final o = orders.create(
          appointmentId: a.id,
          userId: u.id,
          amountUzs: a.priceUzs,
          provider: provider,
        );
        final ret = 'medlink://payment-result?order=${o.id}';
        final url = provider == PaymentProvider.click
            ? click.checkoutUrl(o, ret)
            : payme.checkoutUrl(o, ret);
        await _audit(u, 'payment.checkout', 'order', o.id);
        return jsonOk({...o.toJson(), 'checkoutUrl': url.toString()});
      })
      ..post('/v1/payments/wallet', (Request req) async {
        final u = requireUser(req);
        final j = await readJson(req);
        final a = _ownedUnpaid(u, j['appointmentId'] as String?);
        final provider = j['provider'] == 'applePay'
            ? PaymentProvider.applePay
            : PaymentProvider.googlePay;
        final o = orders.create(
          appointmentId: a.id,
          userId: u.id,
          amountUzs: a.priceUzs,
          provider: provider,
        );
        final txn = await wallet.charge(o, j['token'] as String);
        final ok = txn != null;
        if (ok) {
          o
            ..status = OrderStatus.paid
            ..providerTxnId = txn
            ..paidAt = DateTime.now().toUtc();
          appointments.markPaid(a.id);
        } else {
          o.status = OrderStatus.cancelled;
        }
        orders.persist(o);
        await _audit(u, 'payment.wallet', 'order', o.id);
        return jsonOk(o.toJson(), status: ok ? 200 : 402);
      })
      ..get('/v1/payments/<id>', (Request req, String id) {
        final u = requireUser(req);
        final o = orders.byId(id);
        if (o == null || o.userId != u.id) throw ApiException(404, 'not_found');
        return jsonOk(o.toJson());
      })
      // Provayder webhook'lari (JWT emas — imzo/Basic auth bilan himoyalangan).
      ..post(
        '/payments/click/prepare',
        (Request req) async => jsonOk(
          click.prepare(Uri.splitQueryString(await req.readAsString())),
        ),
      )
      ..post(
        '/payments/click/complete',
        (Request req) async => jsonOk(
          click.complete(Uri.splitQueryString(await req.readAsString())),
        ),
      )
      ..post(
        '/payments/payme',
        (Request req) async => jsonOk(
          payme.handle(req.headers['authorization'], await req.readAsString()),
        ),
      )
      // ---------------- Sub'ekt huquqlari ----------------
      ..get('/v1/me/export', (Request req) async {
        final u = requireUser(req);
        await _audit(u, 'me.export', 'user', u.id);
        return jsonOk({
          'user': {'id': u.id, 'role': u.role.name},
          'medicalProfile': (await profiles.get(u.id)).toJson(),
          'consents': [
            for (final c in await consents.history(u.id)) c.toJson(),
          ],
          'triage': await triage.history(u.id),
          'appointments': [
            for (final a in appointments.forPatient(u.id))
              await appointments.toJson(a),
          ],
          'messages': await chat.exportFor(
            u.id,
            appointments.forPatient(u.id).map((a) => a.id),
          ),
          'auditTrail': [
            for (final e in await audit.forActor(u.id)) e.toJson(),
          ],
        });
      })
      // Hisobni to'liq o'chirish (App Store 5.1.1(v), Google Play talabi,
      // O'RQ-547 "unutilish huquqi"). Qonun bo'yicha saqlanishi shart bo'lgan
      // yozuvlar (to'lovlar, shifokor xulosalari, audit) qoladi, lekin
      // shaxsni aniqlovchi ma'lumotlar o'chiriladi.
      ..delete('/v1/me', (Request req) async {
        final u = requireUser(req);
        var refunds = 0;
        // Kelgusi qabullar bekor qilinadi (pul qaytarish qoidasi bo'yicha).
        for (final a in appointments.activeFor(patientId: u.id)) {
          if (await _cancelWithRefund(a, u, 'patient') != 'none') refunds++;
        }
        final doctor = doctors.byUser(u.id);
        if (doctor != null) {
          for (final a in appointments.activeFor(doctorId: doctor.id)) {
            if (await _cancelWithRefund(a, u, 'doctor') != 'none') refunds++;
          }
          doctors.deactivate(doctor);
        }
        triage.deleteAll(u.id);
        profiles.delete(u.id);
        appointments.anonymizeReviews(u.id);
        devices.removeUser(u.id);
        notifications.inbox.deleteUser(u.id);
        await consents.revokeAll(u.id);
        await _audit(u, 'me.delete_account', 'user', u.id);
        auth.deleteUser(u);
        return jsonOk({'deleted': true, 'refunds': refunds});
      })
      ..delete('/v1/me/health-data', (Request req) async {
        final u = requireUser(req);
        triage.deleteAll(u.id);
        profiles.delete(u.id);
        await _audit(u, 'me.delete_health_data', 'user', u.id);
        return jsonOk({'deleted': true});
      });

    return const Pipeline()
        .addMiddleware(securityHeaders())
        .addMiddleware(
          errorMiddleware((e, st) {
            // Faqat xato turi log qilinadi — so'rov tanasi (PHI) emas.
            // ignore: avoid_print
            print(
              jsonEncode({
                'severity': 'ERROR',
                'error': e.runtimeType.toString(),
              }),
            );
          }),
        )
        .addMiddleware(auth.middleware())
        .addHandler(r.call);
  }

  Appointment _ownedUnpaid(User u, String? appointmentId) {
    final a = appointmentId == null ? null : appointments.byId(appointmentId);
    if (a == null || a.patientId != u.id) throw ApiException(404, 'not_found');
    if (a.status != AppointmentStatus.awaitingPayment) {
      throw ApiException(409, 'not_payable');
    }
    return a;
  }

  /// To'lov provayderi muvaffaqiyatni tasdiqlaganda chaqiriladi.
  void onOrderPaid(PaymentOrder o) => appointments.markPaid(o.appointmentId);
}
