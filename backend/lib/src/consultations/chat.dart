import 'package:uuid/uuid.dart';

import '../appointments/appointments.dart';
import '../core/http_utils.dart';
import '../persistence/changes.dart';
import '../security/field_encryption.dart';
import 'attachments.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    required this.senderRole,
    required this.textEnc,
    required this.seq,
    DateTime? at,
    this.attachment,
  }) : at = at ?? DateTime.now().toUtc();

  /// Biriktirilgan fayl (bo'lsa). Fayl mazmuni alohida omborda.
  final AttachmentMeta? attachment;

  final String id;
  final String appointmentId;
  final String senderId;
  final String senderRole; // patient | doctor
  final String textEnc;

  /// Qabul ichida o'suvchi tartib raqami — mijoz `after=seq` bilan faqat
  /// yangilarini so'raydi.
  final int seq;
  final DateTime at;
}

/// Bemor va shifokor o'rtasidagi qabul chati.
///
/// * Faqat shu qabul ishtirokchilari yoza va o'qiy oladi.
/// * Chat qabul tasdiqlangandan boshlab, yakunlangandan keyin 7 kun davomida
///   ochiq (savol-javob uchun), so'ng faqat o'qish mumkin.
/// * Matn bazada AES-256-GCM bilan shifrlanadi.
class ChatService {
  ChatService(this.appointments, this.encryption);
  final AppointmentService appointments;
  final FieldEncryption encryption;

  final _messages = <String, List<ChatMessage>>{};

  static const maxLength = 2000;
  static const followUpWindow = Duration(days: 7);

  /// Yangi xabar (bildirishnoma uchun).
  void Function(Appointment a, ChatMessage m)? onMessage;

  bool canWrite(Appointment a, DateTime now) => switch (a.status) {
    AppointmentStatus.confirmed => true,
    AppointmentStatus.completed => now.isBefore(
      (a.conclusionAt ?? a.startsAt).add(followUpWindow),
    ),
    _ => false,
  };

  /// Ishga tushganda bazadan tiklash.
  void restore(List<Map<String, dynamic>> rows) {
    final list = [
      for (final r in rows)
        ChatMessage(
          id: r['id'] as String,
          appointmentId: r['appointment_id'] as String,
          senderId: (r['data'] as Map)['senderId'] as String,
          senderRole: (r['data'] as Map)['senderRole'] as String,
          textEnc: (r['data'] as Map)['textEnc'] as String,
          seq: r['seq'] as int,
          at: DateTime.parse((r['data'] as Map)['at'] as String),
          attachment: switch ((r['data'] as Map)['attachment']) {
            final Map<String, dynamic> j => AttachmentMeta(
              id: j['id'] as String,
              appointmentId: r['appointment_id'] as String,
              uploaderId: j['uploaderId'] as String,
              name: j['name'] as String,
              mime: j['mime'] as String,
              size: j['size'] as int,
            ),
            _ => null,
          },
        ),
    ]..sort((a, b) => a.seq.compareTo(b.seq));
    for (final m in list) {
      _messages.putIfAbsent(m.appointmentId, () => []).add(m);
    }
  }

  Future<ChatMessage> send(
    String appointmentId,
    String userId,
    String text, {
    AttachmentMeta? attachment,
  }) async {
    final a = appointments.requireParticipant(appointmentId, userId);
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > maxLength) {
      throw ApiException(400, 'invalid_message');
    }
    if (!canWrite(a, DateTime.now().toUtc())) {
      throw ApiException(409, 'chat_closed');
    }
    final list = _messages.putIfAbsent(appointmentId, () => []);
    final id = const Uuid().v4();
    final m = ChatMessage(
      id: id,
      appointmentId: appointmentId,
      senderId: userId,
      senderRole: appointments.participantRole(a, userId)!,
      textEnc: await encryption.encrypt(
        trimmed,
        aad: 'chat:$appointmentId:$id',
      ),
      seq: list.length + 1,
      attachment: attachment,
    );
    list.add(m);
    changes.save(
      'chat_messages',
      m.id,
      () => (
        columns: {'appointment_id': m.appointmentId, 'seq': m.seq},
        data: {
          'senderId': m.senderId,
          'senderRole': m.senderRole,
          'textEnc': m.textEnc,
          'at': m.at.toIso8601String(),
          if (m.attachment != null)
            'attachment': {
              ...m.attachment!.toJson(),
              'uploaderId': m.attachment!.uploaderId,
            },
        },
      ),
    );
    onMessage?.call(a, m);
    return m;
  }

  Future<Map<String, dynamic>> list(
    String appointmentId,
    String userId, {
    int after = 0,
  }) async {
    final a = appointments.requireParticipant(appointmentId, userId);
    final all = _messages[appointmentId] ?? const <ChatMessage>[];
    return {
      'canWrite': canWrite(a, DateTime.now().toUtc()),
      'items': [
        for (final m in all.where((m) => m.seq > after))
          await toJson(m, userId),
      ],
    };
  }

  Future<Map<String, dynamic>> toJson(ChatMessage m, String viewerId) async => {
    'id': m.id,
    'seq': m.seq,
    'senderRole': m.senderRole,
    'mine': m.senderId == viewerId,
    'text': await encryption.decrypt(
      m.textEnc,
      aad: 'chat:${m.appointmentId}:${m.id}',
    ),
    'at': m.at.toIso8601String(),
    'attachment': m.attachment?.toJson(),
  };

  /// Eksport uchun: foydalanuvchi ishtirok etgan barcha xabarlar.
  Future<List<Map<String, dynamic>>> exportFor(
    String userId,
    Iterable<String> appointmentIds,
  ) async => [
    for (final id in appointmentIds)
      for (final m in _messages[id] ?? const <ChatMessage>[])
        {'appointmentId': id, ...await toJson(m, userId)},
  ];
}
