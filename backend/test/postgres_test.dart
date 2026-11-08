@Tags(['postgres'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:medlink_backend/medlink_backend.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// Haqiqiy PostgreSQL bilan integratsion test.
/// Ishga tushirish: TEST_DATABASE_URL=postgresql://... dart test -t postgres
/// (CI'da postgres xizmati bilan ishlaydi; o'zgaruvchi bo'lmasa — o'tkaziladi.)
final _url = Platform.environment['TEST_DATABASE_URL'];
final _key = List<int>.generate(32, (i) => i * 3 % 256);

class _Otp implements OtpSender {
  final codes = <String, String>{};
  @override
  Future<void> send(String phone, String code) async => codes[phone] = code;
}

class _Model implements MedicalModel {
  @override
  String get name => 'fake';
  @override
  Future<String> complete(String prompt) async =>
      '{"urgency":"routine","specialties":["neurologist"],"advice":"Dam oling"}';
}

class _Wallet implements WalletGateway {
  @override
  Future<String?> charge(PaymentOrder order, String token) async => 'pi_1';

  @override
  Future<bool> refund(PaymentOrder order) async => true;
}

/// Bitta "server nusxasi": servislar + API + persistence middleware.
class _World {
  _World(this.store) {
    enc = FieldEncryption({'k1': _key}, 'k1');
    auth = AuthService(
      jwtSecret: 'j' * 40,
      encryption: enc,
      otpSender: otp,
      adminPhones: {'+998900000001'},
    );
    doctors = DoctorService(enc);
    appointments = AppointmentService(doctors, enc);
    orders = OrderRepository();
    chat = ChatService(appointments, enc);
    click = ClickMerchant(
      serviceId: '1',
      merchantId: '1',
      secretKey: 'secret',
      orders: orders,
      onPaid: (o) => appointments.markPaid(o.appointmentId),
    );
    payme = PaymeMerchant(
      merchantId: 'm',
      key: 'paymekey',
      orders: orders,
      onPaid: (o) => appointments.markPaid(o.appointmentId),
      onRefunded: (_) {},
    );
    api = MedLinkApi(
      auth: auth,
      consents: consents,
      triage: triage,
      doctors: doctors,
      appointments: appointments,
      orders: orders,
      click: click,
      payme: payme,
      wallet: _Wallet(),
      audit: PostgresAuditLog(store.pool),
      profiles: profiles,
      devices: devices,
      notifications: NotificationService(
        devices: devices,
        sender: LogPushSender(),
      ),
      chat: chat,
      attachments: AttachmentService(
        appointments: appointments,
        chat: chat,
        encryption: enc,
        store: PostgresAttachmentStore(store.pool),
      ),
      video: VideoTokenIssuer(url: '', apiKey: '', apiSecret: ''),
      publicBaseUrl: 'http://localhost',
    );
    handler = const Pipeline()
        .addMiddleware(persistenceMiddleware(store))
        .addHandler(api.handler);
  }

  final PostgresStore store;
  late final FieldEncryption enc;
  final otp = _Otp();
  late final AuthService auth;
  final consents = ConsentService();
  late final profiles = MedicalProfileService(enc);
  late final triage = TriageService(model: _Model(), encryption: enc);
  late final DoctorService doctors;
  late final AppointmentService appointments;
  late final OrderRepository orders;
  late final ChatService chat;
  late final ClickMerchant click;
  late final PaymeMerchant payme;
  final devices = DeviceRegistry();
  late final MedLinkApi api;
  late final Handler handler;

  Future<Map<String, int>> restore() => restoreAll(
    store,
    auth: auth,
    consents: consents,
    profiles: profiles,
    triage: triage,
    doctors: doctors,
    appointments: appointments,
    orders: orders,
    click: click,
    payme: payme,
    chat: chat,
    devices: devices,
  );

  Future<(int, Map<String, dynamic>)> send(
    String method,
    String path, {
    Object? body,
    String? token,
    Map<String, String>? form,
  }) async {
    final res = await handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        body: form != null
            ? Uri(queryParameters: form).query
            : (body == null ? null : jsonEncode(body)),
        headers: {'authorization': ?(token == null ? null : 'Bearer $token')},
      ),
    );
    final text = await res.readAsString();
    return (
      res.statusCode,
      text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>,
    );
  }

  Future<String> login(String phone, {bool consent = true}) async {
    await send('POST', '/v1/auth/otp/request', body: {'phone': phone});
    final (_, j) = await send(
      'POST',
      '/v1/auth/otp/verify',
      body: {'phone': phone, 'code': otp.codes[phone]},
    );
    final t = j['token'] as String;
    if (consent) {
      await send(
        'POST',
        '/v1/consents',
        token: t,
        body: {
          'decisions': [
            for (final s in ConsentScope.values)
              {
                'scope': s.name,
                'version': currentConsentVersions[s],
                'granted': true,
              },
          ],
        },
      );
    }
    return t;
  }
}

