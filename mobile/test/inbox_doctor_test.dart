import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlink/features/doctor_portal/doctor_schedule_screen.dart';
import 'package:medlink/features/doctor_portal/doctor_settings_screen.dart';
import 'package:medlink/features/notifications/notifications_screen.dart';
import 'package:medlink/features/payments/my_payments_screen.dart';

import 'helpers.dart';

void main() {
  final now = DateTime.now().toUtc();

  testWidgets('bildirishnomalar: o\'qilmaganlar belgisi va hammasini o\'qish', (
    t,
  ) async {
    var unread = 2;
    final marked = <Object?>[];
    Map<String, dynamic> list() => {
      'unread': unread,
      'items': [
        for (final (id, kind, title) in [
          ('n2', 'refundCompleted', "To'lov qaytarildi"),
          ('n1', 'paymentConfirmed', 'Qabul tasdiqlandi'),
        ])
          {
            'id': id,
            'kind': kind,
            'title': title,
            'body': 'Matn',
            'data': {'type': 'appointment', 'appointmentId': 'a1'},
            'at': now.toIso8601String(),
            'read': unread == 0,
          },
      ],
    };
    await pumpScreen(t, {
      'GET /v1/me/notifications': (_) => list(),
      'POST /v1/me/notifications/read': (req) {
        marked.add(jsonDecode(req.body));
        unread = 0;
        return {'marked': 2, 'unread': 0};
      },
    }, const Scaffold(body: Center(child: NotificationBell())));
    await t.pumpAndSettle();
    expect(find.text('2'), findsOneWidget); // belgi

    await t.tap(find.byType(NotificationBell));
    await t.pumpAndSettle();
    expect(find.text("To'lov qaytarildi"), findsOneWidget);
    expect(find.text('Qabul tasdiqlandi'), findsOneWidget);
    await t.tap(find.byTooltip("Hammasini o'qilgan deb belgilash"));
    await t.pumpAndSettle();
    expect(marked, [<String, Object?>{}]);
    expect(find.byTooltip("Hammasini o'qilgan deb belgilash"), findsNothing);

    t.state<NavigatorState>(find.byType(Navigator)).pop();
    await t.pumpAndSettle();
    expect(find.text('2'), findsNothing); // belgi yangilandi
  });

  testWidgets('to\'lovlarim: summa, usul, qaytarish holati', (t) async {
    await pumpScreen(t, {
      'GET /v1/me/payments': (_) => {
        'items': [
          {
            'id': 'o1',
            'appointmentId': 'a1',
            'amountUzs': 150000,
            'provider': 'applePay',
            'status': 'refunded',
            'refundStatus': 'refunded',
            'paidAt': now.toIso8601String(),
            'providerTxnId': 'pi_1',
            'doctorName': 'Karimova Dilnoza Rustamovna',
            'appointmentStartsAt': now.toIso8601String(),
          },
        ],
      },
    }, const MyPaymentsScreen());
    await t.pumpAndSettle();
    expect(find.text('150 000 so\'m'), findsOneWidget);
    expect(find.textContaining('Apple Pay'), findsOneWidget);
    expect(find.textContaining('Karimova'), findsOneWidget);
    expect(find.text('Qaytarilgan'), findsOneWidget);
  });

  testWidgets('shifokor: ish stoli ko\'rsatkichlari', (t) async {
    await pumpScreen(t, {
      'GET /v1/doctor/stats': (_) => {
        'today': 3,
        'upcoming': 7,
        'completed30d': 20,
        'earnings30dUzs': 2400000,
        'awaitingConclusion': 1,
        'rating': 4.8,
        'reviewCount': 15,
      },
      'GET /v1/doctor/appointments': (_) => {'items': <Object>[]},
    }, const DoctorScheduleScreen());
    await t.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Xulosa kutmoqda'), findsOneWidget);
    await t.dragUntilVisible(
      find.textContaining('400\u00a0000'),
      find.byType(ListView).first,
      const Offset(-150, 0),
    );
  });

  testWidgets('shifokor: dam olish kunini olib tashlash va saqlash', (t) async {
    Map<String, dynamic>? saved;
    final settings = {
      'clinicEnabled': true,
      'priceUzs': 150000,
      'onlineEnabled': false,
      'onlinePriceUzs': 0,
      'workDays': [1, 2, 3, 4, 5],
      'startHour': 9,
      'endHour': 18,
      'daysOff': ['2030-01-02', '2030-01-03'],
    };
    await pumpScreen(
      t,
      {
        'GET /v1/doctor/settings': (_) => settings,
        'PUT /v1/doctor/settings': (req) {
          saved = jsonDecode(req.body) as Map<String, dynamic>;
          return saved;
        },
      },
      const DoctorSettingsScreen(),
      height: 6000,
    );
    await t.pumpAndSettle();
    expect(find.text('Dam olish kunlari'), findsOneWidget);
    expect(find.byType(InputChip), findsNWidgets(2));
    await t.tap(
      find.descendant(
        of: find.byType(InputChip).first,
        matching: find.byType(Icon),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byType(InputChip), findsOneWidget);
    await t.tap(find.text('Saqlash'));
    await t.pumpAndSettle();
    expect(saved!['daysOff'], ['2030-01-03']);
  });
}
