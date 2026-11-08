import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/api_client.dart';
import '../models/models.dart';

/// Ilovaning barcha server so'rovlari shu yerda — ekranlar HTTP yo'llarini
/// bilmaydi, testlarda esa repozitoriyni almashtirish oson.
class MedLinkRepository {
  MedLinkRepository(this.api);
  final ApiClient api;

  /// Qabullar yuklanganda (mahalliy eslatmalarni yangilash uchun).
  void Function(List<Appointment>)? onAppointments;

  // ---- Rozilik ----
  Future<List<ConsentDoc>> consents() async {
    final res = await api.get('/v1/consents');
    return [
      for (final d in res['documents'] as List)
        ConsentDoc.fromJson(d as Map<String, dynamic>),
    ];
  }

  /// Qaytaradi: hali berilmagan rozilik bandlari.
  Future<List<String>> saveConsents(Iterable<ConsentDoc> docs) async {
    final res = await api.post('/v1/consents', {
      'decisions': [
        for (final d in docs)
          {'scope': d.scope, 'version': d.version, 'granted': d.granted},
      ],
    });
    return (res['missingConsents'] as List).cast<String>();
  }

  // ---- Push qurilmalari ----
  Future<void> registerDevice(String token, String locale) =>
      api.post('/v1/me/devices', {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        'locale': locale,
      });

  Future<void> unregisterDevice(String token) =>
      api.post('/v1/me/devices/remove', {'token': token});

  // ---- Tibbiy profil ----
  Future<MedicalProfile> profile() async =>
      MedicalProfile.fromJson(await api.get('/v1/me/profile'));

  Future<MedicalProfile> saveProfile(MedicalProfile p) async =>
      MedicalProfile.fromJson(await api.put('/v1/me/profile', p.toJson()));

  Future<Map<String, dynamic>> exportData() => api.get('/v1/me/export');

  Future<void> deleteHealthData() => api.delete('/v1/me/health-data');

  // ---- AI triaj ----
  Future<TriageResult> analyze({
    required String symptoms,
    required int ageYears,
    required String sex,
    int? durationDays,
    List<String> chronicConditions = const [],
  }) async => TriageResult.fromJson(
    await api.post('/v1/triage', {
      'symptoms': symptoms,
      'ageYears': ageYears,
      'sex': sex,
      'durationDays': ?durationDays,
      'chronicConditions': chronicConditions,
    }),
  );

  Future<List<TriageHistoryItem>> triageHistory() async {
    final res = await api.get('/v1/triage/history');
    return [
      for (final i in (res['items'] as List).reversed)
        TriageHistoryItem.fromJson(i as Map<String, dynamic>),
    ];
  }

  // ---- Shifokorlar ----
  Future<List<Doctor>> doctors({String? specialty, String? query}) async {
    final res = await api.get('/v1/doctors', {
      'specialty': ?specialty,
      if (query != null && query.isNotEmpty) 'q': query,
    });
    return [
      for (final d in res['items'] as List)
        Doctor.fromJson(d as Map<String, dynamic>),
    ];
  }

  Future<Doctor> doctor(String id) async =>
      Doctor.fromJson(await api.get('/v1/doctors/$id'));

  Future<List<Review>> reviews(String doctorId) async {
    final res = await api.get('/v1/doctors/$doctorId/reviews');
    return [
      for (final r in res['items'] as List)
        Review.fromJson(r as Map<String, dynamic>),
    ];
  }

  /// [day] — Toshkent bo'yicha sana. Qaytaradi: UTC vaqtlar.
  Future<List<DateTime>> slots(String doctorId, DateTime day) async {
    final date =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final res = await api.get('/v1/doctors/$doctorId/slots', {'date': date});
    return [
      for (final s in res['items'] as List) DateTime.parse(s as String).toUtc(),
    ];
  }

