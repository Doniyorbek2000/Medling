import 'dart:async';
import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../audit/audit_log.dart';
import 'changes.dart';
import 'schema.dart';

/// PostgreSQL ombori.
///
/// Arxitektura: servislar ishchi holatni xotirada saqlaydi, PostgreSQL —
/// doimiy manba. Ishga tushganda holat bazadan yuklanadi; har bir HTTP
/// so'rovdagi o'zgarishlar javob qaytishidan OLDIN bitta tranzaksiyada
/// yoziladi. Shu sababli bir vaqtda faqat BITTA server nusxasi ishlashi
/// mumkin — bu `pg_try_advisory_lock` bilan kafolatlanadi (ikkinchi nusxa
/// ishga tushmaydi, ma'lumotlar ikkiga bo'linib ketmaydi).
class PostgresStore {
  PostgresStore._(this._pool, this._lockConnection);

  final Pool<void> _pool;

  /// Advisory lock shu ulanish yopilguncha ushlab turiladi.
  final Connection _lockConnection;

  static const _lockKey = 727001; // "MedLink" yagona yozuvchi qulfi

  Pool<void> get pool => _pool;

  /// [url]: `postgresql://user:pass@host:5432/db?sslmode=require`
  static Future<PostgresStore> open(String url) async {
    final lock = await Connection.openFromUrl(url);
    final got =
        (await lock.execute(
              Sql.named('SELECT pg_try_advisory_lock(@k)'),
              parameters: {'k': _lockKey},
            )).first.first
            as bool;
    if (!got) {
      await lock.close();
      throw StateError(
        'Bazaga boshqa MedLink nusxasi ulangan (advisory lock band). '
        'Hozirgi arxitektura bitta yozuvchi nusxani talab qiladi.',
      );
    }
    await migrate(lock);
    return PostgresStore._(Pool.withUrl(url), lock);
  }

