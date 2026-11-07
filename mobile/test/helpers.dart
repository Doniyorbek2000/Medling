import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medlink/core/l10n.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medlink/app.dart';
import 'package:medlink/core/api_client.dart';
import 'package:medlink/core/app_lock.dart';
import 'package:medlink/core/deep_links.dart';
import 'package:medlink/core/session.dart';
import 'package:medlink/core/settings.dart';
import 'package:medlink/data/repository.dart';
import 'package:medlink/main.dart';

/// Soxta backend: yo'l -> javob.
typedef Routes = Map<String, Object? Function(http.Request req)>;

ApiClient fakeApi(Routes routes) => ApiClient(
  client: MockClient((req) async {
    final key = '${req.method} ${req.url.path}';
    final handler = routes[key];
    if (handler == null) {
      return http.Response(
        jsonEncode({
          'error': {'code': 'not_found'},
        }),
        404,
      );
    }
    final body = handler(req);
    if (body is http.Response) return body;
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }),
);

class FakeLock extends AppLock {
  @override
  Future<bool> get available async => false;
  @override
  Future<bool> unlock(String reason) async => true;
}

/// To'liq ilovani soxta API bilan ishga tushiradi.
Future<({Session session, AppSettings settings})> pumpApp(
  WidgetTester t,
  Routes routes, {
  bool loggedIn = false,
  bool onboardingDone = true,
  List<String> missingConsents = const [],
  UserRole role = UserRole.patient,
  Locale locale = const Locale('uz'),
  double height = 2532,
}) async {
  t.view.physicalSize = Size(1170, height);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);

  final api = fakeApi(routes);
  final settings = AppSettings()
    ..onboardingDone = onboardingDone
    ..locale = locale;
  final session = Session(api)..loading = false;
  if (loggedIn) {
    session
      ..token = 'test'
      ..role = role
      ..missingConsents = missingConsents;
    api.token = 'test';
  }
  await t.pumpWidget(
    MedLinkProviders(
      settings: settings,
      session: session,
      repository: MedLinkRepository(api),
      deepLinks: DeepLinks(),
      appLock: FakeLock(),
      child: const MedLinkApp(),
    ),
  );
  await t.pumpAndSettle();
  return (session: session, settings: settings);
}

Map<String, dynamic> doctorJson(String id, String name, String spec) => {
  'id': id,
  'fullName': name,
  'specialty': spec,
  'experienceYears': 12,
  'clinic': 'Shifo Med',
  'city': 'Toshkent',
  'priceUzs': 150000,
  'bio': '',
  'rating': 4.8,
  'reviewCount': 124,
  'verified': true,
};

/// Bitta ekranni soxta API va kerakli provayderlar bilan ochadi.
Future<MedLinkRepository> pumpScreen(
  WidgetTester t,
  Routes routes,
  Widget screen, {
  double height = 2532,
}) async {
  t.view.physicalSize = Size(1170, height);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final api = fakeApi(routes)..token = 'test';
  final repo = MedLinkRepository(api);
  final settings = AppSettings()..locale = const Locale('uz');
  await t.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: Session(api)..loading = false),
        Provider.value(value: repo),
        Provider.value(value: DeepLinks()),
        Provider<AppLock>.value(value: FakeLock()),
      ],
      child: MaterialApp(
        locale: const Locale('uz'),
        supportedLocales: AppSettings.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: screen,
      ),
    ),
  );
  await t.pumpAndSettle();
  return repo;
}

Map<String, dynamic> appointmentJson({
  String id = 'a1',
  String status = 'confirmed',
  String type = 'online',
  required DateTime startsAt,
  String? myRole,
  Map<String, dynamic>? conclusion,
}) => {
  'id': id,
  'doctor': {
    ...doctorJson('d1', 'Karimova Dilnoza Rustamovna', 'therapist'),
    'onlineEnabled': true,
    'onlinePriceUzs': 120000,
  },
  'startsAt': startsAt.toUtc().toIso8601String(),
  'priceUzs': 120000,
  'status': status,
  'reason': 'Bosh og\'rig\'i',
  'type': type,
  'myRole': ?myRole,
  'videoAvailable': true,
  'conclusion': ?conclusion,
};
