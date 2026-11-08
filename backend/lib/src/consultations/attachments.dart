import 'dart:convert';
import 'dart:typed_data';

import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import '../appointments/appointments.dart';
import '../core/http_utils.dart';
import '../security/field_encryption.dart';
import 'chat.dart';

/// Chatga biriktirilgan fayl (tahlil natijasi, retsept rasmi).
class AttachmentMeta {
  AttachmentMeta({
    required this.id,
    required this.appointmentId,
    required this.uploaderId,
    required this.name,
    required this.mime,
    required this.size,
  });

  final String id;
  final String appointmentId;
  final String uploaderId;
  final String name;
  final String mime;
  final int size;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mime': mime,
    'size': size,
  };
}

/// Fayllar xotirada ushlab turilmaydi — to'g'ridan-to'g'ri omborga yoziladi.
abstract class AttachmentStore {
  Future<void> put(AttachmentMeta meta, String encryptedContent);
  Future<(AttachmentMeta, String)?> get(String id);
}

class MemoryAttachmentStore implements AttachmentStore {
  final _items = <String, (AttachmentMeta, String)>{};

  @override
  Future<void> put(AttachmentMeta meta, String enc) async =>
      _items[meta.id] = (meta, enc);

  @override
  Future<(AttachmentMeta, String)?> get(String id) async => _items[id];
}

class PostgresAttachmentStore implements AttachmentStore {
  PostgresAttachmentStore(this._pool);
  final Pool<void> _pool;

  @override
  Future<void> put(AttachmentMeta m, String enc) async {
    await _pool.execute(
      Sql.named(
        'INSERT INTO attachments (id, appointment_id, uploader_id, name, mime, '
        'size, content) VALUES (@id, @a, @u, @n, @m, @s, @c)',
      ),
      parameters: {
        'id': m.id,
        'a': m.appointmentId,
        'u': m.uploaderId,
        'n': m.name,
        'm': m.mime,
        's': m.size,
        'c': enc,
      },
    );
  }

  @override
  Future<(AttachmentMeta, String)?> get(String id) async {
    final rows = await _pool.execute(
      Sql.named('SELECT * FROM attachments WHERE id = @id'),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    final r = rows.first.toColumnMap();
    return (
      AttachmentMeta(
        id: r['id'] as String,
        appointmentId: r['appointment_id'] as String,
        uploaderId: r['uploader_id'] as String,
        name: r['name'] as String,
        mime: r['mime'] as String,
        size: r['size'] as int,
      ),
      r['content'] as String,
    );
  }
}

/// Chat fayllari: faqat rasm (JPEG/PNG), 5 MB gacha, AES-256-GCM bilan
/// shifrlangan; turi kengaytma bo'yicha emas, fayl imzosi bo'yicha aniqlanadi.
class AttachmentService {
  AttachmentService({
    required this.appointments,
    required this.chat,
    required this.encryption,
    required this.store,
  });

  final AppointmentService appointments;
  final ChatService chat;
  final FieldEncryption encryption;
  final AttachmentStore store;

  static const maxBytes = 5 * 1024 * 1024;

  /// Fayl imzosi (magic bytes) bo'yicha MIME turi; qo'llab-quvvatlanmasa null.
  static String? detectMime(List<int> b) {
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return 'image/jpeg';
    }
    const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (b.length >= 8 &&
        List.generate(8, (i) => b[i] == png[i]).every((x) => x)) {
      return 'image/png';
    }
    return null;
  }

  static String _safeName(String? name, String mime) {
    final base = (name ?? '')
        .replaceAll(RegExp(r'[^A-Za-z0-9._\- ]'), '_')
        .trim();
    final ext = mime == 'image/png' ? '.png' : '.jpg';
    if (base.isEmpty) return 'rasm$ext';
    return base.length > 80 ? base.substring(0, 80) : base;
  }

  Future<ChatMessage> upload(
    String appointmentId,
    String userId,
    Uint8List bytes, {
    String? fileName,
  }) async {
    final a = appointments.requireParticipant(appointmentId, userId);
    if (!chat.canWrite(a, DateTime.now().toUtc())) {
      throw ApiException(409, 'chat_closed');
    }
    if (bytes.isEmpty) throw ApiException(400, 'empty_file');
    if (bytes.length > maxBytes) throw ApiException(413, 'file_too_large');
    final mime =
        detectMime(bytes) ?? (throw ApiException(415, 'unsupported_file_type'));
    final id = const Uuid().v4();
    final meta = AttachmentMeta(
      id: id,
      appointmentId: appointmentId,
      uploaderId: userId,
      name: _safeName(fileName, mime),
      mime: mime,
      size: bytes.length,
    );
    await store.put(
      meta,
      await encryption.encrypt(
        base64.encode(bytes),
        aad: 'att:$appointmentId:$id',
      ),
    );
    return chat.send(appointmentId, userId, meta.name, attachment: meta);
  }

  Future<(AttachmentMeta, Uint8List)> download(
    String appointmentId,
    String attachmentId,
    String userId,
  ) async {
    appointments.requireParticipant(appointmentId, userId);
    final found = await store.get(attachmentId);
    if (found == null || found.$1.appointmentId != appointmentId) {
      throw ApiException(404, 'not_found');
    }
    final clear = await encryption.decrypt(
      found.$2,
      aad: 'att:$appointmentId:$attachmentId',
    );
    return (found.$1, base64.decode(clear));
  }
}
