import 'package:uuid/uuid.dart';

import '../persistence/changes.dart';
import 'notifications.dart';

/// Ilova ichidagi bildirishnomalar tarixi (qo'ng'iroqcha belgisi). Push
/// o'chirilgan yoki yetib kelmagan bo'lsa ham foydalanuvchi xabarni ko'radi.
/// Matn saqlanmaydi — faqat turi va identifikatorlar; sarlavha so'rov
/// vaqtida foydalanuvchi tilida yasaladi (push bilan bir xil shablon).
class InboxItem {
  InboxItem({
    required this.id,
    required this.userId,
    required this.kind,
    required this.data,
    required this.createdAt,
    this.eventAt,
    this.read = false,
  });

  final String id;
  final String userId;
  final PushKind kind;
  final Map<String, String> data;
  final DateTime createdAt;

  /// Xabardagi vaqt (masalan, qabul vaqti).
  final DateTime? eventAt;
  bool read;

  Map<String, dynamic> toJson(String locale) {
    final m = PushTemplates.build(kind, locale, at: eventAt, data: data);
    return {
      'id': id,
      'kind': kind.name,
      'title': m.title,
      'body': m.body,
      'data': data,
      'at': createdAt.toIso8601String(),
      'read': read,
    };
  }
}

class NotificationInbox {
  static const keepPerUser = 100;

  final _byUser = <String, List<InboxItem>>{};

  void add(
    String userId,
    PushKind kind, {
    DateTime? eventAt,
    Map<String, String> data = const {},
  }) {
    final list = _byUser.putIfAbsent(userId, () => []);
    final item = InboxItem(
      id: const Uuid().v4(),
      userId: userId,
      kind: kind,
      data: Map.unmodifiable(data),
      createdAt: DateTime.now().toUtc(),
      eventAt: eventAt,
    );
    list.add(item);
    _persist(item);
    while (list.length > keepPerUser) {
      final old = list.removeAt(0);
      changes.delete('notifications', 'id', old.id);
    }
  }

  /// Eng yangilari birinchi.
  List<InboxItem> list(String userId) =>
      (_byUser[userId] ?? const <InboxItem>[]).reversed.toList();

  int unread(String userId) =>
      (_byUser[userId] ?? const <InboxItem>[]).where((i) => !i.read).length;

  /// [ids] berilmasa — hammasi o'qilgan deb belgilanadi.
  int markRead(String userId, [Set<String>? ids]) {
    var n = 0;
    for (final i in _byUser[userId] ?? const <InboxItem>[]) {
      if (!i.read && (ids == null || ids.contains(i.id))) {
        i.read = true;
        _persist(i);
        n++;
      }
    }
    return n;
  }

  void deleteUser(String userId) {
    _byUser.remove(userId);
    changes.delete('notifications', 'user_id', userId);
  }

  void _persist(InboxItem i) => changes.save(
    'notifications',
    i.id,
    () => (
      columns: {'user_id': i.userId, 'created_at': i.createdAt, 'read': i.read},
      data: {
        'kind': i.kind.name,
        'data': i.data,
        'eventAt': i.eventAt?.toIso8601String(),
      },
    ),
  );

  void restore(List<Map<String, dynamic>> rows) {
    final items = <InboxItem>[];
    for (final r in rows) {
      final j = r['data'] as Map<String, dynamic>;
      final kind = PushKind.values
          .where((k) => k.name == j['kind'])
          .firstOrNull;
      if (kind == null) continue;
      items.add(
        InboxItem(
          id: r['id'] as String,
          userId: r['user_id'] as String,
          kind: kind,
          data: (j['data'] as Map).cast<String, String>(),
          createdAt: (r['created_at'] as DateTime).toUtc(),
          eventAt: j['eventAt'] == null
              ? null
              : DateTime.parse(j['eventAt'] as String),
          read: r['read'] as bool,
        ),
      );
    }
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final i in items) {
      _byUser.putIfAbsent(i.userId, () => []).add(i);
    }
  }
}
