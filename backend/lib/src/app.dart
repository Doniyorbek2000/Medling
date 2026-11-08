import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ai/triage_service.dart';
import 'appointments/appointments.dart';
import 'audit/audit_log.dart';
import 'auth/auth.dart';
import 'consent/consent.dart';
import 'core/http_utils.dart';
import 'doctors/doctors.dart';
import 'doctors/specialties.dart';
import 'payments/click.dart';
import 'payments/orders.dart';
import 'payments/payme.dart';
import 'payments/wallet.dart';
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
    required this.publicBaseUrl,
    this.trustProxy = false,
  });

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
  final String publicBaseUrl;
  final bool trustProxy;

  final _rate = <String, List<DateTime>>{};

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
        return jsonOk({'id': d.id, 'status': d.status.name});
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
        appointments.cancel(id, u.id);
        await _audit(u, 'appointment.cancel', 'appointment', id);
        return jsonOk({'id': id, 'status': 'cancelled'});
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
        final ok = await wallet.charge(o, j['token'] as String);
        if (ok) {
          o
            ..status = OrderStatus.paid
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
