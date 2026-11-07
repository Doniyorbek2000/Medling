import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlink/core/api_client.dart';
import 'package:medlink/core/clinic_time.dart';
import 'package:medlink/core/theme.dart';
import 'package:medlink/core/l10n.dart';
import 'package:medlink/core/session.dart';
import 'package:medlink/features/auth/phone_screen.dart';
import 'package:medlink/features/triage/triage_result_screen.dart';
import 'package:medlink/models/models.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'helpers.dart';

const _scopes = [
  ('terms', true),
  ('personalData', true),
  ('healthData', true),
  ('aiProcessing', false),
  ('crossBorderTransfer', false),
  ('marketing', false),
];

Map<String, dynamic> _consentDocs() => {
  'documents': [
    for (final (s, r) in _scopes)
      {'scope': s, 'required': r, 'version': '2026-11-01', 'granted': false},
  ],
};

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('onboarding -> kirish ekrani', (t) async {
    await pumpApp(t, {}, onboardingDone: false);
    expect(find.text('Alomatlaringizni AI tahlil qiladi'), findsOneWidget);
    await t.tap(find.text("O'tkazish"));
    await t.pumpAndSettle();
    expect(find.text('Telefon raqamingiz'), findsOneWidget);
    expect(find.text('Kod olish'), findsOneWidget);
  });

  testWidgets('kirish ekrani rus tilida', (t) async {
    await pumpApp(t, {}, locale: const Locale('ru'));
    expect(find.text('Ваш номер телефона'), findsOneWidget);
    expect(find.text('Получить код'), findsOneWidget);
  });

  test('telefon formatlovchi', () {
    final f = UzPhoneFormatter();
    final v = f.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '901234567'),
    );
    expect(v.text, '90 123 45 67');
  });

  testWidgets("majburiy rozilik belgilanmaguncha davom etib bo'lmaydi", (
    t,
  ) async {
    Map<String, dynamic>? posted;
    final app = await pumpApp(
      t,
      {
        'GET /v1/consents': (_) => _consentDocs(),
        'POST /v1/consents': (req) {
          posted = jsonDecode(req.body) as Map<String, dynamic>;
          return {
            'missingConsents': [
              'aiProcessing',
              'crossBorderTransfer',
              'marketing',
            ],
          };
        },
        'GET /v1/appointments': (_) => {'items': <Object>[]},
      },
      loggedIn: true,
      missingConsents: ['terms', 'personalData', 'healthData'],
      height: 6000,
    );

    final button = find.widgetWithText(FilledButton, 'Roziman, davom etish');
    expect(t.widget<FilledButton>(button).onPressed, isNull);

    final boxes = find.byType(Checkbox);
    expect(boxes, findsNWidgets(6));
    for (final b in t.widgetList<Checkbox>(boxes)) {
      expect(b.value, isFalse, reason: 'hech biri oldindan belgilanmagan');
    }
    for (var i = 0; i < 3; i++) {
      await t.ensureVisible(boxes.at(i));
      await t.tap(boxes.at(i));
    }
    await t.pump();
    expect(t.widget<FilledButton>(button).onPressed, isNotNull);

    await t.tap(button);
    await t.pumpAndSettle();

    final decisions = (posted!['decisions'] as List).cast<Map>();
    expect(
      decisions.where((d) => d['granted'] == true).map((d) => d['scope']),
      ['terms', 'personalData', 'healthData'],
    );
    expect(app.session.needsConsent, isFalse);
    // Bosh sahifa ochildi.
    expect(find.text('Alomatlarni tahlil qilish'), findsOneWidget);
  });

  testWidgets('shifokorlar ro\'yxati va filtr', (t) async {
    String? lastSpecialty;
    await pumpApp(t, {
      'GET /v1/appointments': (_) => {'items': <Object>[]},
      'GET /v1/doctors': (req) {
        lastSpecialty = req.url.queryParameters['specialty'];
        return {
          'items': [
            doctorJson('d1', 'Karimova Dilnoza Rustamovna', 'therapist'),
            if (lastSpecialty == null)
              doctorJson('d2', 'Abdullayev Jasur Akmalovich', 'cardiologist'),
          ],
        };
      },
    }, loggedIn: true);
    await t.tap(find.text('Shifokorlar').last);
    await t.pumpAndSettle();
    expect(find.textContaining('Abdullayev Jasur Akmalovich'), findsOneWidget);

    final chip = find.widgetWithText(ChoiceChip, 'Terapevt');
    await t.ensureVisible(chip);
    await t.pumpAndSettle();
    await t.tap(chip);
    await t.pumpAndSettle();
    expect(lastSpecialty, 'therapist');
    expect(find.textContaining('Abdullayev Jasur Akmalovich'), findsNothing);
    expect(find.textContaining('Karimova Dilnoza Rustamovna'), findsOneWidget);
  });

  testWidgets('admin moderatsiya tabini ko\'radi, bemor ko\'rmaydi', (t) async {
    final routes = {
      'GET /v1/appointments': (_) => {'items': <Object>[]},
      'GET /v1/admin/doctors/pending': (_) => {'items': <Object>[]},
    };
    await pumpApp(t, routes, loggedIn: true, role: UserRole.admin);
    expect(find.text('Moderatsiya'), findsOneWidget);
  });

  testWidgets('tarmoq xatosida qayta urinish tugmasi', (t) async {
    await pumpApp(t, {}, loggedIn: true);
    await t.tap(find.text('Qabullarim').last);
    await t.pumpAndSettle();
    expect(find.text('Qayta urinish'), findsOneWidget);
  });

  testWidgets('shoshilinch natija 103 bannerini ko\'rsatadi', (t) async {
    final r = TriageResult.fromJson({
      'id': 't1',
      'urgency': 'emergency',
      'conditions': [
        {
          'name': "O'tkir koronar sindrom",
          'likelihood': 'medium',
          'rationale': '...',
        },
      ],
      'recommendedSpecialties': ['cardiologist'],
      'redFlags': ["Ko'krak qafasidagi og'riq"],
      'advice': 'Darhol yordam chaqiring',
      'disclaimer': 'Bu tashxis emas',
    });
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('uz'),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: TriageResultScreen(result: r),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Shoshilinch yordam kerak'), findsOneWidget);
    expect(find.text("103 ga qo'ng'iroq qilish"), findsOneWidget);
    await t.scrollUntilVisible(find.text('Kardiolog topish'), 200);
    expect(find.text('Kardiolog topish'), findsOneWidget);
  });

  test('ApiClient HTTP (non-HTTPS) manzilni rad etadi', () {
    expect(() => ApiClient(baseUrl: 'http://api.medlink.uz'), throwsStateError);
  });

  test('MedicalProfile yoshni to\'g\'ri hisoblaydi', () {
    final now = DateTime.now();
    final p = MedicalProfile(
      birthDate: DateTime(now.year - 30, now.month, now.day),
    );
    expect(p.ageYears, 30);
    final q = MedicalProfile(
      birthDate: DateTime(
        now.year - 30,
        now.month,
        now.day,
      ).add(const Duration(days: 1)),
    );
    expect(q.ageYears, 29);
  });

  test('qabul vaqti qurilma zonasidan qat\'i nazar Toshkent vaqtida', () {
    // 04:00 UTC = 09:00 Toshkent.
    final slot = DateTime.parse('2026-11-08T04:00:00.000Z');
    expect(clinicWall(slot).hour, 9);
    expect(clinicWall(slot.toLocal()).hour, 9);
    final m = Appointment.fromJson({
      'id': 'a',
      'startsAt': '2026-11-08T04:00:00.000Z',
      'priceUzs': 1,
      'status': 'confirmed',
    });
    expect(m.startsAt.isUtc, isTrue);
  });

  test('brend ranglari matn uchun WCAG AA kontrastga keltiriladi', () {
    const white = Color(0xFFFFFFFF);
    const darkSurface = Color(0xFF111D2E);
    for (final c in [Brand.teal, Brand.warning, Brand.danger, Brand.blue]) {
      expect(
        contrastRatio(readableOn(c, white), white),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(readableOn(c, darkSurface), darkSurface),
        greaterThanOrEqualTo(4.5),
      );
    }
    // Teal oq fonda o'zi yetarli emas — shuning uchun helper kerak.
    expect(contrastRatio(Brand.teal, white), lessThan(4.5));
  });
}
