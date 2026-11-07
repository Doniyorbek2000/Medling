import 'package:uuid/uuid.dart';

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
    return o;
  }

  PaymentOrder? byId(String id) => _orders[id];
}
