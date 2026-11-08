import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlink/features/admin/admin_doctor_screen.dart';
import 'package:medlink/features/admin/admin_tabs.dart';

import 'helpers.dart';

void main() {
  final now = DateTime.now().toUtc();

  testWidgets('foydalanuvchini sabab bilan bloklash', (t) async {
    var blocked = false;
    Map<String, dynamic>? sent;
    Map<String, dynamic> user() => {
      'id': 'u1234567890',
      'role': 'patient',
      'phone': '+99890***4567',
      'createdAt': now.toIso8601String(),
      'blocked': blocked,
      'blockReason': blocked ? 'Soxta bronlar' : null,
      'appointments': 3,
      'doctorId': null,
    };
    await pumpScreen(t, {
      'GET /v1/admin/users': (_) => {
        'total': 1,
        'items': [user()],
      },
      'POST /v1/admin/users/u1234567890/block': (req) {
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        blocked = sent!['blocked'] as bool;
        return user();
      },
    }, const Scaffold(body: AdminUsersTab()));
    await t.pumpAndSettle();

    expect(find.text('+99890***4567'), findsOneWidget);
    expect(find.textContaining('Qabullar: 3'), findsOneWidget);
    await t.tap(find.widgetWithText(OutlinedButton, 'Bloklash'));
    await t.pumpAndSettle();
    expect(find.textContaining('kira olmaydi'), findsOneWidget);
    // Sababsiz tasdiqlab bo'lmaydi.
    final confirm = find.widgetWithText(FilledButton, 'Bloklash');
    expect(t.widget<FilledButton>(confirm).onPressed, isNull);
    await t.enterText(find.byType(TextField).last, 'Soxta bronlar');
    await t.pump();
    await t.tap(confirm);
    await t.pumpAndSettle();
    expect(sent, {'blocked': true, 'reason': 'Soxta bronlar'});
    expect(find.text('Bloklangan'), findsWidgets);
    expect(find.text('Sabab: Soxta bronlar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Blokdan chiqarish'), findsOne);
  });

  testWidgets('shifokorni to\'xtatish va sharhni yashirish', (t) async {
    var status = 'approved';
    var hidden = false;
    final calls = <String, Object?>{};
    Map<String, dynamic> doctor() => {
      ...doctorJson('d1', 'Karimova Dilnoza Rustamovna', 'therapist'),
      'experienceYears': 12,
      'city': 'Toshkent',
      'status': status,
      'moderationNote': status == 'suspended' ? 'Litsenziya tugagan' : null,
      'licenseNumber': 'LIC-77',
      'documentRefs': ['https://files.example/diplom.pdf'],
      'stats': {
        'upcoming': 2,
        'today': 0,
        'completed30d': 9,
        'earnings30dUzs': 1350000,
        'awaitingConclusion': 0,
        'rating': 4.5,
        'reviewCount': 2,
      },
      'reviews': [
        {
          'appointmentId': 'a1',
          'rating': 1,
          'comment': 'Haqoratli matn',
          'authorName': 'Ali',
          'at': now.toIso8601String(),
          'hidden': hidden,
          'hiddenReason': hidden ? 'Haqorat' : null,
        },
      ],
    };
    await pumpScreen(
      t,
      {
        'GET /v1/admin/doctors/d1': (_) => doctor(),
        'POST /v1/admin/doctors/d1/moderate': (req) {
          final j = jsonDecode(req.body) as Map;
          calls['moderate'] = j;
          status = j['decision'] as String;
          return {'id': 'd1', 'status': status};
        },
        'POST /v1/admin/reviews/a1/hide': (req) {
          final j = jsonDecode(req.body) as Map;
          calls['hide'] = j;
          hidden = j['hidden'] as bool;
          return {'hidden': hidden};
        },
      },
      const AdminDoctorScreen(doctorId: 'd1'),
      height: 5000,
    );
    await t.pumpAndSettle();
    expect(find.textContaining('LIC-77'), findsOneWidget);
    expect(find.text('9'), findsOneWidget); // 30 kunda yakunlangan

    // Sharhni yashirish.
    await t.tap(find.widgetWithText(TextButton, 'Yashirish'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, 'Haqorat');
    await t.pump();
    await t.tap(find.widgetWithText(FilledButton, 'Yashirish'));
    await t.pumpAndSettle();
    expect(calls['hide'], {'hidden': true, 'reason': 'Haqorat'});
    expect(find.text('Yashirilgan: Haqorat'), findsOneWidget);

    // To'xtatish: kelgusi qabullar soni ogohlantirishda.
    await t.tap(find.text("Profilni to'xtatish"));
    await t.pumpAndSettle();
    expect(find.textContaining('(2 ta)'), findsOneWidget);
    await t.enterText(find.byType(TextField).last, 'Litsenziya tugagan');
    await t.pump();
    await t.tap(find.widgetWithText(FilledButton, "Profilni to'xtatish"));
    await t.pumpAndSettle();
    expect(calls['moderate'], {
      'decision': 'suspended',
      'note': 'Litsenziya tugagan',
    });
    expect(find.text("To'xtatilgan"), findsOneWidget);
    expect(find.text('Profilni tiklash'), findsOneWidget);
  });

  testWidgets('to\'lovlar va audit jurnali', (t) async {
    await pumpScreen(t, {
      'GET /v1/admin/payments': (req) => {
        'total': 1,
        'sumPaidUzs': 150000,
        'items': [
          {
            'id': 'o1',
            'appointmentId': 'a1',
            'amountUzs': 150000,
            'provider': req.url.queryParameters['provider'] ?? 'payme',
            'status': 'paid',
            'refundStatus': 'none',
            'createdAt': now.toIso8601String(),
            'providerTxnId': 'pm-1',
          },
        ],
      },
    }, const Scaffold(body: AdminPaymentsTab()));
    await t.pumpAndSettle();
    expect(find.textContaining("Jami to'langan"), findsOneWidget);
    expect(find.textContaining('Payme'), findsWidgets);
    await t.dragUntilVisible(
      find.widgetWithText(ChoiceChip, 'Apple Pay'),
      find.byType(ListView).first,
      const Offset(-150, 0),
    );
    await t.ensureVisible(find.widgetWithText(ChoiceChip, 'Apple Pay'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(ChoiceChip, 'Apple Pay'));
    await t.pumpAndSettle();
    expect(find.textContaining('Apple Pay ·'), findsOneWidget);

    await pumpScreen(t, {
      'GET /v1/admin/audit': (req) => {
        'items': [
          {
            'actorId': 'admin-123456789',
            'action': req.url.queryParameters['action'] == 'user.'
                ? 'user.block'
                : 'patient.read',
            'resource': 'user',
            'resourceId': 'u1234567890',
            'outcome': 'success',
            'at': now.toIso8601String(),
          },
        ],
      },
    }, const Scaffold(body: AdminAuditTab()));
    await t.pumpAndSettle();
    expect(find.text('patient.read'), findsOneWidget);
    await t.tap(find.widgetWithText(ChoiceChip, 'Foydalanuvchilar'));
    await t.pumpAndSettle();
    expect(find.text('user.block'), findsOneWidget);
    expect(find.textContaining('Kim: admin-12'), findsOneWidget);
  });
}