  // ---- Qabullar ----
  Future<Appointment> book({
    required String doctorId,
    required DateTime startsAt,
    required String reason,
    String? triageId,
    String type = 'clinic',
  }) async => Appointment.fromJson(
    await api.post('/v1/appointments', {
      'type': type,
      'doctorId': doctorId,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'reason': reason,
      'triageId': ?triageId,
    }),
  );

  Future<List<Appointment>> appointments() async {
    final res = await api.get('/v1/appointments');
    final list = [
      for (final a in res['items'] as List)
        Appointment.fromJson(a as Map<String, dynamic>),
    ];
    onAppointments?.call(list);
    return list;
  }

  /// Bitta qabul (bemor yoki shifokor uchun, `myRole` bilan).
  Future<Appointment> appointment(String id) async =>
      Appointment.fromJson(await api.get('/v1/appointments/$id'));

  // ---- Onlayn konsultatsiya ----
  Future<({bool canWrite, List<ChatMessage> items})> messages(
    String appointmentId, {
    int after = 0,
  }) async {
    final res = await api.get('/v1/appointments/$appointmentId/messages', {
      'after': '$after',
    });
    return (
      canWrite: res['canWrite'] as bool,
      items: [
        for (final m in res['items'] as List)
          ChatMessage.fromJson(m as Map<String, dynamic>),
      ],
    );
  }

  /// Chatning real vaqt oqimi: `ready` (ulandi) va yangi xabarlar.
  /// null — ulanish imkoni yo'q (brauzer/test), so'rovlar ishlatiladi.
  LiveChat? liveChat(String appointmentId) {
    final ch = api.openSocket('/v1/appointments/$appointmentId/live');
    if (ch == null) return null;
    return LiveChat._(ch);
  }

  Future<ChatMessage> sendMessage(String appointmentId, String text) async =>
      ChatMessage.fromJson(
        await api.post('/v1/appointments/$appointmentId/messages', {
          'text': text,
        }),
      );

  Future<ChatMessage> uploadAttachment(
    String appointmentId,
    List<int> bytes,
    String fileName,
  ) async => ChatMessage.fromJson(
    await api.postBytes(
      '/v1/appointments/$appointmentId/attachments',
      bytes,
      headers: {'x-file-name': Uri.encodeComponent(fileName)},
    ),
  );

  /// Ekranda qayta-qayta yuklanmasligi uchun xotirada (faqat sessiya
  /// davomida; diskka yozilmaydi).
  final _attachmentCache = <String, Uint8List>{};

  Future<Uint8List> attachmentBytes(String appointmentId, String id) async {
    final cached = _attachmentCache[id];
    if (cached != null) return cached;
    final bytes = await api.getBytes(
      '/v1/appointments/$appointmentId/attachments/$id',
    );
    if (_attachmentCache.length > 30) _attachmentCache.clear();
    return _attachmentCache[id] = bytes;
  }

  void clearCache() => _attachmentCache.clear();

  Future<({String url, String token})> videoToken(String appointmentId) async {
    final res = await api.post('/v1/appointments/$appointmentId/video');
    return (url: res['url'] as String, token: res['token'] as String);
  }

  Future<PatientInfo> patientInfo(String appointmentId) async =>
      PatientInfo.fromJson(
        await api.get('/v1/doctor/appointments/$appointmentId/patient'),
      );

  Future<Appointment> saveConclusion(
    String appointmentId,
    Conclusion c,
  ) async => Appointment.fromJson(
    await api.put(
      '/v1/doctor/appointments/$appointmentId/conclusion',
      c.toJson(),
    ),
  );

  Future<DoctorSettings> doctorSettings() async =>
      DoctorSettings.fromJson(await api.get('/v1/doctor/settings'));

  Future<DoctorSettings> saveDoctorSettings(DoctorSettings s) async =>
      DoctorSettings.fromJson(await api.put('/v1/doctor/settings', s.toJson()));

