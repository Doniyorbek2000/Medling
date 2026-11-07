import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../appointments/appointments.dart';
import '../core/http_utils.dart';

/// LiveKit (WebRTC SFU) uchun kirish tokeni.
///
/// LiveKit serverini O'zbekiston hududidagi serverga o'rnatish mumkin
/// (open-source), bu ma'lumotlarni lokalizatsiya talabiga mos keladi.
/// Media DTLS-SRTP bilan shifrlanadi; yozib olish o'chiq.
class VideoTokenIssuer {
  VideoTokenIssuer({
    required this.url,
    required this.apiKey,
    required this.apiSecret,
  });

  final String url;
  final String apiKey;
  final String apiSecret;

  bool get configured =>
      url.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty;

  /// Qabul boshlanishidan 10 daqiqa oldin ochiladi, slot tugagach 30 daqiqa
  /// qo'shimcha vaqt beriladi.
  static const earlyJoin = Duration(minutes: 10);
  static const overtime = Duration(minutes: 30);

  static (DateTime, DateTime) window(Appointment a) => (
    a.startsAt.subtract(earlyJoin),
    a.startsAt.add(AppointmentService.slot).add(overtime),
  );

  /// Xona nomida tibbiy yoki shaxsiy ma'lumot yo'q.
  static String roomName(Appointment a) => 'medlink-${a.id}';

  ({String url, String token, String room, DateTime expiresAt}) issue(
    Appointment a, {
    required String userId,
    required String role,
    DateTime? now,
  }) {
    if (!configured) throw ApiException(503, 'video_unavailable');
    if (!a.isOnline) throw ApiException(409, 'not_online');
    if (a.status != AppointmentStatus.confirmed) {
      throw ApiException(409, 'not_confirmed');
    }
    final t = (now ?? DateTime.now()).toUtc();
    final (opens, closes) = window(a);
    if (t.isBefore(opens)) throw ApiException(409, 'too_early');
    if (t.isAfter(closes)) throw ApiException(409, 'too_late');

    final room = roomName(a);
    final token =
        JWT(
          {
            // Ko'rinadigan ism — faqat rol, ism-familiya emas.
            'name': role == 'doctor' ? 'Doctor' : 'Patient',
            'metadata': '{"role":"$role"}',
            'video': {
              'room': room,
              'roomJoin': true,
              'canPublish': true,
              'canSubscribe': true,
              'canPublishData': true,
              'roomRecord': false,
            },
          },
          issuer: apiKey,
          subject: userId,
          jwtId: '${a.id}:$userId',
        ).sign(
          SecretKey(apiSecret),
          algorithm: JWTAlgorithm.HS256,
          notBefore: Duration.zero,
          expiresIn: closes.difference(t),
        );
    return (url: url, token: token, room: room, expiresAt: closes);
  }
}
