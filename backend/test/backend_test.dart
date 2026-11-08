import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medlink_backend/medlink_backend.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:test/test.dart';

final _key = List<int>.generate(32, (i) => i);
final _key2 = List<int>.generate(32, (i) => 255 - i);

class _CapturingOtp implements OtpSender {
  final codes = <String, String>{};
  @override
  Future<void> send(String phone, String code) async => codes[phone] = code;
}

class _FakeModel implements MedicalModel {
  _FakeModel(this.reply);
  String reply;
  String? lastPrompt;
  @override
  String get name => 'fake';
  @override
  Future<String> complete(String prompt) async {
    lastPrompt = prompt;
    return reply;
  }
}

class _FakeWallet implements WalletGateway {
  final refunded = <String>[];
  bool refundOk = true;

  @override
  Future<String?> charge(PaymentOrder order, String token) async =>
      token == 'tok_ok' ? 'pi_${order.id}' : null;

  @override
  Future<bool> refund(PaymentOrder order) async {
    if (refundOk) refunded.add(order.providerTxnId!);
    return refundOk;
  }
}

void main() {
  group('FieldEncryption', () {
    test('roundtrip va AAD bog\'lanishi', () async {
      final e = FieldEncryption({'k1': _key}, 'k1');
      final c = await e.encrypt('bosh og\'rig\'i', aad: 'triage:u1:t1');
      expect(c, startsWith('enc:v1:k1:'));
      expect(c, isNot(contains('bosh')));
      expect(await e.decrypt(c, aad: 'triage:u1:t1'), 'bosh og\'rig\'i');
      // Boshqa yozuvga ko'chirilgan shifr ochilmaydi.
      expect(() => e.decrypt(c, aad: 'triage:u2:t1'), throwsA(anything));
    });

    test('kalit rotatsiyasi', () async {
      final old = FieldEncryption({'k1': _key}, 'k1');
      final c = await old.encrypt('x', aad: 'a');
      final rotated = FieldEncryption({'k1': _key, 'k2': _key2}, 'k2');
      expect(rotated.needsRotation(c), isTrue);
      final c2 = await rotated.reencrypt(c, aad: 'a');
      expect(c2, startsWith('enc:v1:k2:'));
      expect(await rotated.decrypt(c2, aad: 'a'), 'x');
    });
  });

  group('TriageService', () {
    test('PII yashiriladi va qizil bayroq emergency qiladi', () async {
      final model = _FakeModel(
        jsonEncode({
          'urgency': 'routine',
          'conditions': [
            {
              'name': 'Stenokardiya',
              'likelihood': 'medium',
              'rationale': '...',
            },
          ],
          'specialties': ['cardiologist', 'astrologer'],
          'redFlags': <String>[],
          'advice': 'Shifokorga murojaat qiling',
        }),
      );
      final t = TriageService(
        model: model,
        encryption: FieldEncryption({'k1': _key}, 'k1'),
      );
      final r = await t.analyze(
        'u1',
        TriageInput(
          symptoms: "Ko'krakda kuchli og'riq, tel +998901234567",
          ageYears: 54,
          sex: 'male',
        ),
      );
      expect(model.lastPrompt, isNot(contains('901234567')));
      expect(r.urgency, Urgency.emergency);
      expect(r.specialties, [
        'cardiologist',
      ]); // oq ro'yxatdan tashqarisi olib tashlandi
      expect((await t.history('u1')).single['id'], r.id);
    });

    test('apostrof variantlari va yozilish usullaridan qat\'i nazar', () {
      for (final text in [
        "Ko'krakda kuchli og'riq",
        'Ko‘krakda kuchli og‘riq',
        'Koʻkragim siqilyapti',
        'kokrakda ogriq bor',
        'KO`KRAK OG`RIYAPTI',
        'боль в груди',
      ]) {
        expect(
          TriageService.detectRedFlags(text),
          contains("Ko'krak qafasidagi og'riq"),
          reason: text,
        );
      }
      expect(TriageService.detectRedFlags('Boshim ogriyapti, tumov'), isEmpty);
      expect(
        TriageService.detectRedFlags('Bolada talvasa boshlandi'),
        contains('Tutqanoq / talvasa'),
      );
    });

    test('model ishlamasa fallback', () async {
      final t = TriageService(
        model: _FakeModel('not json'),
        encryption: FieldEncryption({'k1': _key}, 'k1'),
      );
      final r = await t.analyze(
        'u1',
        TriageInput(symptoms: 'yo\'tal 3 kun', ageYears: 30, sex: 'female'),
      );
      expect(r.model, 'fallback');
      expect(r.specialties, ['therapist']);
    });
  });

  group('Click', () {
    late OrderRepository orders;
    late ClickMerchant click;
    late PaymentOrder order;
    var paid = false;

    setUp(() {
      orders = OrderRepository();
      paid = false;
      click = ClickMerchant(
        serviceId: '100',
        merchantId: '200',
        secretKey: 'secret',
        orders: orders,
        onPaid: (_) => paid = true,
      );
      order = orders.create(
        appointmentId: 'a1',
        userId: 'u1',
        amountUzs: 150000,
        provider: PaymentProvider.click,
      );
    });

    Map<String, String> params(
      String action, {
      String? prepId,
      String amount = '150000',
    }) {
      final p = {
        'click_trans_id': '999',
        'service_id': '100',
        'click_paydoc_id': '1',
        'merchant_trans_id': order.id,
        'amount': amount,
        'action': action,
        'error': '0',
        'error_note': 'Success',
        'sign_time': '2026-11-07 10:00:00',
        'merchant_prepare_id': ?prepId,
      };
      final raw =
          '999100secret${order.id}${prepId ?? ''}$amount$action'
          '2026-11-07 10:00:00';
      p['sign_string'] = md5.convert(utf8.encode(raw)).toString();
      return p;
    }

    test('prepare + complete muvaffaqiyatli', () {
      final prep = click.prepare(params('0'));
      expect(prep['error'], 0);
      final done = click.complete(
        params('1', prepId: '${prep['merchant_prepare_id']}'),
      );
      expect(done['error'], 0);
      expect(order.status, OrderStatus.paid);
      expect(paid, isTrue);
    });

    test('noto\'g\'ri imzo va summa rad etiladi', () {
      expect(click.prepare({...params('0'), 'sign_string': 'x'})['error'], -1);
      expect(click.prepare(params('0', amount: '1000'))['error'], -2);
    });
  });

  group('Payme', () {
    late OrderRepository orders;
    late PaymeMerchant payme;
    late PaymentOrder order;
    final auth = 'Basic ${base64.encode(utf8.encode('Paycom:key123'))}';

    setUp(() {
      orders = OrderRepository();
      payme = PaymeMerchant(
        merchantId: 'm1',
        key: 'key123',
        orders: orders,
        onPaid: (_) {},
        onRefunded: (_) {},
      );
      order = orders.create(
        appointmentId: 'a1',
        userId: 'u1',
        amountUzs: 100000,
        provider: PaymentProvider.payme,
      );
    });

    Map<String, Object?> call(
      String method,
      Map<String, Object?> params, {
      String? authHeader,
    }) => payme.handle(
      authHeader ?? auth,
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': method,
        'params': params,
      }),
    );

    test('to\'liq tsikl: check -> create -> perform -> cancel (refund)', () {
      final acc = {'order_id': order.id};
      expect(
        call('CheckPerformTransaction', {
          'amount': 10000000,
          'account': acc,
        })['result'],
        {'allow': true},
      );
      final created =
          call('CreateTransaction', {
                'id': 'p1',
                'time': 1,
                'amount': 10000000,
                'account': acc,
              })['result']
              as Map;
      expect(created['state'], 1);
      // Idempotent.
      expect(
        (call('CreateTransaction', {
              'id': 'p1',
              'time': 1,
              'amount': 10000000,
              'account': acc,
            })['result']
            as Map)['transaction'],
        created['transaction'],
      );
      expect(
        (call('PerformTransaction', {'id': 'p1'})['result'] as Map)['state'],
        2,
      );
      expect(order.status, OrderStatus.paid);
      expect(
        (call('CancelTransaction', {'id': 'p1', 'reason': 5})['result']
            as Map)['state'],
        -2,
      );
      expect(order.status, OrderStatus.refunded);
    });

    test('xatolar', () {
      expect(
        (call('CheckPerformTransaction', {}, authHeader: 'Basic xx')['error']
            as Map)['code'],
        -32504,
      );
      expect(
        (call('CheckPerformTransaction', {
              'amount': 1,
              'account': {'order_id': order.id},
            })['error']
            as Map)['code'],
        -31001,
      );
      expect(
        (call('CheckTransaction', {'id': 'none'})['error'] as Map)['code'],
        -31003,
      );
    });
  });

  group('MedicalProfile', () {
    test('shifrlangan saqlash va validatsiya', () async {
      final svc = MedicalProfileService(FieldEncryption({'k1': _key}, 'k1'));
      await svc.put('u1', {
        'fullName': 'Aliyev Vali',
        'birthDate': '1990-05-01',
        'sex': 'male',
        'bloodType': 'A+',
        'allergies': ['Penitsillin'],
      });
      final p = await svc.get('u1');
      expect(p.allergies, ['Penitsillin']);
      expect(p.birthDate, DateTime(1990, 5, 1));
      expect(
        () => svc.put('u1', {'bloodType': 'Z'}),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('Demo ma\'lumotlar', () {
    test('seedDemo tasdiqlangan shifokorlarni yaratadi', () async {
      final d = DoctorService(FieldEncryption({'k1': _key}, 'k1'));
      await d.seedDemo();
      expect(d.search(), hasLength(8));
      expect(d.search(specialty: 'cardiologist').single.rating, 4.9);
    });
  });

  test('pul qaytarish siyosati', () {
    final start = DateTime.utc(2026, 11, 10, 5);
    final a = Appointment(
      id: 'a',
      patientId: 'p',
      doctorId: 'd',
      startsAt: start,
      priceUzs: 1,
      reasonEnc: 'x',
    );
    expect(refundReason(a, 'doctor', start), 'doctor_cancelled');
    expect(
      refundReason(a, 'patient', start.subtract(const Duration(hours: 24))),
      'patient_cancelled_early',
    );
    expect(
      refundReason(a, 'patient', start.subtract(const Duration(hours: 23))),
      isNull,
    );
  });

  group('Eskiz SMS', () {
    test('login, yuborish va token eskirsa qayta kirish', () async {
      final calls = <String>[];
      var logins = 0;
      final client = MockClient((req) async {
        calls.add(req.url.path);
        if (req.url.path.endsWith('/auth/login')) {
          logins++;
          return http.Response(
            jsonEncode({
              'data': {'token': 'tok$logins'},
            }),
            200,
          );
        }
        final auth = req.headers['authorization'];
        if (auth == 'Bearer tok1' && logins == 1 && calls.length > 2) {
          return http.Response('{}', 401);
        }
        expect(req.bodyFields['mobile_phone'], '998901234567');
        expect(req.bodyFields['message'], contains('123456'));
        return http.Response('{"status":"waiting"}', 200);
      });
      final s = EskizOtpSender(client: client, email: 'e', password: 'p');
      await s.send('+998901234567', '123456');
      expect(logins, 1);
      await s.send('+998901234567', '123456'); // 401 -> qayta login
      expect(logins, 2);
    });
  });

  group('Push bildirishnomalar', () {
    test('FCM: eskirgan token ro\'yxatdan chiqariladi', () async {
      final devices = DeviceRegistry()
        ..register(userId: 'u1', token: 'dead', platform: 'ios', locale: 'en')
        ..register(
          userId: 'u1',
          token: 'live',
          platform: 'android',
          locale: 'en',
        );
      Map<String, dynamic>? lastBody;
      final client = MockClient((req) async {
        lastBody = jsonDecode(req.body) as Map<String, dynamic>;
        final token = (lastBody!['message'] as Map)['fid'];
        return token == 'dead'
            ? http.Response('{"error":{"status":"NOT_FOUND"}}', 404)
            : http.Response('{}', 200);
      });
      final svc = NotificationService(
        devices: devices,
        sender: FcmPushSender(
          client: client,
          tokens: GcpTokenProvider(client, staticToken: 't'),
          projectId: 'medlink',
        ),
      );
      await svc.notify(
        'u1',
        PushKind.appointmentReminder,
        at: DateTime.utc(2026, 11, 8, 4),
        data: {'appointmentId': 'a1'},
      );
      expect(devices.forUser('u1').map((d) => d.token), ['live']);
      final msg = lastBody!['message'] as Map;
      expect((msg['notification'] as Map)['body'], contains('08.11 09:00'));
      expect(
        ((msg['android'] as Map)['notification'] as Map)['visibility'],
        'PRIVATE',
      );
    });

    test('token boshqa hisobga o\'tadi', () {
      final r = DeviceRegistry()
        ..register(userId: 'a', token: 't', platform: 'ios', locale: 'uz')
        ..register(userId: 'b', token: 't', platform: 'ios', locale: 'uz');
      expect(r.forUser('a'), isEmpty);
      expect(r.forUser('b'), hasLength(1));
      expect(
        () =>
            r.register(userId: 'a', token: 'x', platform: 'web', locale: 'uz'),
        throwsFormatException,
      );
    });
  });

  group('API oqimi', () {
    late MedLinkApi api;
    late Handler h;
    late _CapturingOtp otp;
    late LogPushSender push;
    late AppointmentService appts;
    late DoctorService doctors;
    late NotificationService notifications;
    late ChatService chat;
    late VideoTokenIssuer video;
    late _FakeWallet wallet;
    late AuthService authService;

    setUp(() {
      wallet = _FakeWallet();
      final enc = FieldEncryption({'k1': _key}, 'k1');
      otp = _CapturingOtp();
      doctors = DoctorService(enc);
      appts = AppointmentService(doctors, enc);
      final orders = OrderRepository();
      push = LogPushSender();
      final devices = DeviceRegistry();
      notifications = NotificationService(devices: devices, sender: push);
      wireAppointmentNotifications(
        appointments: appts,
        doctors: doctors,
        notifications: notifications,
      );
      chat = ChatService(appts, enc);
      wireConsultationNotifications(
        appointments: appts,
        doctors: doctors,
        chat: chat,
        notifications: notifications,
      );
      video = VideoTokenIssuer(
        url: 'wss://video.test',
        apiKey: 'APIkey',
        apiSecret: 's' * 40,
      );
      api = MedLinkApi(
        auth: authService = AuthService(
          jwtSecret: 'x' * 40,
          encryption: enc,
          otpSender: otp,
          adminPhones: {'+998900000001'},
        ),
        consents: ConsentService(),
        triage: TriageService(
          model: _FakeModel(
            '{"urgency":"routine","specialties":["therapist"]}',
          ),
          encryption: enc,
        ),
        doctors: doctors,
        appointments: appts,
        orders: orders,
        click: ClickMerchant(
          serviceId: '1',
          merchantId: '1',
          secretKey: 's',
          orders: orders,
          onPaid: (_) {},
        ),
        payme: PaymeMerchant(
          merchantId: 'm',
          key: 'k',
          orders: orders,
          onPaid: (_) {},
          onRefunded: (_) {},
        ),
        wallet: wallet,
        audit: InMemoryAuditLog(),
        profiles: MedicalProfileService(enc),
        devices: devices,
        notifications: notifications,
        chat: chat,
        video: video,
        publicBaseUrl: 'http://localhost',
      );
      h = api.handler;
    });

    Future<(int, Map<String, dynamic>)> send(
      String method,
      String path, {
      Object? body,
      String? token,
    }) async {
      final res = await h(
        Request(
          method,
          Uri.parse('http://localhost$path'),
          body: body == null ? null : jsonEncode(body),
          headers: {'authorization': ?(token == null ? null : 'Bearer $token')},
        ),
      );
      return (
        res.statusCode,
        jsonDecode(await res.readAsString()) as Map<String, dynamic>,
      );
    }

    Future<String> login(String phone) async {
      await send('POST', '/v1/auth/otp/request', body: {'phone': phone});
      final (_, j) = await send(
        'POST',
        '/v1/auth/otp/verify',
        body: {'phone': phone, 'code': otp.codes[phone]},
      );
      return j['token'] as String;
    }

    Future<void> consentAll(String token) => send(
      'POST',
      '/v1/consents',
      token: token,
      body: {
        'decisions': [
          for (final s in ConsentScope.values)
            {
              'scope': s.name,
              'version': currentConsentVersions[s],
              'granted': s != ConsentScope.marketing,
            },
        ],
      },
    );

    test('rozilikasiz tibbiy endpointlar 451 qaytaradi', () async {
      final t = await login('+998901112233');
      final (code, _) = await send(
        'POST',
        '/v1/triage',
        token: t,
        body: {'symptoms': 'bosh og\'riydi', 'ageYears': 30, 'sex': 'male'},
      );
      expect(code, 451);
      await consentAll(t);
      final (code2, body) = await send(
        'POST',
        '/v1/triage',
        token: t,
        body: {'symptoms': 'bosh og\'riydi', 'ageYears': 30, 'sex': 'male'},
      );
      expect(code2, 200);
      expect(body['disclaimer'], isNotEmpty);
    });

    test('shifokor moderatsiyasi -> bron -> wallet to\'lov', () async {
      final doc = await login('+998901111111');
      final admin = await login('+998900000001');
      final patient = await login('+998902222222');
      for (final t in [doc, admin, patient]) {
        await consentAll(t);
      }
      // Push qurilmalari: bemor — rus, shifokor — o'zbek tilida.
      for (final (t, token, loc) in [
        (patient, 'fcm-patient', 'ru'),
        (doc, 'fcm-doctor', 'uz'),
      ]) {
        expect(
          (await send(
            'POST',
            '/v1/me/devices',
            token: t,
            body: {'token': token, 'platform': 'android', 'locale': loc},
          )).$1,
          200,
        );
      }
      List<String> titles() => [for (final m in push.sent) m.$2.title];

      final (c1, app) = await send(
        'POST',
        '/v1/doctors/apply',
        token: doc,
        body: {
          'fullName': 'Aliyev Vali Karimovich',
          'specialty': 'cardiologist',
          'licenseNumber': 'LIC-12345',
          'documentRefs': ['gs://medlink-docs/diploma.pdf'],
          'priceUzs': 200000,
        },
      );
      expect(c1, 201);
      expect(
        (await send('GET', '/v1/doctors')).$2['items'],
        isEmpty,
      ); // tasdiqlanmagan — ko'rinmaydi

      expect(
        (await send('GET', '/v1/admin/doctors/pending', token: patient)).$1,
        403,
      );
      final (_, pending) = await send(
        'GET',
        '/v1/admin/doctors/pending',
        token: admin,
      );
      expect((pending['items'] as List).single['licenseNumber'], 'LIC-12345');
      expect(
        (await send(
          'POST',
          '/v1/admin/doctors/${app['id']}/moderate',
          token: admin,
          body: {'decision': 'approved'},
        )).$1,
        200,
      );
      expect(
        (await send('GET', '/v1/doctors?specialty=cardiologist')).$2['items'],
        hasLength(1),
      );
      await Future<void>.delayed(Duration.zero);
      expect(titles(), ['Ariza tasdiqlandi']);

      // Standart jadval: dushanba–shanba. Eng yaqin ish kunini tanlaymiz.
      var tomorrow = DateTime.now().toUtc().add(const Duration(days: 1));
      if (tomorrow.weekday == DateTime.sunday) {
        tomorrow = tomorrow.add(const Duration(days: 1));
      }
      final day = tomorrow.toIso8601String().substring(0, 10);
      final (_, slots) = await send(
        'GET',
        '/v1/doctors/${app['id']}/slots?date=$day',
      );
      final slot = (slots['items'] as List).first as String;
      final (c2, appt) = await send(
        'POST',
        '/v1/appointments',
        token: patient,
        body: {'doctorId': app['id'], 'startsAt': slot, 'reason': 'Bosim'},
      );
      expect(c2, 201);
      expect(appt['status'], 'awaitingPayment');
      // Xuddi shu slot band.
      expect(
        (await send(
          'POST',
          '/v1/appointments',
          token: patient,
          body: {'doctorId': app['id'], 'startsAt': slot, 'reason': 'x'},
        )).$1,
        409,
      );

      final (c3, order) = await send(
        'POST',
        '/v1/payments/wallet',
        token: patient,
        body: {
          'appointmentId': appt['id'],
          'provider': 'googlePay',
          'token': 'tok_ok',
        },
      );
      expect(c3, 200);
      expect(order['status'], 'paid');
      expect(order['amountUzs'], 200000);
      final (_, list) = await send('GET', '/v1/appointments', token: patient);
      expect((list['items'] as List).single['status'], 'confirmed');

      // To'lovdan keyin: bemorga (ruscha) va shifokorga (o'zbekcha) push.
      await Future<void>.delayed(Duration.zero);
      expect(titles(), containsAll(['Приём подтверждён', 'Yangi bemor']));
      for (final (_, m) in push.sent) {
        // Qulf ekranida tibbiy ma'lumot ko'rinmasligi kerak.
        final text = '${m.title} ${m.body} ${m.data}'.toLowerCase();
        for (final secret in ['aliyev', 'kardiolog', 'cardiolog', 'bosim']) {
          expect(text, isNot(contains(secret)));
        }
      }
      expect(push.sent.last.$2.data['appointmentId'], appt['id']);

      // Eslatma: qabulga 30 daqiqa qolganda — bir marta.
      final reminders = ReminderScheduler(
        appointments: appts,
        doctors: doctors,
        notifications: notifications,
      );
      final startsAt = DateTime.parse(slot);
      expect(
        await reminders.tick(startsAt.subtract(const Duration(hours: 3))),
        0,
      );
      expect(
        await reminders.tick(startsAt.subtract(const Duration(minutes: 30))),
        1,
      );
      expect(
        await reminders.tick(startsAt.subtract(const Duration(minutes: 29))),
        0,
      );
      expect(
        titles().where(
          (t) => t.contains('eslatma') || t.contains('Напоминание'),
        ),
        hasLength(2),
      );

      // Qabul hali boshlanmagan — yakunlab bo'lmaydi.
      final docToken = await login('+998901111111'); // rol endi doctor
      expect(
        (await send(
          'POST',
          '/v1/doctor/appointments/${appt['id']}/complete',
          token: docToken,
        )).$1,
        409,
      );
      // Yakunlanmagan qabulga baho qo'yib bo'lmaydi.
      expect(
        (await send(
          'POST',
          '/v1/appointments/${appt['id']}/review',
          token: patient,
          body: {'rating': 5},
        )).$1,
        409,
      );
      expect(
        (await send('GET', '/v1/me', token: docToken)).$2['role'],
        'doctor',
      );
    });

    test('onlayn konsultatsiya: jadval, chat, video, xulosa', () async {
      final doc = await login('+998903333333');
      final admin = await login('+998900000001');
      final patient = await login('+998904444444');
      final stranger = await login('+998905555555');
      for (final t in [doc, admin, patient, stranger]) {
        await consentAll(t);
      }
      await send(
        'POST',
        '/v1/me/devices',
        token: doc,
        body: {'token': 'fid-doc', 'platform': 'ios', 'locale': 'uz'},
      );
      await send(
        'POST',
        '/v1/me/devices',
        token: patient,
        body: {'token': 'fid-patient', 'platform': 'android', 'locale': 'ru'},
      );
      final (_, app) = await send(
        'POST',
        '/v1/doctors/apply',
        token: doc,
        body: {
          'fullName': 'Karimova Dilnoza Rustamovna',
          'specialty': 'psychiatrist',
          'licenseNumber': 'LIC-9',
          'documentRefs': ['gs://x'],
          'priceUzs': 200000,
        },
      );
      await send(
        'POST',
        '/v1/admin/doctors/${app['id']}/moderate',
        token: admin,
        body: {'decision': 'approved'},
      );
      final docT = await login('+998903333333'); // rol: doctor

      // Onlayn hali yoqilmagan — bron qilib bo'lmaydi.
      final tomorrow = DateTime.now().toUtc().add(const Duration(days: 1));
      final day = tomorrow.toIso8601String().substring(0, 10);
      final weekday = DateTime.parse(day).weekday;

      // Jadval: faqat ertangi kun, 10:00–12:00, onlayn 150 000.
      final (cs, settings) = await send(
        'PUT',
        '/v1/doctor/settings',
        token: docT,
        body: {
          'workDays': [weekday],
          'startHour': 10,
          'endHour': 12,
          'onlineEnabled': true,
          'onlinePriceUzs': 150000,
        },
      );
      expect(cs, 200);
      expect(settings['onlineEnabled'], isTrue);
      expect(
        (await send(
          'PUT',
          '/v1/doctor/settings',
          token: docT,
          body: {'startHour': 12, 'endHour': 10},
        )).$1,
        400,
      );
      expect(
        (await send('GET', '/v1/doctor/settings', token: patient)).$1,
        403,
      );

      final (_, slots) = await send(
        'GET',
        '/v1/doctors/${app['id']}/slots?date=$day',
      );
      // 10:00–12:00 Toshkent = 4 ta 30 daqiqalik slot.
      expect(slots['items'], hasLength(4));
      expect(DateTime.parse((slots['items'] as List).first as String).hour, 5);
      final otherDay = tomorrow
          .add(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      expect(
        (await send(
          'GET',
          '/v1/doctors/${app['id']}/slots?date=$otherDay',
        )).$2['items'],
        isEmpty,
      );

      final slot = (slots['items'] as List).first as String;
      final (cb, appt) = await send(
        'POST',
        '/v1/appointments',
        token: patient,
        body: {
          'doctorId': app['id'],
          'startsAt': slot,
          'reason': 'Uyqusizlik',
          'type': 'online',
        },
      );
      expect(cb, 201);
      expect(appt['type'], 'online');
      expect(appt['priceUzs'], 150000);

      // To'lanmagan qabulda chat yopiq.
      expect(
        (await send(
          'POST',
          '/v1/appointments/${appt['id']}/messages',
          token: patient,
          body: {'text': 'Salom'},
        )).$1,
        409,
      );
      await send(
        'POST',
        '/v1/payments/wallet',
        token: patient,
        body: {
          'appointmentId': appt['id'],
          'provider': 'googlePay',
          'token': 'tok_ok',
        },
      );

      // Begona foydalanuvchi qabulni ham, chatni ham ko'ra olmaydi.
      expect(
        (await send(
          'GET',
          '/v1/appointments/${appt['id']}',
          token: stranger,
        )).$1,
        403,
      );
      expect(
        (await send(
          'GET',
          '/v1/appointments/${appt['id']}/messages',
          token: stranger,
        )).$1,
        403,
      );

      final (c1, m1) = await send(
        'POST',
        '/v1/appointments/${appt['id']}/messages',
        token: patient,
        body: {'text': 'Salom, doktor! 3 kundan beri uxlay olmayapman.'},
      );
      expect(c1, 201);
      expect(m1['mine'], isTrue);
      await send(
        'POST',
        '/v1/appointments/${appt['id']}/messages',
        token: docT,
        body: {'text': 'Salom! Qabulda batafsil gaplashamiz.'},
      );
      final (_, page) = await send(
        'GET',
        '/v1/appointments/${appt['id']}/messages?after=1',
        token: patient,
      );
      expect((page['items'] as List).single['senderRole'], 'doctor');
      expect((page['items'] as List).single['mine'], isFalse);
      expect(page['canWrite'], isTrue);

      // Shifokorga push: "Yangi xabar" — xabar matni ham, mutaxassislik ham yo'q.
      await Future<void>.delayed(Duration.zero);
      // Ikkala tomonga ham push: "Yangi xabar" — xabar matni ham,
      // mutaxassislik ham qulf ekranida ko'rinmaydi.
      final chatPush = push.sent.where(
        (p) => p.$2.data['kind'] == 'newMessage',
      );
      expect(chatPush, hasLength(2));
      for (final (_, m) in chatPush) {
        final txt = '${m.title} ${m.body}'.toLowerCase();
        expect(txt, isNot(contains('uxlay')));
        expect(txt, isNot(contains('psix')));
      }

      // Chatga rasm (JPEG imzosi bilan), begona va noto'g'ri fayllar.
      final jpeg = [0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(100, 7)];
      Future<Response> upload(List<int> bytes, String token, {String? name}) =>
          Future.value(
            h(
              Request(
                'POST',
                Uri.parse(
                  'http://localhost/v1/appointments/${appt['id']}/attachments',
                ),
                body: bytes,
                headers: {
                  'authorization': 'Bearer $token',
                  'x-file-name': ?name,
                },
              ),
            ),
          );
      final up = await upload(
        jpeg,
        patient,
        name: Uri.encodeComponent('qon tahlili.jpg'),
      );
      expect(up.statusCode, 201);
      final upJson =
          jsonDecode(await up.readAsString()) as Map<String, dynamic>;
      final att = upJson['attachment'] as Map;
      expect(att['mime'], 'image/jpeg');
      expect(att['name'], 'qon tahlili.jpg');
      expect(att['size'], jpeg.length);
      final dl = await h(
        Request(
          'GET',
          Uri.parse(
            'http://localhost/v1/appointments/${appt['id']}/attachments/${att['id']}',
          ),
          headers: {'authorization': 'Bearer $docT'},
        ),
      );
      expect(dl.statusCode, 200);
      expect(dl.headers['content-type'], 'image/jpeg');
      expect(await dl.read().expand((c) => c).toList(), jpeg);
      final denied = await h(
        Request(
          'GET',
          Uri.parse(
            'http://localhost/v1/appointments/${appt['id']}/attachments/${att['id']}',
          ),
          headers: {'authorization': 'Bearer $stranger'},
        ),
      );
      expect(denied.statusCode, 403);
      expect(
        (await upload(utf8.encode('salom'), patient, name: 'x.jpg')).statusCode,
        415,
      );
      expect(
        (await upload([
          0xFF,
          0xD8,
          0xFF,
          ...List.filled(AttachmentService.maxBytes, 0),
        ], patient)).statusCode,
        413,
      );

      // Shifokor bemor profilini ko'radi; bemor esa bu endpointni ishlata olmaydi.
      expect(
        (await send(
          'GET',
          '/v1/doctor/appointments/${appt['id']}/patient',
          token: docT,
        )).$1,
        200,
      );
      expect(
        (await send(
          'GET',
          '/v1/doctor/appointments/${appt['id']}/patient',
          token: patient,
        )).$1,
        403,
      );

      // Video: qabulgacha hali ko'p vaqt bor.
      final (cv, v) = await send(
        'POST',
        '/v1/appointments/${appt['id']}/video',
        token: patient,
      );
      expect(cv, 409);
      expect((v['error'] as Map)['code'], 'too_early');

      // Qabul vaqtida token beriladi va LiveKit formatida bo'ladi.
      final a = appts.byId(appt['id'] as String)!;
      final t = video.issue(
        a,
        userId: a.patientId,
        role: 'patient',
        now: a.startsAt,
      );
      final jwt = JWT.verify(t.token, SecretKey('s' * 40));
      final grant = (jwt.payload as Map)['video'] as Map;
      expect(grant['room'], 'medlink-${a.id}');
      expect(grant['roomJoin'], isTrue);
      expect(jwt.subject, a.patientId);
      expect(jwt.issuer, 'APIkey');
      expect(
        () => video.issue(
          a,
          userId: 'x',
          role: 'patient',
          now: a.startsAt.add(const Duration(hours: 2)),
        ),
        throwsA(isA<ApiException>()),
      );

      // Xulosa: qabul boshlanmasdan — yo'q; boshlangach — yakunlanadi.
      expect(
        (await send(
          'PUT',
          '/v1/doctor/appointments/${appt['id']}/conclusion',
          token: docT,
          body: {'diagnosis': 'Insomniya'},
        )).$1,
        409,
      );
      final docUserId = doctors.byId(a.doctorId)!.userId;
      await appts.setConclusion(a.id, docUserId, {
        'diagnosis': 'Birlamchi insomniya',
        'recommendations': 'Uyqu gigiyenasi, kofeinni kamaytirish.',
        'prescriptions': [
          {
            'drug': 'Melatonin',
            'dose': '3 mg',
            'frequency': 'Kechqurun 1 marta',
            'durationDays': 14,
          },
        ],
        'followUpDays': 14,
      }, now: a.startsAt.add(const Duration(minutes: 20)));
      final (_, done) = await send(
        'GET',
        '/v1/appointments/${appt['id']}',
        token: patient,
      );
      expect(done['status'], 'completed');
      expect(done['myRole'], 'patient');
      expect(done.containsKey('patientName'), isFalse); // bemorga kerak emas
      expect((done['conclusion'] as Map)['diagnosis'], 'Birlamchi insomniya');
      expect(
        ((done['conclusion'] as Map)['prescriptions'] as List).single['drug'],
        'Melatonin',
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        push.sent.map((p) => p.$2.data['kind']),
        contains('conclusionReady'),
      );
      // Xulosadan keyin 7 kun davomida savol berish mumkin.
      expect(
        (await send(
          'POST',
          '/v1/appointments/${appt['id']}/messages',
          token: patient,
          body: {'text': 'Rahmat!'},
        )).$1,
        201,
      );
    });

    test('OTP: telefon raqami bo\'yicha limit va X-Forwarded-For', () async {
      for (var i = 0; i < 5; i++) {
        expect(
          (await send(
            'POST',
            '/v1/auth/otp/request',
            body: {'phone': '+998906666666'},
          )).$1,
          200,
        );
      }
      // 6-urinish shu raqamga — rad etiladi.
      final (c, j) = await send(
        'POST',
        '/v1/auth/otp/request',
        body: {'phone': '+998906666666'},
      );
      expect(c, 429);
      expect((j['error'] as Map)['code'], 'rate_limited');
      // Boshqa raqam ishlayveradi (umumiy IP limiti 20).
      expect(
        (await send(
          'POST',
          '/v1/auth/otp/request',
          body: {'phone': '+998906666667'},
        )).$1,
        200,
      );
      final req = Request(
        'GET',
        Uri.parse('http://localhost/health'),
        headers: {'x-forwarded-for': '203.0.113.7, 10.0.0.1'},
      );
      expect(api.clientIp(req), 'unknown'); // trustProxy o'chiq
    });

    test('pul qaytarish: 24 soat qoidasi, admin navbati, statistika', () async {
      final doc = await login('+998908888881');
      final admin = await login('+998900000001');
      final patient = await login('+998908888882');
      for (final t in [doc, admin, patient]) {
        await consentAll(t);
      }
      await send(
        'POST',
        '/v1/me/devices',
        token: patient,
        body: {'token': 'fid-r', 'platform': 'ios', 'locale': 'uz'},
      );
      final (_, app) = await send(
        'POST',
        '/v1/doctors/apply',
        token: doc,
        body: {
          'fullName': 'Qodirov Anvar Botirovich',
          'specialty': 'therapist',
          'licenseNumber': 'LIC-R1',
          'documentRefs': ['gs://x'],
          'priceUzs': 100000,
        },
      );
      await send(
        'POST',
        '/v1/admin/doctors/${app['id']}/moderate',
        token: admin,
        body: {'decision': 'approved'},
      );
      final docT = await login('+998908888881');
      await send(
        'PUT',
        '/v1/doctor/settings',
        token: docT,
        body: {
          'workDays': [1, 2, 3, 4, 5, 6, 7],
        },
      );

      Future<String> bookAndPay(int daysAhead) async {
        final day = DateTime.now()
            .toUtc()
            .add(Duration(days: daysAhead))
            .toIso8601String()
            .substring(0, 10);
        final (_, slots) = await send(
          'GET',
          '/v1/doctors/${app['id']}/slots?date=$day',
        );
        final (_, a) = await send(
          'POST',
          '/v1/appointments',
          token: patient,
          body: {
            'doctorId': app['id'],
            'startsAt': (slots['items'] as List).first,
            'reason': 'x',
          },
        );
        await send(
          'POST',
          '/v1/payments/wallet',
          token: patient,
          body: {
            'appointmentId': a['id'],
            'provider': 'googlePay',
            'token': 'tok_ok',
          },
        );
        return a['id'] as String;
      }

      // Stripe vaqtincha ishlamayapti — qaytarish admin navbatiga tushadi.
      wallet.refundOk = false;
      // Bemor 3 kun oldin bekor qiladi — qaytariladi.
      final early = await bookAndPay(3);
      final (_, c1) = await send(
        'POST',
        '/v1/appointments/$early/cancel',
        token: patient,
      );
      expect(c1['refund'], 'requested');
      // Shifokor bekor qiladi — har doim qaytariladi.
      final byDoctor = await bookAndPay(4);
      final (_, c2) = await send(
        'POST',
        '/v1/appointments/$byDoctor/cancel',
        token: docT,
      );
      expect(c2['refund'], 'requested');
      // To'lanmagan bron bekor qilinsa — qaytariladigan narsa yo'q.
      final (_, a3) = await send(
        'GET',
        '/v1/appointments/$early',
        token: patient,
      );
      expect(a3['refundStatus'], 'requested');

      // Bemor/shifokor admin navbatini ko'ra olmaydi.
      expect((await send('GET', '/v1/admin/refunds', token: patient)).$1, 403);
      final (_, queue) = await send('GET', '/v1/admin/refunds', token: admin);
      expect(queue['items'], hasLength(2));
      final first = (queue['items'] as List).first as Map;
      expect(first['amountUzs'], 100000);
      expect(first['reason'], 'patient_cancelled_early');

      final (_, stats) = await send('GET', '/v1/admin/stats', token: admin);
      expect(stats['refundsPending'], 2);
      expect(stats['refundsPendingUzs'], 200000);
      expect((stats['appointmentsByStatus'] as Map)['cancelled'], 2);
      expect(stats['doctorsApproved'], greaterThanOrEqualTo(1));

      // Stripe hali ham ishlamasa — admin xato ko'radi, navbat saqlanadi.
      expect(
        (await send(
          'POST',
          '/v1/admin/refunds/${first['id']}/complete',
          token: admin,
        )).$1,
        502,
      );
      wallet.refundOk = true;
      final (cc, done) = await send(
        'POST',
        '/v1/admin/refunds/${first['id']}/complete',
        token: admin,
      );
      expect(cc, 200);
      expect(wallet.refunded, ['pi_${first['id']}']);
      expect(done['refundStatus'], 'refunded');
      expect(done['status'], 'refunded');
      // Takroriy yakunlash — topilmaydi.
      expect(
        (await send(
          'POST',
          '/v1/admin/refunds/${first['id']}/complete',
          token: admin,
        )).$1,
        404,
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        push.sent.map((p) => p.$2.data['kind']),
        contains('refundCompleted'),
      );
      expect(
        (await send('GET', '/v1/admin/refunds', token: admin)).$2['items'],
        hasLength(1),
      );

      // Stripe ishlayotganda Google Pay qaytarishi darhol avtomatik.
      final auto = await bookAndPay(5);
      final (_, c3) = await send(
        'POST',
        '/v1/appointments/$auto/cancel',
        token: patient,
      );
      expect(c3['refund'], 'refunded');
      expect(wallet.refunded, hasLength(2));
      final (_, a4) = await send(
        'GET',
        '/v1/appointments/$auto',
        token: patient,
      );
      expect(a4['refundStatus'], 'refunded');
    });

    Future<({String doctorId, String docToken})> approvedDoctor(
      String phone,
    ) async {
      final admin = await login('+998900000001');
      await consentAll(admin);
      var doc = await login(phone);
      await consentAll(doc);
      final (_, app) = await send(
        'POST',
        '/v1/doctors/apply',
        token: doc,
        body: {
          'fullName': 'Jalilov Bekzod Akmalovich',
          'specialty': 'therapist',
          'licenseNumber': 'LIC-$phone',
          'documentRefs': ['gs://x'],
          'priceUzs': 90000,
        },
      );
      await send(
        'POST',
        '/v1/admin/doctors/${app['id']}/moderate',
        token: admin,
        body: {'decision': 'approved'},
      );
      doc = await login(phone);
      await send(
        'PUT',
        '/v1/doctor/settings',
        token: doc,
        body: {
          'workDays': [1, 2, 3, 4, 5, 6, 7],
        },
      );
      return (doctorId: app['id'] as String, docToken: doc);
    }

    Future<List<String>> slotsOn(String doctorId, int daysAhead) async {
      final day = DateTime.now()
          .toUtc()
          .add(Duration(days: daysAhead))
          .toIso8601String()
          .substring(0, 10);
      final (_, s) = await send('GET', '/v1/doctors/$doctorId/slots?date=$day');
      return (s['items'] as List).cast<String>();
    }

    Future<String> bookPaid(String token, String doctorId, String at) async {
      final (_, a) = await send(
        'POST',
        '/v1/appointments',
        token: token,
        body: {'doctorId': doctorId, 'startsAt': at, 'reason': 'yo\'tal'},
      );
      await send(
        'POST',
        '/v1/payments/wallet',
        token: token,
        body: {
          'appointmentId': a['id'],
          'provider': 'applePay',
          'token': 'tok_ok',
        },
      );
      return a['id'] as String;
    }

    test('qabul vaqtini ko\'chirish: qoidalar va bildirishnoma', () async {
      final (:doctorId, :docToken) = await approvedDoctor('+998907777771');
      await send(
        'POST',
        '/v1/me/devices',
        token: docToken,
        body: {'token': 'fid-doc', 'platform': 'android', 'locale': 'uz'},
      );
      final patient = await login('+998907777772');
      await consentAll(patient);
      final day3 = await slotsOn(doctorId, 3);
      final id = await bookPaid(patient, doctorId, day3.first);

      // Begona foydalanuvchi va shifokor ko'chira olmaydi.
      expect(
        (await send(
          'POST',
          '/v1/appointments/$id/reschedule',
          token: docToken,
          body: {'startsAt': day3[1]},
        )).$1,
        403,
      );
      // Band yoki noto'g'ri vaqt.
      expect(
        (await send(
          'POST',
          '/v1/appointments/$id/reschedule',
          token: patient,
          body: {'startsAt': day3.first},
        )).$1,
        409,
      );
      expect(
        (await send(
          'POST',
          '/v1/appointments/$id/reschedule',
          token: patient,
          body: {'startsAt': 'ertaga'},
        )).$1,
        400,
      );

      final (code, moved) = await send(
        'POST',
        '/v1/appointments/$id/reschedule',
        token: patient,
        body: {'startsAt': day3[2]},
      );
      expect(code, 200);
      expect(
        DateTime.parse(moved['startsAt'] as String),
        DateTime.parse(day3[2]),
      );
      expect(moved['status'], 'confirmed');
      expect(moved['reschedulesLeft'], 1);
      // Eski vaqt bo'shadi, yangisi band.
      final after = await slotsOn(doctorId, 3);
      expect(after, contains(day3.first));
      expect(after, isNot(contains(day3[2])));
      await Future<void>.delayed(Duration.zero);
      expect(
        push.sent.map((p) => p.$2.data['kind']),
        contains('appointmentRescheduled'),
      );

      // Ikkinchi ko'chirish mumkin, uchinchisi — yo'q.
      expect(
        (await send(
          'POST',
          '/v1/appointments/$id/reschedule',
          token: patient,
          body: {'startsAt': day3[3]},
        )).$1,
        200,
      );
      final (limit, lj) = await send(
        'POST',
        '/v1/appointments/$id/reschedule',
        token: patient,
        body: {'startsAt': day3[4]},
      );
      expect(limit, 409);
      expect((lj['error'] as Map)['code'], 'reschedule_limit');

      // Qabulgacha 24 soatdan kam qolganda ko'chirib bo'lmaydi.
      final a = appts.byId(id)!;
      expect(
        () => appts.reschedule(
          id,
          a.patientId,
          DateTime.parse(day3[5]),
          now: a.startsAt.subtract(const Duration(hours: 3)),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'too_late_to_reschedule',
          ),
        ),
      );
    });

    test('hisobni o\'chirish: ma\'lumotlar, qabullar, tokenlar', () async {
      final (:doctorId, :docToken) = await approvedDoctor('+998906666661');
      const phone = '+998906666662';
      final patient = await login(phone);
      await consentAll(patient);
      await send(
        'PUT',
        '/v1/me/profile',
        token: patient,
        body: {
          'fullName': 'Karimova Dilnoza',
          'allergies': ['penitsillin'],
        },
      );
      await send(
        'POST',
        '/v1/triage',
        token: patient,
        body: {'symptoms': 'yo\'tal', 'ageYears': 30, 'sex': 'female'},
      );
      await send(
        'POST',
        '/v1/me/devices',
        token: patient,
        body: {'token': 'fid-del', 'platform': 'ios', 'locale': 'uz'},
      );
      final slots = await slotsOn(doctorId, 3);
      final future = await bookPaid(patient, doctorId, slots.first);
      final before = authService.userCount;

      final (code, j) = await send('DELETE', '/v1/me', token: patient);
      expect(code, 200);
      expect(j['refunds'], 1);
      expect(authService.userCount, before - 1);

      // Eski token endi ishlamaydi.
      expect((await send('GET', '/v1/me', token: patient)).$1, 401);
      // Kelgusi qabul bekor qilindi, pul avtomatik qaytarildi, vaqt bo'shadi.
      expect(appts.byId(future)!.status, AppointmentStatus.cancelled);
      expect(wallet.refunded, hasLength(1));
      expect(await slotsOn(doctorId, 3), contains(slots.first));
      // Tibbiy profil va AI tahlillari o'chirildi.
      final patientId = appts.byId(future)!.patientId;
      final profile = await api.profiles.get(patientId);
      expect(profile.fullName, isEmpty);
      expect(profile.allergies, isEmpty);
      expect(await api.triage.history(patientId), isEmpty);

      // Shu raqam bilan qayta kirish — yangi, bo'sh hisob, rozilik qayta
      // so'raladi.
      final again = await login(phone);
      final (_, me) = await send('GET', '/v1/me', token: again);
      expect(me['missingConsents'], isNotEmpty);
      expect(me['id'], isNot(patientId));
      expect(appts.forPatient(me['id'] as String), isEmpty);
    });

    test(
      'shifokor hisobini o\'chirsa — profil yashiriladi, pul qaytadi',
      () async {
        final (:doctorId, :docToken) = await approvedDoctor('+998905555551');
        final patient = await login('+998905555552');
        await consentAll(patient);
        final slots = await slotsOn(doctorId, 1);
        final id = await bookPaid(patient, doctorId, slots.last);
        final (code, j) = await send('DELETE', '/v1/me', token: docToken);
        expect(code, 200);
        expect(j['refunds'], 1);
        expect(appts.byId(id)!.status, AppointmentStatus.cancelled);
        final (_, a) = await send(
          'GET',
          '/v1/appointments/$id',
          token: patient,
        );
        expect(a['refundStatus'], 'refunded');
        final (_, search) = await send('GET', '/v1/doctors');
        expect(
          (search['items'] as List).map((d) => (d as Map)['id']),
          isNot(contains(doctorId)),
        );
      },
    );

    test(
      'chat real vaqtda (WebSocket): darhol keladi, begonaga yopiq',
      () async {
        final (:doctorId, :docToken) = await approvedDoctor('+998904444441');
        final patient = await login('+998904444442');
        await consentAll(patient);
        final slots = await slotsOn(doctorId, 2);
        final id = await bookPaid(patient, doctorId, slots.first);
        final server = await io.serve(h, InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        Uri live(String apptId) => Uri.parse(
          'ws://127.0.0.1:${server.port}/v1/appointments/$apptId/live',
        );

        final ws = IOWebSocketChannel.connect(
          live(id),
          headers: {'authorization': 'Bearer $docToken'},
        );
        final events = StreamIterator(ws.stream);
        expect(await events.moveNext(), isTrue);
        expect(jsonDecode(events.current as String)['type'], 'ready');

        final (code, _) = await send(
          'POST',
          '/v1/appointments/$id/messages',
          token: patient,
          body: {'text': 'Salom, doktor!'},
        );
        expect(code, 201);
        expect(
          await events.moveNext().timeout(const Duration(seconds: 5)),
          isTrue,
        );
        final ev = jsonDecode(events.current as String) as Map<String, dynamic>;
        expect(ev['type'], 'message');
        expect(ev['message']['text'], 'Salom, doktor!');
        expect(ev['message']['mine'], isFalse);
        expect(ev['message']['senderRole'], 'patient');
        await ws.sink.close();

        // Boshqa bemor bu qabul chatiga ulana olmaydi; tokensiz ham.
        final stranger = await login('+998904444443');
        for (final headers in [
          {'authorization': 'Bearer $stranger'},
          <String, String>{},
        ]) {
          final bad = IOWebSocketChannel.connect(live(id), headers: headers);
          await expectLater(
            bad.ready,
            throwsA(isA<WebSocketChannelException>()),
          );
        }
      },
    );

    test('maxfiylik siyosati va shartlar: 3 tilda, ommaviy', () async {
      Future<(int, String, Map<String, String>)> page(String path) async {
        final res = await h(Request('GET', Uri.parse('http://localhost$path')));
        return (res.statusCode, await res.readAsString(), res.headers);
      }

      final (c1, uz, hd) = await page('/legal/privacy');
      expect(c1, 200);
      expect(hd['content-type'], startsWith('text/html'));
      expect(uz, contains('Maxfiylik siyosati'));
      expect(uz, contains("O'RQ-547"));
      expect(uz, contains(currentConsentVersions[ConsentScope.personalData]));
      final (_, ru, _) = await page('/legal/privacy?lang=ru');
      expect(ru, contains('Политика конфиденциальности'));
      final (_, en, _) = await page('/legal/terms?lang=en');
      expect(en, contains('Terms of Use'));
      expect(en, contains('24 hours'));
      // Noma'lum til — o'zbekcha; HTML kiritish mumkin emas.
      final (_, x, _) = await page('/legal/terms?lang=<script>');
      expect(x, contains('Foydalanish shartlari'));
      expect(x, isNot(contains('<script>')));
    });
  });
}
