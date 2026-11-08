/// Bazaga yoziladigan qator: indekslangan ustunlar + qolgan maydonlar (JSONB).
typedef RowData = ({Map<String, Object?> columns, Map<String, Object?> data});

sealed class ChangeOp {
  const ChangeOp(this.table);
  final String table;
}

/// Qatorni qo'shish yoki yangilash. [build] bazaga yozish paytida chaqiriladi,
/// shuning uchun obyektning so'nggi holati yoziladi.
final class SaveOp extends ChangeOp {
  const SaveOp(super.table, this.id, this.build);
  final String id;
  final RowData Function() build;
}

/// `DELETE FROM table WHERE column = value`.
final class DeleteOp extends ChangeOp {
  const DeleteOp(super.table, this.column, this.value);
  final String column;
  final String value;
}

/// "Unit of work": so'rov davomida o'zgargan obyektlar ro'yxati.
///
/// Servislar holatni xotirada saqlaydi va har bir o'zgarishni shu yerda
/// belgilaydi. HTTP javobi qaytishidan oldin barcha o'zgarishlar bitta
/// tranzaksiyada PostgreSQL'ga yoziladi (`PersistenceMiddleware`). Baza
/// ulanmagan bo'lsa (testlar, dev) — hech narsa qilinmaydi.
class Changes {
  Changes._();

  /// Ilova bo'yicha yagona jurnal.
  static final instance = Changes._();

  /// Yoqilmagan bo'lsa, o'zgarishlar yig'ilmaydi (xotira o'smasligi uchun).
  bool enabled = false;

  final _ops = <ChangeOp>[];

  bool get isEmpty => _ops.isEmpty;
  int get length => _ops.length;

  void save(String table, String id, RowData Function() build) {
    if (!enabled) return;
    // Bir qator uchun faqat oxirgi yozuv — jurnal oxiriga ko'chiriladi.
    _ops.removeWhere((o) => o is SaveOp && o.table == table && o.id == id);
    _ops.add(SaveOp(table, id, build));
  }

  void delete(String table, String column, String value) {
    if (!enabled) return;
    _ops.add(DeleteOp(table, column, value));
  }

  /// Jurnalni olib, bo'shatadi.
  List<ChangeOp> drain() {
    final out = List<ChangeOp>.of(_ops);
    _ops.clear();
    return out;
  }

  /// Yozish muvaffaqiyatsiz bo'lsa — keyingi urinish uchun qaytariladi.
  void restore(List<ChangeOp> ops) {
    if (!enabled) return;
    _ops.insertAll(0, ops);
  }
}

/// Qisqa yozuv.
Changes get changes => Changes.instance;
