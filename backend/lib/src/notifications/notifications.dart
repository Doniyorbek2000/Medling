import 'dart:convert';

import 'package:http/http.dart' as http;

import '../ai/medical_model.dart';
import '../persistence/changes.dart';

/// Push bildirishnoma turlari.
enum PushKind {
  paymentConfirmed,
  newPatient,
  appointmentCancelled,
  appointmentReminder,
  doctorApproved,
  doctorRejected,
  newMessage,
  consultationStarted,
  conclusionReady,
  refundCompleted,
  appointmentRescheduled,
}

class Device {
  Device({
    required this.userId,
    required this.token,
    required this.platform,
    required this.locale,
  });
  final String userId;

  /// Firebase Installation ID (FID) — ilova `onRegistered` dan oladi.
  final String token;
  final String platform; // android | ios
  final String locale; // uz | ru | en
  DateTime updatedAt = DateTime.now().toUtc();
}

/// Foydalanuvchi qurilmalari (FCM tokenlari). Bitta token faqat bitta
/// foydalanuvchiga tegishli bo'ladi — telefonda boshqa hisobga kirilsa, token
/// yangi egasiga o'tadi (oldingi egaga bildirishnoma bormaydi).
class DeviceRegistry {
  final _byToken = <String, Device>{};

  static const platforms = {'android', 'ios'};
  static const locales = {'uz', 'ru', 'en'};

  Device register({
    required String userId,
    required String token,
    required String platform,
    required String locale,
  }) {
    if (token.isEmpty || token.length > 4096 || !platforms.contains(platform)) {
      throw const FormatException('device');
    }
    final d = Device(
      userId: userId,
      token: token,
      platform: platform,
      locale: locales.contains(locale) ? locale : 'uz',
    );
    _byToken[token] = d;
    changes.save(
      'devices',
      token,
      () => (
        columns: {'user_id': d.userId},
        data: {'platform': d.platform, 'locale': d.locale},
      ),
    );
    return d;
  }

  void unregister(String userId, String token) {
    if (_byToken[token]?.userId == userId) removeToken(token);
  }

  void removeToken(String token) {
    _byToken.remove(token);
    changes.delete('devices', 'id', token);
  }

  void restore(List<Map<String, dynamic>> rows) {
    for (final r in rows) {
      final j = r['data'] as Map;
      _byToken[r['id'] as String] = Device(
        userId: r['user_id'] as String,
        token: r['id'] as String,
        platform: j['platform'] as String,
        locale: j['locale'] as String,
      );
    }
  }

  void removeUser(String userId) =>
      forUser(userId).map((d) => d.token).toList().forEach(removeToken);

  List<Device> forUser(String userId) =>
      _byToken.values.where((d) => d.userId == userId).toList();
}

class PushMessage {
  const PushMessage(this.title, this.body, this.data);
  final String title;
  final String body;

  /// Faqat identifikatorlar (masalan, appointmentId) — tibbiy mazmun yo'q.
  final Map<String, String> data;
}

/// Matnlar ataylab umumiy: qulf ekranida shifokor ismi, mutaxassisligi yoki
/// tashxis ko'rinmasligi kerak (masalan, "Psixiatr qabuli" — sog'liq haqidagi
/// ma'lumotni oshkor qiladi). Tafsilotlar faqat ilova ichida, autentifikatsiyadan
/// keyin ko'rsatiladi.
class PushTemplates {
  static const _t = <PushKind, Map<String, (String, String)>>{
    PushKind.paymentConfirmed: {
      'uz': ('Qabul tasdiqlandi', "To'lov qabul qilindi. Qabul {time} da."),
      'ru': ('Приём подтверждён', 'Оплата получена. Приём в {time}.'),
      'en': ('Visit confirmed', 'Payment received. Your visit is at {time}.'),
    },
    PushKind.newPatient: {
      'uz': ('Yangi bemor', 'Sizga {time} ga yangi bemor yozildi.'),
      'ru': ('Новый пациент', 'К вам записался пациент на {time}.'),
      'en': ('New patient', 'A patient booked a visit at {time}.'),
    },
    PushKind.appointmentCancelled: {
      'uz': ('Qabul bekor qilindi', '{time} dagi qabul bekor qilindi.'),
      'ru': ('Приём отменён', 'Приём в {time} отменён.'),
      'en': ('Visit cancelled', 'The visit at {time} was cancelled.'),
    },
    PushKind.appointmentRescheduled: {
      'uz': ("Qabul vaqti o'zgardi", "Qabul {time} ga ko'chirildi."),
      'ru': ('Время приёма изменено', 'Приём перенесён на {time}.'),
      'en': ('Visit rescheduled', 'The visit was moved to {time}.'),
    },
    PushKind.appointmentReminder: {
      'uz': ('Qabul eslatmasi', 'Qabulingiz soat {time} da. Kechikmang.'),
      'ru': ('Напоминание о приёме', 'Ваш приём в {time}. Не опаздывайте.'),
      'en': ('Visit reminder', 'Your visit is at {time}. Please be on time.'),
    },
    PushKind.newMessage: {
      'uz': ('Yangi xabar', 'Qabul chatida yangi xabar bor.'),
      'ru': ('Новое сообщение', 'В чате приёма новое сообщение.'),
      'en': ('New message', 'You have a new message in your visit chat.'),
    },
    PushKind.consultationStarted: {
      'uz': ('Shifokor kutmoqda', 'Onlayn qabul boshlandi. Ilovani oching.'),
      'ru': ('Врач ожидает', 'Онлайн-приём начался. Откройте приложение.'),
      'en': ('Your doctor is waiting', 'Your online visit has started.'),
    },
    PushKind.conclusionReady: {
      'uz': ('Shifokor xulosasi', 'Qabul xulosasi tayyor. Ilovada ko\'ring.'),
      'ru': ('Заключение врача', 'Заключение по приёму готово.'),
      'en': ('Doctor\'s summary', 'Your visit summary is ready in the app.'),
    },
    PushKind.refundCompleted: {
      'uz': (
        "To'lov qaytarildi",
        "Bekor qilingan qabul uchun to'lov qaytarildi.",
      ),
      'ru': ('Возврат выполнен', 'Оплата за отменённый приём возвращена.'),
      'en': (
        'Refund completed',
        'Your payment for the cancelled visit was refunded.',
      ),
    },
    PushKind.doctorApproved: {
      'uz': ('Ariza tasdiqlandi', 'Profilingiz endi bemorlarga ko\'rinadi.'),
      'ru': ('Заявка одобрена', 'Ваш профиль теперь виден пациентам.'),
      'en': (
        'Application approved',
        'Your profile is now visible to patients.',
      ),
    },
    PushKind.doctorRejected: {
      'uz': ('Ariza ko\'rib chiqildi', 'Natijani ilovada ko\'ring.'),
      'ru': ('Заявка рассмотрена', 'Результат смотрите в приложении.'),
      'en': ('Application reviewed', 'See the result in the app.'),
    },
  };

