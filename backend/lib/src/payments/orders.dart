import 'package:uuid/uuid.dart';

import '../persistence/changes.dart';

enum PaymentProvider { click, payme, googlePay, applePay }

enum OrderStatus { pending, processing, paid, cancelled, refunded }

/// To'lov buyurtmasi. Summa serverda qabul narxidan olinadi — mijoz yuborgan
/// summaga hech qachon ishonilmaydi.
class PaymentOrder {
  PaymentOrder({
    required this.id,
    required this.appointmentId,
    required this.userId,
    required this.amountUzs,
    required this.provider,
  });

  final String id;
  final String appointmentId;
  final String userId;
  final int amountUzs;
  final PaymentProvider provider;
  OrderStatus status = OrderStatus.pending;
  String? providerTxnId;
  DateTime? paidAt;

  int get amountTiyin => amountUzs * 100;

  Map<String, dynamic> toJson() => {
    'id': id,
    'appointmentId': appointmentId,
    'amountUzs': amountUzs,
    'provider': provider.name,
    'status': status.name,
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
        'providerTxnId': o.providerTxnId,
        'paidAt': o.paidAt?.toIso8601String(),
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
            )
            ..status = OrderStatus.values.byName(r['status'] as String)
            ..providerTxnId = j['providerTxnId'] as String?
            ..paidAt = j['paidAt'] == null
                ? null
                : DateTime.parse(j['paidAt'] as String);
      _orders[o.id] = o;
    }
  }
}
