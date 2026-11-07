import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medlink/core/api_client.dart';
import 'package:medlink/core/notifications.dart';
import 'package:medlink/core/notifications_controller.dart';
import 'package:medlink/core/session.dart';
import 'package:medlink/models/models.dart';

Appointment appt(String id, String status, DateTime startsAtUtc) =>
    Appointment.fromJson({
      'id': id,
      'startsAt': startsAtUtc.toIso8601String(),
      'priceUzs': 1,
      'status': status,
    });

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('Mahalliy eslatmalar', () {
    final now = DateTime.utc(2026, 11, 7, 10);

    test(
      'faqat tasdiqlangan va kelgusi qabullar uchun, 24 soat va 1 soat oldin',
      () {
        final plan = NotificationsService.plannedReminders([
          appt('a', 'confirmed', now.add(const Duration(days: 2))),
          appt('b', 'confirmed', now.add(const Duration(hours: 5))),
          appt('c', 'awaitingPayment', now.add(const Duration(days: 2))),
          appt('d', 'cancelled', now.add(const Duration(days: 2))),
          appt('e', 'confirmed', now.subtract(const Duration(hours: 1))),
        ], now);
        // a: ikkalasi; b: faqat 1 soat oldin (24 soat oldin o'tib ketgan).
        expect(plan.map((r) => (r.appointment.id, r.lead.inHours)), [
          ('a', 24),
          ('a', 1),
          ('b', 1),
        ]);
        expect(plan.first.at, now.add(const Duration(days: 1)));
        // ID'lar noyob.
        expect(plan.map((r) => r.id).toSet(), hasLength(3));
      },
    );

    test('ID ishga tushirishlar orasida barqaror (FNV-1a)', () {
      expect(
        NotificationsService.stableId('abc'),
        NotificationsService.stableId('abc'),
      );
      expect(NotificationsService.stableId('abc'), 0x1a47e90b & 0x3fffffff);
      expect(
        NotificationsService.stableId('abc'),
        isNot(NotificationsService.stableId('abd')),
      );
    });

    test('eslatma vaqti Toshkent vaqtida', () {
      expect(
        NotificationsController.reminderTime(DateTime.utc(2026, 11, 8, 4)),
        '09:00',
      );
    });
  });

  test('bildirishnoma ma\'lumotidan yo\'nalish', () {
    final t = NotificationTap.fromData({
      'type': 'appointment',
      'appointmentId': 'a1',
      'kind': 'x',
    });
    expect(t?.type, 'appointment');
    expect(t?.appointmentId, 'a1');
    expect(NotificationTap.fromData({'kind': 'x'}), isNull);
  });

  test('Firebase sozlanmagan bo\'lsa push o\'chiq (build buzilmaydi)', () {
    expect(FirebaseConfig.current, isNull);
    expect(NotificationsService().pushAvailable, isFalse);
  });

  test(
    'chiqish: qurilma o\'chiriladi, 401 cheksiz takrorlanishga olib kelmaydi',
    () async {
      var calls = 0;
      final api = ApiClient(
        client: MockClient((req) async {
          calls++;
          return http.Response('{"error":{"code":"unauthorized"}}', 401);
        }),
      );
      final session = Session(api)
        ..token = 't'
        ..loading = false;
      api.token = 't';
      var before = 0;
      session.beforeLogout = () async {
        before++;
        await api.post('/v1/me/devices/remove', {'token': 'fid'});
      };
      await session.logout();
      expect(session.loggedIn, isFalse);
      expect(before, 1);
      expect(calls, 1);
    },
  );
}
