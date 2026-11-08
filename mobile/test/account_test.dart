import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlink/core/legal_links.dart';
import 'package:medlink/features/appointments/appointment_detail_screen.dart';
import 'package:medlink/features/profile/profile_screen.dart';
import 'package:medlink/models/models.dart';

import 'helpers.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('qabul vaqtini ko\'chirish', () {
    // Toshkent 10:00 (UTC 05:00), 3 kundan keyin.
    final now = DateTime.now().toUtc();
    final day = DateTime.utc(now.year, now.month, now.day + 3, 5);

    testWidgets('bo\'sh vaqt tanlanadi va serverga yuboriladi', (t) async {
      var current = {
        ...appointmentJson(startsAt: day, myRole: 'patient'),
        'reschedulesLeft': 2,
      };
      String? sentStartsAt;
      await pumpScreen(
        t,
        {
          'GET /v1/appointments/a1': (_) => current,
          'GET /v1/doctors/d1/slots': (_) => {
            'items': [
              day.toIso8601String(), // joriy vaqt — ko'rsatilmaydi
              day.add(const Duration(hours: 1)).toIso8601String(),
              day.add(const Duration(hours: 2)).toIso8601String(),
            ],
          },
          'POST /v1/appointments/a1/reschedule': (req) {
            sentStartsAt = (jsonDecode(req.body) as Map)['startsAt'] as String;
            current = {
              ...current,
              'startsAt': sentStartsAt,
              'reschedulesLeft': 1,
            };
            return current;
          },
        },
        AppointmentDetailScreen(appointment: Appointment.fromJson(current)),
        height: 5000,
      );

      await t.tap(find.text("Vaqtini o'zgartirish"));
      await t.pumpAndSettle();
      expect(find.text('Yangi vaqtni tanlang'), findsOneWidget);
      expect(
        find.textContaining("Yana 2 marta ko'chirish mumkin"),
        findsOneWidget,
      );
      expect(find.widgetWithText(ChoiceChip, '10:00'), findsNothing);
      await t.tap(find.widgetWithText(ChoiceChip, '11:00'));
      await t.pump();
      await t.tap(find.widgetWithText(FilledButton, "Vaqtini o'zgartirish"));
      await t.pumpAndSettle();
      expect(find.textContaining('11:00 ga ko\'chirasizmi'), findsOneWidget);
      await t.tap(find.text("Vaqtini o'zgartirish").last);
      await t.pumpAndSettle();

      expect(DateTime.parse(sentStartsAt!), day.add(const Duration(hours: 1)));
      // Qabul sahifasiga qaytdik va yangi vaqt ko'rinadi.
      expect(find.text('Yangi vaqtni tanlang'), findsNothing);
      expect(find.textContaining('11:00'), findsWidgets);
    });

    testWidgets('24 soatdan kam qolganda yoki limit tugaganda tugma yo\'q', (
      t,
    ) async {
      for (final json in [
        {
          ...appointmentJson(
            startsAt: now.add(const Duration(hours: 5)),
            myRole: 'patient',
          ),
          'reschedulesLeft': 2,
        },
        {
          ...appointmentJson(startsAt: day, myRole: 'patient'),
          'reschedulesLeft': 0,
        },
        {
          ...appointmentJson(startsAt: day, myRole: 'doctor'),
          'reschedulesLeft': 2,
        },
      ]) {
        await pumpScreen(
          t,
          {'GET /v1/appointments/a1': (_) => json},
          AppointmentDetailScreen(appointment: Appointment.fromJson(json)),
          height: 5000,
        );
        await t.pumpAndSettle();
        expect(find.text("Vaqtini o'zgartirish"), findsNothing);
        await t.pumpWidget(const SizedBox());
      }
    });
  });

  testWidgets('hisobni o\'chirish: ikki marta tasdiq, keyin chiqish', (
    t,
  ) async {
    var deleted = false;
    final repo = await pumpScreen(
      t,
      {
        'DELETE /v1/me': (_) {
          deleted = true;
          return {'deleted': true, 'refunds': 0};
        },
      },
      const ProfileScreen(),
      height: 6000,
    );
    await t.pumpAndSettle();

    expect(find.text('Maxfiylik siyosati'), findsOneWidget);
    expect(find.text('Foydalanish shartlari'), findsOneWidget);

    await t.tap(find.text("Hisobni o'chirish"));
    await t.pumpAndSettle();
    expect(find.textContaining('ortga qaytarib bo\'lmaydi'), findsOneWidget);
    // Birinchi oynada bekor qilish — hech narsa o'chmaydi.
    await t.tap(find.text('Bekor qilish').last);
    await t.pumpAndSettle();
    expect(deleted, isFalse);

    await t.tap(find.text("Hisobni o'chirish"));
    await t.pumpAndSettle();
    await t.tap(find.text('Davom etish'));
    await t.pumpAndSettle();
    expect(find.textContaining('Haqiqatan ham'), findsOneWidget);
    await t.tap(find.text("O'chirish").last);
    await t.pumpAndSettle();
    expect(deleted, isTrue);
    expect(repo.api.token, isNull); // tizimdan chiqildi
  });

  test('huquqiy hujjat havolasi ilova tilida', () {
    final u = legalUri('privacy', 'ru');
    expect(u.path, '/legal/privacy');
    expect(u.queryParameters['lang'], 'ru');
  });
}