  /// Qaytaradi: `requested` (pul qaytariladi) yoki `none`.
  /// Qabulni shu shifokorning boshqa bo'sh vaqtiga ko'chirish.
  Future<Appointment> reschedule(String id, DateTime startsAt) async =>
      Appointment.fromJson(
        await api.post('/v1/appointments/$id/reschedule', {
          'startsAt': startsAt.toUtc().toIso8601String(),
        }),
      );

  /// Hisobni butunlay o'chirish. Qaytariladigan to'lovlar soni qaytadi.
  Future<int> deleteAccount() async {
    final res = await api.delete('/v1/me');
    clearCache();
    return res['refunds'] as int? ?? 0;
  }

  Future<String> cancelAppointment(String id) async =>
      (await api.post('/v1/appointments/$id/cancel'))['refund'] as String? ??
      'none';

  Future<void> review(String appointmentId, int rating, String comment) =>
      api.post('/v1/appointments/$appointmentId/review', {
        'rating': rating,
        'comment': comment,
      });

  // ---- To'lovlar ----
  Future<({String orderId, Uri checkoutUrl})> checkout(
    String appointmentId,
    String provider,
  ) async {
    final res = await api.post('/v1/payments/checkout', {
      'appointmentId': appointmentId,
      'provider': provider,
    });
    return (
      orderId: res['id'] as String,
      checkoutUrl: Uri.parse(res['checkoutUrl'] as String),
    );
  }

  Future<bool> payWithWallet(
    String appointmentId,
    String provider,
    String token,
  ) async {
    final res = await api.post('/v1/payments/wallet', {
      'appointmentId': appointmentId,
      'provider': provider,
      'token': token,
    });
    return res['status'] == 'paid';
  }

  Future<String> orderStatus(String orderId) async =>
      (await api.get('/v1/payments/$orderId'))['status'] as String;

  // ---- Shifokor portali ----
  Future<DoctorApplication?> myApplication() async {
    try {
      return DoctorApplication.fromJson(await api.get('/v1/doctors/me'));
    } on ApiError catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  Future<void> applyAsDoctor(Map<String, dynamic> body) =>
      api.post('/v1/doctors/apply', body);

  Future<List<Appointment>> doctorAppointments() async {
    final res = await api.get('/v1/doctor/appointments');
    return [
      for (final a in res['items'] as List)
        Appointment.fromJson(a as Map<String, dynamic>),
    ];
  }

  Future<void> completeAppointment(String id) =>
      api.post('/v1/doctor/appointments/$id/complete');

  // ---- Admin ----
  Future<AdminStats> adminStats() async =>
      AdminStats.fromJson(await api.get('/v1/admin/stats'));

  Future<List<RefundRequest>> refunds() async {
    final res = await api.get('/v1/admin/refunds');
    return [
      for (final r in res['items'] as List)
        RefundRequest.fromJson(r as Map<String, dynamic>),
    ];
  }

  Future<void> completeRefund(String orderId) =>
      api.post('/v1/admin/refunds/$orderId/complete');

  Future<List<Map<String, dynamic>>> pendingDoctors() async =>
      ((await api.get('/v1/admin/doctors/pending'))['items'] as List)
          .cast<Map<String, dynamic>>();

  Future<void> moderate(String doctorId, String decision, {String? note}) =>
      api.post('/v1/admin/doctors/$doctorId/moderate', {
        'decision': decision,
        'note': ?note,
      });
}

/// Chat WebSocket ulanishi.
class LiveChat {
  LiveChat._(this._channel);
  final WebSocketChannel _channel;

  /// `null` — ulanish tayyor (server `ready` yubordi); aks holda yangi xabar.
  Stream<ChatMessage?> get events => _channel.stream.map((raw) {
    final e = jsonDecode(raw as String) as Map<String, dynamic>;
    return e['type'] == 'message'
        ? ChatMessage.fromJson(e['message'] as Map<String, dynamic>)
        : null;
  });

  Future<void> close() async {
    try {
      await _channel.sink.close();
    } catch (_) {}
  }
}
