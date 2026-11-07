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
    required this.publicBaseUrl,
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
  final String publicBaseUrl;

  final _rate = <String, List<DateTime>>{};

  /// Oddiy sliding-window limitlovchi (OTP brute-force'ga qarshi).
  void _limit(Request req, String bucket, int max, Duration window) {
    final ip =
        (req.context['shelf.io.connection_info'] as dynamic)
                ?.remoteAddress
                ?.address
            as String? ??
        'unknown';
    final key = '$bucket:$ip';
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
        _limit(req, 'otp', 5, const Duration(minutes: 10));
        final j = await readJson(req);
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
        final ip =
            (req.context['shelf.io.connection_info'] as dynamic)
                    ?.remoteAddress
                    ?.address
                as String?;
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
                await appointments.toJson(a),
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
              await appointments.toJson(a),
          ],
        });
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