String _clickSign(Map<String, String> p, {required bool complete}) => md5
    .convert(
      utf8.encode(
        [
          p['click_trans_id'],
          p['service_id'],
          'secret',
          p['merchant_trans_id'],
          if (complete) p['merchant_prepare_id'],
          p['amount'],
          p['action'],
          p['sign_time'],
        ].join(),
      ),
    )
    .toString();

void main() {
  final url = _url;
  if (url == null) {
    test('PostgreSQL', () {}, skip: 'TEST_DATABASE_URL berilmagan');
    return;
  }

  setUpAll(() async {
    final c = await Connection.openFromUrl(url);
    await c.execute(
      'DROP SCHEMA public CASCADE; CREATE SCHEMA public;',
      queryMode: QueryMode.simple,
    );
    await c.close();
  });

  setUp(() {
    changes.enabled = true;
    changes.drain();
  });
  tearDown(() => changes.enabled = false);

  test('migratsiyalar takroriy ishga tushishga chidamli', () async {
    final store = await PostgresStore.open(url);
    final c = await Connection.openFromUrl(url);
    expect(await PostgresStore.migrate(c), 0);
    await c.close();
    await store.close();
  });

  test('ikkinchi server nusxasi ishga tushmaydi (advisory lock)', () async {
    final first = await PostgresStore.open(url);
    await expectLater(PostgresStore.open(url), throwsStateError);
    await first.close();
    // Birinchisi yopilgach — ochiladi.
    final again = await PostgresStore.open(url);
    await again.close();
  });

  test('to\'liq oqim qayta ishga tushgandan keyin bazadan tiklanadi', () async {
    // ======== 1-nusxa: ma'lumot yaratish ========
    var store = await PostgresStore.open(url);
    var w = _World(store);
    await w.restore();

    final patient = await w.login('+998901234567');
    final doc = await w.login('+998907777777');
    final admin = await w.login('+998900000001');
    await w.send(
      'PUT',
      '/v1/me/profile',
      token: patient,
      body: {
        'fullName': 'Aliyev Vali',
        'birthDate': '1990-05-01',
        'allergies': ['Penitsillin'],
      },
    );
    final (_, tri) = await w.send(
      'POST',
      '/v1/triage',
      token: patient,
      body: {
        'symptoms': 'Bosh og\'rig\'i 3 kun',
        'ageYears': 36,
        'sex': 'male',
      },
    );
    await w.send(
      'POST',
      '/v1/me/devices',
      token: patient,
      body: {'token': 'fid-1', 'platform': 'android', 'locale': 'uz'},
    );

    final (_, app) = await w.send(
      'POST',
      '/v1/doctors/apply',
      token: doc,
      body: {
        'fullName': 'Rahimova Shahnoza Bahodirovna',
        'specialty': 'neurologist',
        'licenseNumber': 'LIC-77',
        'documentRefs': ['https://x/diploma.pdf'],
        'priceUzs': 200000,
      },
    );
    await w.send(
      'POST',
      '/v1/admin/doctors/${app['id']}/moderate',
      token: admin,
      body: {'decision': 'approved'},
    );
    final docT = await w.login('+998907777777', consent: false);
    final day = DateTime.now().toUtc().add(const Duration(days: 1));
    final (cs, _) = await w.send(
      'PUT',
      '/v1/doctor/settings',
      token: docT,
      body: {
        'workDays': [1, 2, 3, 4, 5, 6, 7],
        'startHour': 9,
        'endHour': 12,
        'onlineEnabled': true,
        'onlinePriceUzs': 150000,
      },
    );
    expect(cs, 200);
    final date = day.toIso8601String().substring(0, 10);
    final (_, slots) = await w.send(
      'GET',
      '/v1/doctors/${app['id']}/slots?date=$date',
    );
    final s1 = (slots['items'] as List)[0] as String;
    final s2 = (slots['items'] as List)[1] as String;

    // 1-qabul: onlayn, Click orqali.
    final (_, a1) = await w.send(
      'POST',
      '/v1/appointments',
      token: patient,
      body: {
        'doctorId': app['id'],
        'startsAt': s1,
        'reason': 'Uyqusizlik',
        'type': 'online',
        'triageId': tri['id'],
      },
    );
    final (_, o1) = await w.send(
      'POST',
      '/v1/payments/checkout',
      token: patient,
      body: {'appointmentId': a1['id'], 'provider': 'click'},
    );
    final p = {
      'click_trans_id': '555',
      'service_id': '1',
      'click_paydoc_id': '1',
      'merchant_trans_id': o1['id'] as String,
      'amount': '150000',
      'action': '0',
      'error': '0',
      'error_note': '',
      'sign_time': '2026-11-08 10:00:00',
    };
    p['sign_string'] = _clickSign(p, complete: false);
    final (_, prep) = await w.send('POST', '/payments/click/prepare', form: p);
    expect(prep['error'], 0);
    final p2 = {
      ...p,
      'action': '1',
      'merchant_prepare_id': '${prep['merchant_prepare_id']}',
    };
    p2['sign_string'] = _clickSign(p2, complete: true);
    expect(
      (await w.send('POST', '/payments/click/complete', form: p2)).$2['error'],
      0,
    );

    // 2-qabul: klinikada, Payme orqali.
    final (_, a2) = await w.send(
      'POST',
      '/v1/appointments',
      token: patient,
      body: {'doctorId': app['id'], 'startsAt': s2, 'reason': 'Nazorat'},
    );
    final (_, o2) = await w.send(
      'POST',
      '/v1/payments/checkout',
      token: patient,
      body: {'appointmentId': a2['id'], 'provider': 'payme'},
    );
    final paymeAuth = 'Basic ${base64.encode(utf8.encode('Paycom:paymekey'))}';
    Future<Map<String, dynamic>> rpc(
      String m,
      Map<String, Object?> params,
    ) async {
      final res = await w.handler(
        Request(
          'POST',
          Uri.parse('http://localhost/payments/payme'),
          headers: {'authorization': paymeAuth},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'method': m,
            'params': params,
          }),
        ),
      );
      return jsonDecode(await res.readAsString()) as Map<String, dynamic>;
    }

    await rpc('CreateTransaction', {
      'id': 'pm-1',
      'time': 1,
      'amount': 20000000,
      'account': {'order_id': o2['id']},
    });
    expect(
      ((await rpc('PerformTransaction', {'id': 'pm-1'}))['result']
          as Map)['state'],
      2,
    );

    // Chat, xulosa, sharh.
    await w.send(
      'POST',
      '/v1/appointments/${a1['id']}/messages',
      token: patient,
      body: {'text': 'Salom, doktor!'},
    );
    await w.send(
      'POST',
      '/v1/appointments/${a1['id']}/messages',
      token: docT,
      body: {'text': 'Salom! Qachondan beri?'},
    );
    final png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3];
    final upRes = await w.handler(
      Request(
        'POST',
        Uri.parse('http://localhost/v1/appointments/${a1['id']}/attachments'),
        body: png,
        headers: {'authorization': 'Bearer $patient', 'x-file-name': 'eko.png'},
      ),
    );
    expect(upRes.statusCode, 201);
    final attId =
        ((jsonDecode(await upRes.readAsString()) as Map)['attachment']
            as Map)['id'];
    final docUser = w.doctors.byId(app['id'] as String)!.userId;
    final appt1 = w.appointments.byId(a1['id'] as String)!;
    await w.appointments.setConclusion(appt1.id, docUser, {
      'diagnosis': 'Insomniya',
      'prescriptions': [
        {'drug': 'Melatonin', 'dose': '3 mg', 'durationDays': 14},
      ],
    }, now: appt1.startsAt.add(const Duration(minutes: 30)));
    await w.send(
      'POST',
      '/v1/appointments/${a1['id']}/review',
      token: patient,
      body: {'rating': 5, 'comment': 'Rahmat!'},
    );
    // Middleware'dan tashqaridagi (setConclusion) o'zgarishlar ham yozilsin.
    await store.flush(changes.drain());
    expect(changes.isEmpty, isTrue);

    final patientId = w.appointments.byId(a1['id'] as String)!.patientId;
    final doctorId = app['id'] as String;
    await store.close(); // "server o'chdi"

    // ======== 2-nusxa: bazadan tiklash ========
    store = await PostgresStore.open(url);
    w = _World(store);
    final counts = await w.restore();
    expect(counts['users'], 3);
    expect(counts['appointments'], 2);
    expect(counts['chat_messages'], 3);

    // Foydalanuvchi o'sha ID bilan qaytadi.
    final again = await w.login('+998901234567', consent: false);
    expect(w.auth.userById(patientId), isNotNull);
    expect(await w.consents.hasAllRequired(patientId), isTrue);
    expect((await w.profiles.get(patientId)).allergies, ['Penitsillin']);
    expect(await w.triage.history(patientId), hasLength(1));
    expect(w.devices.forUser(patientId).single.token, 'fid-1');

    // Shifokor: tasdiqlangan, jadval va onlayn sozlamalari, reyting.
    final d = w.doctors.byId(doctorId)!;
    expect(d.status, ModerationStatus.approved);
    expect(d.onlineEnabled, isTrue);
    expect(d.onlinePriceUzs, 150000);
    expect(d.endHour, 12);
    expect(d.reviewCount, 1);
    expect(w.auth.userById(d.userId)!.role, Role.doctor);

    // 1-qabul: yakunlangan, xulosa ochiladi, sharh bor.
    final (_, r1) = await w.send(
      'GET',
      '/v1/appointments/${a1['id']}',
      token: again,
    );
    expect(r1['status'], 'completed');
    expect(r1['type'], 'online');
    expect((r1['conclusion'] as Map)['diagnosis'], 'Insomniya');
    expect((r1['review'] as Map)['rating'], 5);
    expect(w.orders.byId(o1['id'] as String)!.status, OrderStatus.paid);

    // 2-qabul: Payme orqali tasdiqlangan; tranzaksiya holati saqlangan.
    final (_, r2) = await w.send(
      'GET',
      '/v1/appointments/${a2['id']}',
      token: again,
    );
    expect(r2['status'], 'confirmed');
    final check = w.payme.handle(
      'Basic ${base64.encode(utf8.encode('Paycom:paymekey'))}',
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'CheckTransaction',
        'params': {'id': 'pm-1'},
      }),
    );
    expect((check['result'] as Map)['state'], 2);

    // Click: takroriy "complete" — "allaqachon to'langan" (prepare tiklangan).
    expect(w.click.complete(p2)['error'], -4);

    // Chat tartibi va matni.
    final (_, msgs) = await w.send(
      'GET',
      '/v1/appointments/${a1['id']}/messages',
      token: again,
    );
    expect((msgs['items'] as List).map((m) => m['text']), [
      'Salom, doktor!',
      'Salom! Qachondan beri?',
      'eko.png',
    ]);

    // Fayl bazadan o'qiladi (shifrlangan holda saqlangan).
    final dl = await w.handler(
      Request(
        'GET',
        Uri.parse(
          'http://localhost/v1/appointments/${a1['id']}/attachments/$attId',
        ),
        headers: {'authorization': 'Bearer $again'},
      ),
    );
    expect(dl.statusCode, 200);
    expect(await dl.read().expand((c) => c).toList(), png);
    expect(
      ((msgs['items'] as List).last as Map)['attachment']['name'],
      'eko.png',
    );

    // Audit jurnali bazada.
    expect(await PostgresAuditLog(store.pool).forActor(patientId), isNotEmpty);

    // Bazada ochiq tibbiy matn yo'q (shifrlangan).
    final c = await Connection.openFromUrl(url);
    final raw = await c.execute(
      "SELECT data::text FROM chat_messages UNION ALL "
      "SELECT data::text FROM medical_profiles UNION ALL "
      "SELECT data::text FROM appointments",
    );
    final dump = raw.map((r) => r.first as String).join(' ');
    for (final secret in ['Salom', 'Penitsillin', 'Uyqusizlik', 'Insomniya']) {
      expect(dump, isNot(contains(secret)));
    }

    // "Unutilish huquqi": tibbiy ma'lumotlar bazadan ham o'chadi.
    await w.send('DELETE', '/v1/me/health-data', token: again);
    final left = await c.execute(
      Sql.named(
        'SELECT (SELECT count(*) FROM triage_results WHERE user_id = @u) + '
        '(SELECT count(*) FROM medical_profiles WHERE id = @u)',
      ),
      parameters: {'u': patientId},
    );
    expect(left.first.first, 0);

    // Hisobni to'liq o'chirish: raqam bazadan yo'qoladi, qayta ishga
    // tushganda hisob tiklanmaydi, to'lov yozuvlari (qonun bo'yicha) qoladi.
    expect((await w.send('DELETE', '/v1/me', token: again)).$1, 200);
    final u = await c.execute(
      Sql.named('SELECT phone_hash, data::text FROM users WHERE id = @u'),
      parameters: {'u': patientId},
    );
    expect(u.first[0], 'deleted:$patientId');
    expect(u.first[1] as String, contains('"phoneEnc": ""'));
    await c.close();
    await store.close();

    store = await PostgresStore.open(url);
    w = _World(store);
    final counts2 = await w.restore();
    expect(counts2['users'], 3); // qatorlar o'qiladi, o'chirilgan tiklanmaydi
    expect(w.auth.userById(patientId), isNull);
    expect(w.auth.userCount, 2);
    expect(w.orders.byId(o1['id'] as String), isNotNull);
    expect(w.devices.forUser(patientId), isEmpty);
    expect(await w.consents.hasAllRequired(patientId), isFalse);
    // Shu raqam bilan kirish — yangi hisob.
    await w.login('+998901234567', consent: false);
    expect(w.auth.userCount, 3);
    await store.close();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
