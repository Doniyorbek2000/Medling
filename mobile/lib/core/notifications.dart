import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/repository.dart';
import '../models/models.dart';

/// Firebase sozlamalari build vaqtida beriladi (`--dart-define`), shuning
/// uchun `google-services.json` / `GoogleService-Info.plist` shart emas.
/// Bu qiymatlar maxfiy emas (ular baribir ilova ichida bo'ladi).
class FirebaseConfig {
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');

  static FirebaseOptions? get current {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final key = ios ? iosApiKey : androidApiKey;
    final app = ios ? iosAppId : androidAppId;
    if (projectId.isEmpty || senderId.isEmpty || key.isEmpty || app.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: key,
      appId: app,
      messagingSenderId: senderId,
      projectId: projectId,
      iosBundleId: ios ? 'uz.medlink.medlink' : null,
    );
  }
}

/// Bildirishnoma bosilganda qayerga o'tish kerak.
class NotificationTap {
  const NotificationTap({required this.type, this.appointmentId});
  final String type; // appointment | doctor_application
  final String? appointmentId;

  static NotificationTap? fromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return null;
    return NotificationTap(
      type: type,
      appointmentId: data['appointmentId'] as String?,
    );
  }
}

/// Mahalliy eslatma matnlari (lokalizatsiyadan olinadi).
class ReminderTexts {
  const ReminderTexts({
    required this.title,
    required this.dayBefore,
    required this.hourBefore,
  });
  final String title;

  /// Vaqtni oladi (masalan, "09:00").
  final String Function(String time) dayBefore;
  final String Function(String time) hourBefore;
}

/// Push (FCM) va mahalliy eslatmalar.
///
/// Maxfiylik: bildirishnoma matnida shifokor ismi, mutaxassisligi yoki
/// tashxis bo'lmaydi; Android'da qulf ekranida mazmun yashiriladi
/// (`NotificationVisibility.private`).
class NotificationsService {
  NotificationsService({FlutterLocalNotificationsPlugin? local})
    : _local = local ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _local;
  final _taps = StreamController<NotificationTap>.broadcast();
  bool _localReady = false;
  bool _firebaseReady = false;
  String? _token;
  MedLinkRepository? _repo;
  String _locale = 'uz';
  StreamSubscription<String>? _tokenSub;

  static const channelId = 'medlink_default';
  static const _reminderLead = [Duration(hours: 24), Duration(hours: 1)];

