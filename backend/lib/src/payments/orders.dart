import 'package:uuid/uuid.dart';

import '../persistence/changes.dart';

enum PaymentProvider { click, payme, googlePay, applePay }

enum OrderStatus { pending, processing, paid, cancelled, refunded }

/// Pul qaytarish holati. Click va Payme'da qaytarish provayder kabineti
/// orqali amalga oshiriladi; admin bajargach, ilovada "qaytarildi" deb
/// belgilaydi (Payme CancelTransaction kelsa — avtomatik).
enum RefundStatus { none, requested, refunded }

/// To'lov buyurtmasi. Summa serverda qabul narxidan olinadi — mijoz yuborgan
/// summaga hech qachon ishonilmaydi.
class PaymentOrder {
  PaymentOrder({
    required this.id,
    required this.appointmentId,
    required this.userId,
    required this.amountUzs,
    required this.provider,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final DateTime createdAt;
  final String appointmentId;
  final String userId;
  final int amountUzs;
  final PaymentProvider provider;
  OrderStatus status = OrderStatus.pending;
  String? providerTxnId;
  DateTime? paidAt;

  RefundStatus refundStatus = RefundStatus.none;
  String? refundReason;
  DateTime? refundRequestedAt;
  DateTime? refundedAt;

  int get amountTiyin => amountUzs * 100;

  Map<String, dynamic> toJson() => {
    'id': id,
    'appointmentId': appointmentId,
    'amountUzs': amountUzs,
    'provider': provider.name,
    'status': status.name,
    'refundStatus': refundStatus.name,
  };
}

class OrderRepository {
  final _orders = <String, PaymentOrder>{};

  PaymentOrder create({
    required String appointmentId,
    required String userId,
    required int amountUzs,
    required PaymentProvider provider,
  }) {
    final o = PaymentOrder(
      id: const Uuid().v4(),
      appointmentId: appointmentId,
      userId: userId,
      amountUzs: amountUzs,
      provider: provider,
    );
    _orders[o.id] = o;
    persist(o);
    return o;
  }

  PaymentOrder? byId(String id) => _orders[id];

  Iterable<PaymentOrder> get all => _orders.values;

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);

  /// Qabul muddati o'tganda boshlangan, lekin yakunlanmagan to'lovlar bekor
  /// qilinadi — keyin kelgan Click/Payme so'rovi rad etiladi.
  void cancelPendingFor(String appointmentId) {
    for (final o in _orders.values) {
      if (o.appointmentId == appointmentId &&
          (o.status == OrderStatus.pending ||
              o.status == OrderStatus.processing)) {
        o.status = OrderStatus.cancelled;
        persist(o);
      }
    }
  }

  /// Qabul uchun to'langan buyurtma (bo'lsa).
  PaymentOrder? paidOrderFor(String appointmentId) => _orders.values
      .where(
        (o) => o.appointmentId == appointmentId && o.status == OrderStatus.paid,
      )
      .firstOrNull;

  /// Qabul bo'yicha pul qaytarish holati (ilovada ko'rsatish uchun).
  RefundStatus refundFor(String appointmentId) =>
      _orders.values
          .where(
            (o) =>
                o.appointmentId == appointmentId &&
                o.refundStatus != RefundStatus.none,
          )
          .firstOrNull
          ?.refundStatus ??
      RefundStatus.none;

  void requestRefund(PaymentOrder o, String reason) {
    if (o.refundStatus != RefundStatus.none) return;
    o
      ..refundStatus = RefundStatus.requested
      ..refundReason = reason
      ..refundRequestedAt = DateTime.now().toUtc();
    persist(o);
  }

  void completeRefund(PaymentOrder o) {
    o
      ..refundStatus = RefundStatus.refunded
      ..refundedAt = DateTime.now().toUtc()
      ..status = OrderStatus.refunded;
    persist(o);
  }

  List<PaymentOrder> pendingRefunds() =>
      _orders.values
          .where((o) => o.refundStatus == RefundStatus.requested)
          .toList()
        ..sort((a, b) => a.refundRequestedAt!.compareTo(b.refundRequestedAt!));

  /// Buyurtmani bazaga yozish uchun belgilaydi (holat o'zgarganda chaqiring).
  void persist(PaymentOrder o) => changes.save(
    'payment_orders',
    o.id,
    () => (
      columns: {
        'appointment_id': o.appointmentId,
        'user_id': o.userId,
        'status': o.status.name,
      },
      data: {
        'amountUzs': o.amountUzs,
        'provider': o.provider.name,
        'createdAt': o.createdAt.toIso8601String(),
        'providerTxnId': o.providerTxnId,
        'paidAt': o.paidAt?.toIso8601String(),
        'refundStatus': o.refundStatus.name,
        'refundReason': o.refundReason,
        'refundRequestedAt': o.refundRequestedAt?.toIso8601String(),
        'refundedAt': o.refundedAt?.toIso8601String(),
      },
    ),
  );

  void restore(List<Map<String, dynamic>> rows) {
    for (final r in rows) {
      final j = r['data'] as Map<String, dynamic>;
      final o =
          PaymentOrder(
              id: r['id'] as String,
              appointmentId: r['appointment_id'] as String,
              userId: r['user_id'] as String,
              amountUzs: j['amountUzs'] as int,
              provider: PaymentProvider.values.byName(j['provider'] as String),
              createdAt: _date(j['createdAt']) ?? _date(j['paidAt']),
            )
            ..status = OrderStatus.values.byName(r['status'] as String)
            ..providerTxnId = j['providerTxnId'] as String?
            ..paidAt = j['paidAt'] == null
                ? null
                : DateTime.parse(j['paidAt'] as String)
            ..refundStatus = RefundStatus.values.byName(
              j['refundStatus'] as String? ?? 'none',
            )
            ..refundReason = j['refundReason'] as String?
            ..refundRequestedAt = _date(j['refundRequestedAt'])
            ..refundedAt = _date(j['refundedAt']);
      _orders[o.id] = o;
    }
  }
}
