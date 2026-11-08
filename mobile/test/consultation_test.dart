import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:medlink/features/appointments/appointment_detail_screen.dart';
import 'package:medlink/features/consultation/chat_screen.dart';
import 'package:medlink/features/consultation/conclusion_screen.dart';
import 'package:medlink/features/doctors/doctor_detail_screen.dart';
import 'package:medlink/models/models.dart';

import 'helpers.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('Video oynasi', () {
    final start = DateTime.utc(2026, 11, 8, 4);
    Appointment a({String type = 'online', String status = 'confirmed'}) =>
        Appointment.fromJson(
          appointmentJson(startsAt: start, type: type, status: status),
        );

    test('qabuldan 10 daqiqa oldin ochiladi, 60 daqiqadan keyin yopiladi', () {
      expect(
        a().videoOpenAt(start.subtract(const Duration(minutes: 11))),
        isFalse,
      );
      expect(
        a().videoOpenAt(start.subtract(const Duration(minutes: 10))),
        isTrue,
      );
      expect(a().videoOpenAt(start.add(const Duration(minutes: 59))), isTrue);
      expect(a().videoOpenAt(start.add(const Duration(minutes: 60))), isFalse);
    });

    test('klinika qabuli yoki to\'lanmagan qabul uchun video yo\'q', () {
      expect(a(type: 'clinic').videoOpenAt(start), isFalse);
      expect(a(status: 'awaitingPayment').videoOpenAt(start), isFalse);
    });
  });

  testWidgets('chat: xabarlar yuklanadi, yuboriladi', (t) async {
    final sent = <String>[];
    final now = DateTime.now().toUtc().toIso8601String();
    await pumpScreen(t, {
      'GET /v1/appointments/a1/messages': (req) => {
        'canWrite': true,
        'items': req.url.queryParameters['after'] == '0'
            ? [
                {
                  'id': 'm1',
                  'seq': 1,
                  'senderRole': 'doctor',
                  'mine': false,
                  'text': 'Salom! Qanday yordam bera olaman?',
                  'at': now,
                },
              ]
            : <Object>[],
      },
      'POST /v1/appointments/a1/messages': (req) {
        final text = (jsonDecode(req.body) as Map)['text'] as String;
        sent.add(text);
        return {
          'id': 'm2',
          'seq': 2,
          'senderRole': 'patient',
          'mine': true,
          'text': text,
          'at': now,
        };
      },
    }, const ChatScreen(appointmentId: 'a1', title: 'Karimova D.'));

    expect(find.text('Salom! Qanday yordam bera olaman?'), findsOneWidget);
    expect(find.text('Shifokor'), findsOneWidget); // jo'natuvchi roli
    await t.enterText(
      find.byType(TextField),
      'Boshim 3 kundan beri og\'riyapti',
    );
    await t.pump();
    await t.tap(find.byTooltip('Yuborish'));
    await t.pumpAndSettle();
    expect(sent, ['Boshim 3 kundan beri og\'riyapti']);
    expect(find.text('Boshim 3 kundan beri og\'riyapti'), findsOneWidget);
    // Polling taymerini to'xtatish uchun ekranni yopamiz.
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('chat yopilgan bo\'lsa yozib bo\'lmaydi', (t) async {
    await pumpScreen(t, {
      'GET /v1/appointments/a1/messages': (_) => {
        'canWrite': false,
        'items': <Object>[],
      },
    }, const ChatScreen(appointmentId: 'a1', title: 'X'));
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Chat yopilgan'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('bron: onlayn qabul tanlansa narx va tur yuboriladi', (t) async {
    Map<String, dynamic>? booked;
    final day = DateTime.now().toUtc().add(const Duration(days: 2));
    final slot = DateTime.utc(day.year, day.month, day.day, 5);
    await pumpScreen(
      t,
      {
        'GET /v1/doctors/d1/reviews': (_) => {'items': <Object>[]},
        'GET /v1/doctors/d1/slots': (_) => {
          'items': [slot.toIso8601String()],
        },
        'POST /v1/appointments': (req) {
          booked = jsonDecode(req.body) as Map<String, dynamic>;
          return appointmentJson(startsAt: slot, status: 'awaitingPayment');
        },
      },
      DoctorDetailScreen(
        doctor: Doctor.fromJson({
          ...doctorJson('d1', 'Karimova Dilnoza Rustamovna', 'therapist'),
          'onlineEnabled': true,
          'onlinePriceUzs': 120000,
        }),
      ),
      height: 5000,
    );
    expect(find.text('Klinikada'), findsOneWidget);
    await t.tap(find.text('Onlayn').last);
    await t.pumpAndSettle();
    await t.tap(find.text('10:00'));
    await t.pumpAndSettle();
    // Narx guruhlari bo'linmaydigan bo'shliq (U+00A0) bilan formatlanadi.
    expect(find.textContaining('120\u00a0000'), findsWidgets);
    await t.tap(find.textContaining('Yozilish'));
    await t.pumpAndSettle();
    expect(booked?['type'], 'online');
  });

  testWidgets(
    'shifokor: boshlangan qabulda xulosa yozish va bemor ma\'lumoti',
    (t) async {
      final started = DateTime.now().toUtc().subtract(
        const Duration(minutes: 5),
      );
      final json = appointmentJson(startsAt: started, myRole: 'doctor');
      await pumpScreen(
        t,
        {'GET /v1/appointments/a1': (_) => json},
        AppointmentDetailScreen(appointment: Appointment.fromJson(json)),
        height: 5000,
      );
      expect(find.text('Xulosa yozish'), findsOneWidget);
      expect(find.text("Bemor ma'lumotlari"), findsOneWidget);
      expect(find.text("Video qo'ng'iroqqa kirish"), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      // Shifokorga "baholash" yoki "to'lash" ko'rinmaydi.
      expect(find.text('Shifokorni baholash'), findsNothing);
    },
  );

  testWidgets('bemor: xulosa va retsept ko\'rinadi', (t) async {
    final json = appointmentJson(
      startsAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      status: 'completed',
      myRole: 'patient',
      conclusion: {
        'diagnosis': 'Taranglik tipidagi bosh og\'rig\'i',
        'recommendations': 'Uyqu rejimi, suv ichish.',
        'prescriptions': [
          {
            'drug': 'Ibuprofen',
            'dose': '200 mg',
            'frequency': 'Og\'riqda, kuniga 3 martagacha',
            'durationDays': 5,
            'notes': '',
          },
        ],
        'followUpDays': 14,
        'at': DateTime.now().toUtc().toIso8601String(),
      },
    );
    await pumpScreen(
      t,
      {'GET /v1/appointments/a1': (_) => json},
      AppointmentDetailScreen(appointment: Appointment.fromJson(json)),
      height: 5000,
    );
    expect(find.text('Shifokor xulosasi'), findsOneWidget);
    expect(find.text('Taranglik tipidagi bosh og\'rig\'i'), findsOneWidget);
    expect(find.text('Ibuprofen · 200 mg'), findsOneWidget);
    expect(find.textContaining('14 kundan keyin'), findsOneWidget);
    expect(find.text('Shifokorni baholash'), findsOneWidget);
    expect(find.text("Video qo'ng'iroqqa kirish"), findsNothing);
  });

  testWidgets('xulosa: tashxissiz saqlab bo\'lmaydi, retsept yuboriladi', (
    t,
  ) async {
    Map<String, dynamic>? saved;
    final json = appointmentJson(
      startsAt: DateTime.now().toUtc().subtract(const Duration(minutes: 20)),
      myRole: 'doctor',
    );
    await pumpScreen(
      t,
      {
        'PUT /v1/doctor/appointments/a1/conclusion': (req) {
          saved = jsonDecode(req.body) as Map<String, dynamic>;
          return {...json, 'status': 'completed'};
        },
      },
      ConclusionScreen(appointment: Appointment.fromJson(json)),
      height: 5000,
    );
    await t.tap(find.text('Xulosani saqlash').last);
    await t.pumpAndSettle();
    expect(find.text('Majburiy maydon'), findsOneWidget);
    expect(saved, isNull);

    await t.enterText(find.widgetWithText(TextFormField, 'Tashxis'), 'Migren');
    await t.tap(find.text("Dori qo'shish"));
    await t.pumpAndSettle();
    await t.enterText(
      find.widgetWithText(TextFormField, 'Dori nomi'),
      'Sumatriptan',
    );
    await t.enterText(find.widgetWithText(TextFormField, 'Doza'), '50 mg');
    await t.tap(find.text('Xulosani saqlash').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Saqlash').last); // tasdiqlash oynasi
    await t.pumpAndSettle();
    expect(saved?['diagnosis'], 'Migren');
    expect((saved?['prescriptions'] as List).single['drug'], 'Sumatriptan');
  });

  testWidgets('chat: rasm ilovasi ko\'rinadi va to\'liq ekranda ochiladi', (
    t,
  ) async {
    final png = base64.decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
    );
    var downloads = 0;
    await pumpScreen(t, {
      'GET /v1/appointments/a1/messages': (_) => {
        'canWrite': true,
        'items': [
          {
            'id': 'm1',
            'seq': 1,
            'senderRole': 'patient',
            'mine': true,
            'text': 'tahlil.jpg',
            'at': DateTime.now().toUtc().toIso8601String(),
            'attachment': {
              'id': 'f1',
              'name': 'tahlil.png',
              'mime': 'image/png',
              'size': png.length,
            },
          },
        ],
      },
      'GET /v1/appointments/a1/attachments/f1': (_) {
        downloads++;
        return http.Response.bytes(
          png,
          200,
          headers: {'content-type': 'image/png'},
        );
      },
    }, const ChatScreen(appointmentId: 'a1', title: 'X'));
    await t.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('tahlil.jpg'), findsNothing); // fayl nomi emas, rasm
    expect(find.byTooltip("Rasm qo'shish"), findsOneWidget);
    await t.tap(find.byType(Image));
    await t.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(downloads, 1); // qayta ochilganda keshdan
    await t.pumpWidget(const SizedBox());
  });
}