  /// Qabul vaqtlari Toshkent vaqtida (UTC+5).
  static String clinicTime(DateTime utc) {
    final w = utc.toUtc().add(const Duration(hours: 5));
    final hh = w.hour.toString().padLeft(2, '0');
    final mm = w.minute.toString().padLeft(2, '0');
    return '${w.day.toString().padLeft(2, '0')}.${w.month.toString().padLeft(2, '0')} $hh:$mm';
  }

  static PushMessage build(
    PushKind kind,
    String locale, {
    DateTime? at,
    Map<String, String> data = const {},
  }) {
    final byLocale = _t[kind]!;
    final (title, body) = byLocale[locale] ?? byLocale['uz']!;
    return PushMessage(
      title,
      body.replaceAll('{time}', at == null ? '' : clinicTime(at)),
      {'kind': kind.name, ...data},
    );
  }
}

enum PushResult { sent, unregistered, failed }

abstract class PushSender {
  Future<PushResult> send(Device device, PushMessage message);
}

/// Ishlab chiqish uchun: faqat turini logga yozadi (token va matnsiz).
class LogPushSender implements PushSender {
  final sent = <(String userId, PushMessage message)>[];

  @override
  Future<PushResult> send(Device device, PushMessage message) async {
    sent.add((device.userId, message));
    return PushResult.sent;
  }
}

/// Firebase Cloud Messaging HTTP v1 API (`message.fid` — Firebase
/// Installation ID'ga to'g'ridan-to'g'ri yuborish).
/// Xizmat hisobiga `roles/firebasecloudmessaging.admin` (yoki
/// cloudmessaging.messages.create ruxsati) berilgan bo'lishi kerak.
class FcmPushSender implements PushSender {
  FcmPushSender({
    required this.client,
    required this.tokens,
    required this.projectId,
  });

  final http.Client client;
  final GcpTokenProvider tokens;
  final String projectId;

  @override
  Future<PushResult> send(Device device, PushMessage m) async {
    final res = await client.post(
      Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      ),
      headers: {
        'authorization': 'Bearer ${await tokens.token()}',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'message': {
          // Firebase Installation ID (FID). `token` maydoni eskirgan.
          'fid': device.token,
          'notification': {'title': m.title, 'body': m.body},
          'data': m.data,
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': 'medlink_default',
              // Qulf ekranida faqat "MedLink: yangi bildirishnoma".
              'visibility': 'PRIVATE',
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default'},
            },
          },
        },
      }),
    );
    if (res.statusCode == 200) return PushResult.sent;
    // Ilova o'chirilgan yoki token eskirgan — qurilmani ro'yxatdan chiqaramiz.
    if (res.statusCode == 404 ||
        res.body.contains('UNREGISTERED') ||
        (res.statusCode == 400 && res.body.contains('registration token'))) {
      return PushResult.unregistered;
    }
    return PushResult.failed;
  }
}

/// Bildirishnoma yuborish. Hech qachon asosiy jarayonni (to'lov, bron)
/// buzmaydi: xatolar yutiladi.
class NotificationService {
  NotificationService({required this.devices, required this.sender});
  final DeviceRegistry devices;
  final PushSender sender;

  Future<void> notify(
    String userId,
    PushKind kind, {
    DateTime? at,
    Map<String, String> data = const {},
  }) async {
    for (final d in devices.forUser(userId)) {
      try {
        final r = await sender.send(
          d,
          PushTemplates.build(kind, d.locale, at: at, data: data),
        );
        if (r == PushResult.unregistered) devices.removeToken(d.token);
      } catch (_) {
        // Tarmoq xatosi — keyingi qurilmaga o'tamiz.
      }
    }
  }
}