  Stream<NotificationTap> get taps => _taps.stream;
  bool get pushAvailable => FirebaseConfig.current != null;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      'MedLink',
      channelDescription: 'Qabullar va arizalar',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.private,
      icon: 'ic_stat_medlink',
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Ilova ishga tushganda (ruxsat SO'RAMAYDI).
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_medlink'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => _emitPayload(r.payload),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              'MedLink',
              description: 'Qabullar va arizalar',
              importance: Importance.high,
            ),
          );
      _localReady = true;
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _emitPayload(launch!.notificationResponse?.payload);
      }
    } on MissingPluginException {
      // Testlar.
    } catch (_) {}

    final options = FirebaseConfig.current;
    if (options == null) return;
    try {
      await Firebase.initializeApp(options: options);
      _firebaseReady = true;
      final fm = FirebaseMessaging.instance;
      await fm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      // Ilova ochiq paytida Android push'ni o'zi ko'rsatmaydi — biz ko'rsatamiz.
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n == null || defaultTargetPlatform != TargetPlatform.android) {
          return;
        }
        _show(n.title ?? 'MedLink', n.body ?? '', jsonEncode(m.data));
      });
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _emit(m.data));
      final initial = await fm.getInitialMessage();
      if (initial != null) _emit(initial.data);
    } catch (_) {
      _firebaseReady = false;
    }
  }

  void _emit(Map<String, dynamic> data) {
    final t = NotificationTap.fromData(data);
    if (t != null) _taps.add(t);
  }

  void _emitPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      _emit(jsonDecode(payload) as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> _show(String title, String body, String payload) async {
    if (!_localReady) return;
    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
      title: title,
      body: body,
      notificationDetails: _details,
      payload: payload,
    );
  }

  /// Foydalanuvchi bildirishnomalarni yoqqanda chaqiriladi.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      bool? granted;
      if (defaultTargetPlatform == TargetPlatform.android) {
        granted = await _local
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        granted = await _local
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Qurilmani FCM'da ro'yxatdan o'tkazadi va FID (Firebase Installation ID)
  /// ni serverga yozadi. FCM'ning yangi API'si: `register()` → `onRegistered`
  /// (eskirgan `getToken()` o'rniga). Server FID'ga `message.fid` orqali yuboradi.
  Future<void> registerDevice(MedLinkRepository repo, String locale) async {
    _repo = repo;
    _locale = locale;
    if (!_firebaseReady) return;
    try {
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      _tokenSub ??= fm.onRegistered.listen((fid) {
        _token = fid;
        _repo?.registerDevice(fid, _locale).catchError((Object _) {});
      });
      await fm.register();
    } catch (_) {}
  }

  /// Chiqishda yoki o'chirilganda: FID serverdan va FCM'dan o'chiriladi.
  Future<void> unregisterDevice(MedLinkRepository repo) async {
    final fid = _token;
    _token = null;
    await _tokenSub?.cancel();
    _tokenSub = null;
    if (fid != null) {
      try {
        await repo.unregisterDevice(fid);
      } catch (_) {}
    }
    if (_firebaseReady) {
      try {
        await FirebaseMessaging.instance.unregister();
      } catch (_) {}
    }
  }

  /// Tasdiqlangan kelgusi qabullar uchun 24 soat va 1 soat oldin eslatma
  /// rejalashtiradi; qolganlarini bekor qiladi. Server push'idan mustaqil.
  Future<int> syncReminders(
    List<Appointment> appointments,
    ReminderTexts texts,
    String Function(DateTime) formatTime,
  ) async {
    if (!_localReady) return 0;
    await _local.cancelAllPendingNotifications();
    final now = DateTime.now().toUtc();
    var count = 0;
    for (final r in plannedReminders(appointments, now)) {
      final time = formatTime(r.appointment.startsAt);
      await _local.zonedSchedule(
        id: r.id,
        scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
        notificationDetails: _details,
        // Aniq signal (exact alarm) ruxsati shart emas — bir necha daqiqa
        // kechikish eslatma uchun maqbul.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: texts.title,
        body: r.lead >= const Duration(hours: 24)
            ? texts.dayBefore(time)
            : texts.hourBefore(time),
        payload: jsonEncode({
          'type': 'appointment',
          'appointmentId': r.appointment.id,
        }),
      );
      count++;
    }
    return count;
  }

  Future<void> cancelReminders() async {
    if (_localReady) await _local.cancelAllPendingNotifications();
  }

  /// Qaysi eslatmalar rejalashtirilishini hisoblaydi (sof funksiya — test qilinadi).
  static List<({int id, DateTime at, Duration lead, Appointment appointment})>
  plannedReminders(List<Appointment> appointments, DateTime now) => [
    for (final a in appointments)
      if (a.status == 'confirmed')
        for (final (i, lead) in _reminderLead.indexed)
          if (a.startsAt.subtract(lead).isAfter(now))
            (
              id: stableId(a.id) * 2 + i,
              at: a.startsAt.subtract(lead).toUtc(),
              lead: lead,
              appointment: a,
            ),
  ];

  /// Ilova qayta ishga tushganda ham bir xil bo'ladigan ID (FNV-1a).
  /// `String.hashCode` ishga tushirishlar orasida barqaror emas.
  static int stableId(String s) {
    var h = 0x811c9dc5;
    for (final c in utf8.encode(s)) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x3fffffff;
  }
}
