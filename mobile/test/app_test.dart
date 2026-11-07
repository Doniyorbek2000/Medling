import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medlink/app.dart';
import 'package:medlink/core/api_client.dart';
import 'package:medlink/core/session.dart';
import 'package:medlink/features/triage/triage_result_screen.dart';
import 'package:medlink/models/models.dart';
import 'package:provider/provider.dart';

const _scopes = [
  ('terms', true),
  ('personalData', true),
  ('healthData', true),
  ('aiProcessing', false),
  ('crossBorderTransfer', false),
  ('marketing', false),
];

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('kirish ekrani logotip va telefon maydoni bilan', (t) async {
    final session = Session(
      ApiClient(client: MockClient((_) async => http.Response('{}', 200))),
    );
    await session.restore();
    await t.pumpWidget(
      ChangeNotifierProvider.value(value: session, child: const MedLinkApp()),
    );
    await t.pumpAndSettle();
    expect(find.text('SMS kod olish'), findsOneWidget);
    expect(find.text('+998 '), findsOneWidget);
  });

  testWidgets('majburiy rozilik belgilanmaguncha davom etib bo\'lmaydi', (
    t,
  ) async {
    Map<String, dynamic>? posted;
    final api = ApiClient(
      client: MockClient((req) async {
        if (req.url.path == '/v1/consents' && req.method == 'GET') {
          return http.Response(
            jsonEncode({
              'documents': [
                for (final (s, r) in _scopes)
                  {
                    'scope': s,
                    'required': r,
                    'version': '2026-11-01',
                    'granted': false,
                  },
              ],
            }),
            200,
          );
        }
        if (req.url.path == '/v1/consents' && req.method == 'POST') {
          posted = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'missingConsents': [
                'aiProcessing',
                'crossBorderTransfer',
                'marketing',
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      }),
    );
    final session = Session(api)
      ..token = 'test'
      ..loading = false
      ..missingConsents = ['terms', 'personalData', 'healthData'];
    api.token = 'test';
    t.view.physicalSize = const Size(1200, 4000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      ChangeNotifierProvider.value(value: session, child: const MedLinkApp()),
    );
    await t.pumpAndSettle();

    final button = find.widgetWithText(FilledButton, 'Roziman, davom etish');
    expect(t.widget<FilledButton>(button).onPressed, isNull);

    // Hech bir band oldindan belgilanmagan.
    final boxes = find.byType(Checkbox);
    expect(boxes, findsNWidgets(6));
    for (final b in t.widgetList<Checkbox>(boxes)) {
      expect(b.value, isFalse);
    }

    // Faqat majburiy 3 tasini belgilaymiz.
    for (var i = 0; i < 3; i++) {
      await t.tap(boxes.at(i));
    }
    await t.pump();
    expect(t.widget<FilledButton>(button).onPressed, isNotNull);

    await t.ensureVisible(button);
    await t.tap(button);
    await t.pumpAndSettle();

    final decisions = (posted!['decisions'] as List).cast<Map>();
    expect(
      decisions.where((d) => d['granted'] == true).map((d) => d['scope']),
      ['terms', 'personalData', 'healthData'],
    );
    expect(session.needsConsent, isFalse);
  });

  testWidgets('shoshilinch natija 103 bannerini ko\'rsatadi', (t) async {
    final r = TriageResult.fromJson({
      'id': 't1',
      'urgency': 'emergency',
      'conditions': [
        {
          'name': 'O\'tkir koronar sindrom',
          'likelihood': 'medium',
          'rationale': '...',
        },
      ],
      'recommendedSpecialties': ['cardiologist'],
      'redFlags': ['Ko\'krak qafasidagi og\'riq'],
      'advice': 'Darhol yordam chaqiring',
      'disclaimer': 'Bu tashxis emas',
    });
    await t.pumpWidget(MaterialApp(home: TriageResultScreen(result: r)));
    expect(find.text('Shoshilinch yordam kerak'), findsOneWidget);
    expect(find.text('103 ga qo\'ng\'iroq qilish'), findsOneWidget);
    expect(find.text('Ko\'krak qafasidagi og\'riq'), findsOneWidget);
  });

  test('ApiClient HTTP (non-HTTPS) manzilni rad etadi', () {
    expect(() => ApiClient(baseUrl: 'http://api.medlink.uz'), throwsStateError);
  });
}
