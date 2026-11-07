/// HIPAA §164.312(b) "Audit controls": tibbiy ma'lumotga har bir murojaat
/// (kim, qachon, nima, qaysi yozuv) qayd etiladi. Jurnalda tibbiy mazmunning
/// o'zi saqlanmaydi — faqat identifikatorlar.
class AuditEvent {
  AuditEvent({
    required this.actorId,
    required this.action,
    required this.resource,
    this.resourceId,
    this.outcome = 'success',
    DateTime? at,
  }) : at = at ?? DateTime.now().toUtc();

  final String actorId;
  final String action;
  final String resource;
  final String? resourceId;
  final String outcome;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'actorId': actorId,
    'action': action,
    'resource': resource,
    'resourceId': resourceId,
    'outcome': outcome,
    'at': at.toIso8601String(),
  };
}

abstract class AuditLog {
  Future<void> record(AuditEvent event);
  Future<List<AuditEvent>> forActor(String actorId);
}

/// Ishlab chiqish uchun. Prod'da faqat qo'shish mumkin bo'lgan (append-only,
/// WORM) saqlash ishlatilishi kerak, masalan Cloud Logging + bucket lock.
class InMemoryAuditLog implements AuditLog {
  final List<AuditEvent> _events = [];

  List<AuditEvent> get events => List.unmodifiable(_events);

  @override
  Future<void> record(AuditEvent event) async => _events.add(event);

  @override
  Future<List<AuditEvent>> forActor(String actorId) async =>
      _events.where((e) => e.actorId == actorId).toList();
}
