import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:medlink_backend/medlink_backend.dart';
import 'package:shelf/shelf.dart';
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
  @override
  Future<bool> charge(PaymentOrder order, String token) async =>
      token == 'tok_ok';
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

  group('API oqimi', () {
    late MedLinkApi api;
    late Handler h;
    late _CapturingOtp otp;

    setUp(() {
      final enc = FieldEncryption({'k1': _key}, 'k1');
      otp = _CapturingOtp();
      final doctors = DoctorService(enc);
      final appts = AppointmentService(doctors, enc);
      final orders = OrderRepository();
      api = MedLinkApi(
        auth: AuthService(
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
        wallet: _FakeWallet(),
        audit: InMemoryAuditLog(),
        profiles: MedicalProfileService(enc),
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

      final tomorrow = DateTime.now().toUtc().add(const Duration(days: 1));
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
  });
}
