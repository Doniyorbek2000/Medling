import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlink/features/admin/admin_screen.dart';
import 'package:medlink/features/appointments/appointment_detail_screen.dart';
import 'package:medlink/models/models.dart';

import 'helpers.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('admin: statistika va qaytarishni tasdiqlash', (t) async {
    var completed = <String>[];
    await pumpScreen(t, {
      'GET /v1/admin/stats': (_) => {
        'users': 120,
        'doctorsApproved': 14,
        'doctorsPending': 3,
        'appointmentsByStatus': {
          'confirmed': 20,
          'awaitingPayment': 2,
          'completed': 80,
          'cancelled': 5,
        },
        'appointmentsToday': 7,
        'onlineShare': 35,
        'revenue30dUzs': 15000000,
        'refundsPending': 1,
        'refundsPendingUzs': 150000,
      },
      'GET /v1/admin/doctors/pending': (_) => {'items': <Object>[]},
      'GET /v1/admin/refunds': (_) => {
        'items': completed.isEmpty
            ? [
                {
                  'id': 'o1',
                  'appointmentId': 'a1',
                  'amountUzs': 150000,
                  'provider': 'payme',
                  'status': 'paid',
                  'refundStatus': 'requested',
                  'providerTxnId': 'pm-42',
                  'reason': 'doctor_cancelled',
                  'requestedAt': DateTime.now().toUtc().toIso8601String(),
                },
              ]
            : <Object>[],
      },
      'POST /v1/admin/refunds/o1/complete': (_) {
        completed = ['o1'];
        return {'id': 'o1', 'refundStatus': 'refunded'};
      },
    }, const AdminScreen());

    expect(find.text('120'), findsOneWidget);
    expect(find.text('35%'), findsOneWidget);
    expect(find.text('Bugungi qabullar'), findsOneWidget);

    await t.tap(find.text('Qaytarishlar'));
    await t.pumpAndSettle();
    expect(find.text('Shifokor bekor qildi'), findsOneWidget);
    expect(find.textContaining('pm-42'), findsOneWidget);
    await t.tap(find.widgetWithText(FilledButton, 'Qaytarildi deb belgilash'));
    await t.pumpAndSettle();
    // Tasdiqlash oynasi: provayder nomi bilan ko'rsatma.
    expect(find.textContaining('Payme kabinetida'), findsOneWidget);
    await t.tap(find.text('Qaytarildi deb belgilash').last);
    await t.pumpAndSettle();
    expect(completed, ['o1']);
    expect(find.text("Qaytariladigan to'lovlar yo'q"), findsOneWidget);
  });

  group('bekor qilish siyosati', () {
    Future<void> openCancel(
      WidgetTester t,
      DateTime startsAt,
      String role,
    ) async {
      final json = appointmentJson(
        startsAt: startsAt,
        myRole: role,
        type: 'clinic',
      );
      await pumpScreen(
        t,
        {'GET /v1/appointments/a1': (_) => json},
        AppointmentDetailScreen(appointment: Appointment.fromJson(json)),
        height: 5000,
      );
      await t.tap(find.text('Qabulni bekor qilish'));
      await t.pumpAndSettle();
    }

    testWidgets('24 soatdan ko\'p — pul qaytariladi', (t) async {
      await openCancel(
        t,
        DateTime.now().toUtc().add(const Duration(days: 3)),
        'patient',
      );
      expect(find.textContaining("to'liq qaytariladi"), findsOneWidget);
    });

    testWidgets('24 soatdan kam — qaytarilmaydi', (t) async {
      await openCancel(
        t,
        DateTime.now().toUtc().add(const Duration(hours: 5)),
        'patient',
      );
      expect(find.textContaining('qaytarilmaydi'), findsOneWidget);
    });

    testWidgets('shifokor bekor qilsa — bemorga qaytariladi', (t) async {
      await openCancel(
        t,
        DateTime.now().toUtc().add(const Duration(hours: 5)),
        'doctor',
      );
      expect(
        find.textContaining("Bemorga to'lov to'liq qaytariladi"),
        findsOneWidget,
      );
    });
  });
}