  /// Hali qo'llanmagan migratsiyalarni tartib bilan, har birini alohida
  /// tranzaksiyada qo'llaydi.
  static Future<int> migrate(Connection c) async {
    await c.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version     INTEGER PRIMARY KEY,
        applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
      )''');
    final applied = {
      for (final r in await c.execute('SELECT version FROM schema_migrations'))
        r.first as int,
    };
    var count = 0;
    for (var i = 0; i < migrations.length; i++) {
      final version = i + 1;
      if (applied.contains(version)) continue;
      await c.runTx((tx) async {
        await tx.execute(migrations[i], queryMode: QueryMode.simple);
        await tx.execute(
          Sql.named('INSERT INTO schema_migrations(version) VALUES (@v)'),
          parameters: {'v': version},
        );
      });
      count++;
    }
    return count;
  }

  /// Jadvaldagi barcha qatorlar: ustunlar + `data` (JSONB, Map sifatida).
  Future<List<Map<String, dynamic>>> load(String table) async {
    _checkTable(table);
    final rows = await _pool.execute(
      'SELECT * FROM $table ORDER BY updated_at',
    );
    return [for (final r in rows) r.toColumnMap()];
  }

  Future<void> _flushing = Future.value();

  /// O'zgarishlarni bitta tranzaksiyada yozadi. Bir vaqtda faqat bitta
  /// yozish bajariladi (navbat).
  Future<void> flush(List<ChangeOp> ops) {
    if (ops.isEmpty) return Future.value();
    final next = _flushing.then((_) => _write(ops));
    _flushing = next.catchError((Object _) {});
    return next;
  }

  Future<void> _write(List<ChangeOp> ops) => _pool.runTx((tx) async {
    for (final op in ops) {
      _checkTable(op.table);
      switch (op) {
        case SaveOp():
          final row = op.build();
          final cols = row.columns.keys.toList();
          final params = <String, Object?>{'id': op.id, 'data': row.data};
          final values = <String>['@id:text'];
          for (var i = 0; i < cols.length; i++) {
            final v = row.columns[cols[i]];
            params['c$i'] = v is DateTime ? v.toUtc() : v;
            values.add('@c$i:${_pgType(v)}');
          }
          values.add('@data:jsonb');
          final names = ['id', ...cols, 'data'];
          final updates = [
            for (final n in names.skip(1)) '$n = EXCLUDED.$n',
            'updated_at = now()',
          ];
          await tx.execute(
            Sql.named(
              'INSERT INTO ${op.table} (${names.join(', ')}) '
              'VALUES (${values.join(', ')}) '
              'ON CONFLICT (id) DO UPDATE SET ${updates.join(', ')}',
            ),
            parameters: params,
          );
        case DeleteOp():
          if (!RegExp(r'^[a-z_]+$').hasMatch(op.column)) {
            throw ArgumentError('column');
          }
          await tx.execute(
            Sql.named('DELETE FROM ${op.table} WHERE ${op.column} = @v'),
            parameters: {'v': op.value},
          );
      }
    }
  });

  static String _pgType(Object? v) => switch (v) {
    DateTime() => 'timestamptz',
    int() => 'int8',
    bool() => 'boolean',
    _ => 'text',
  };

  /// Jadval nomlari faqat koddagi ro'yxatdan (SQL injection'dan himoya).
  static void _checkTable(String table) {
    if (!tableOrder.contains(table)) {
      throw ArgumentError('Noma\'lum jadval: $table');
    }
  }

  Future<void> close() async {
    await _flushing;
    await _pool.close();
    await _lockConnection.close();
  }
}

/// HTTP javobidan oldin o'zgarishlarni bazaga yozadi. Yozib bo'lmasa —
/// o'zgarishlar jurnalga qaytariladi (keyingi urinishda yoziladi) va mijoz
/// 503 oladi; to'lov provayderlari bunday javobdan keyin so'rovni takrorlaydi
/// (handlerlar idempotent).
Middleware persistenceMiddleware(
  PostgresStore store, {
  void Function(Object error)? onError,
}) =>
    (inner) => (req) async {
      final res = await inner(req);
      if (changes.isEmpty) return res;
      final ops = changes.drain();
      try {
        await store.flush(ops);
        return res;
      } catch (e) {
        changes.restore(ops);
        onError?.call(e);
        return Response(
          503,
          body: jsonEncode({
            'error': {'code': 'storage_unavailable'},
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
    };

/// Fon jarayonlaridagi o'zgarishlarni (eslatmalar, push tozalash) davriy
/// yozadi.
Timer startBackgroundFlush(
  PostgresStore store, {
  Duration every = const Duration(seconds: 2),
  void Function(Object error)? onError,
}) => Timer.periodic(every, (_) async {
  if (changes.isEmpty) return;
  final ops = changes.drain();
  try {
    await store.flush(ops);
  } catch (e) {
    changes.restore(ops);
    onError?.call(e);
  }
});

/// Audit jurnali to'g'ridan-to'g'ri bazaga (faqat INSERT).
class PostgresAuditLog implements AuditLog {
  PostgresAuditLog(this._pool);
  final Pool<void> _pool;

  @override
  Future<void> record(AuditEvent e) async {
    await _pool.execute(
      Sql.named(
        'INSERT INTO audit_log (actor_id, action, resource, resource_id, '
        'outcome, at) VALUES (@a, @b, @c, @d, @e, @f:timestamptz)',
      ),
      parameters: {
        'a': e.actorId,
        'b': e.action,
        'c': e.resource,
        'd': e.resourceId,
        'e': e.outcome,
        'f': e.at.toUtc(),
      },
    );
  }

  @override
  Future<List<AuditEvent>> forActor(String actorId) async {
    final rows = await _pool.execute(
      Sql.named('SELECT * FROM audit_log WHERE actor_id = @a ORDER BY at, id'),
      parameters: {'a': actorId},
    );
    return [
      for (final r in rows)
        () {
          final m = r.toColumnMap();
          return AuditEvent(
            actorId: m['actor_id'] as String,
            action: m['action'] as String,
            resource: m['resource'] as String,
            resourceId: m['resource_id'] as String?,
            outcome: m['outcome'] as String,
            at: (m['at'] as DateTime).toUtc(),
          );
        }(),
    ];
  }
}
