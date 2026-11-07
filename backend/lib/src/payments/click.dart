import 'package:crypto/crypto.dart';

import 'dart:convert';

import 'orders.dart';

/// CLICK Shop API (merchant tomoni): Prepare (action=0) va Complete (action=1).
/// Hujjat: https://docs.click.uz/click-api-request/
class ClickMerchant {
  ClickMerchant({
    required this.serviceId,
    required this.merchantId,
    required this.secretKey,
    required this.orders,
    required this.onPaid,
  });

  final String serviceId;
  final String merchantId;
  final String secretKey;
  final OrderRepository orders;
  final void Function(PaymentOrder) onPaid;

  /// click_trans_id -> merchant_prepare_id
  final _prepared = <String, int>{};
  int _seq = 1000;

  Uri checkoutUrl(PaymentOrder o, String returnUrl) =>
      Uri.https('my.click.uz', '/services/pay', {
        'service_id': serviceId,
        'merchant_id': merchantId,
        'amount': o.amountUzs.toString(),
        'transaction_param': o.id,
        'return_url': returnUrl,
      });

  String sign(Map<String, String> p, {required bool complete}) => md5
      .convert(
        utf8.encode(
          [
            p['click_trans_id'],
            p['service_id'],
            secretKey,
            p['merchant_trans_id'],
            if (complete) p['merchant_prepare_id'],
            p['amount'],
            p['action'],
            p['sign_time'],
          ].map((e) => e ?? '').join(),
        ),
      )
      .toString();

  Map<String, Object?> _resp(
    Map<String, String> p,
    int error,
    String note, {
    Object? prepareId,
    Object? confirmId,
  }) => {
    'click_trans_id': p['click_trans_id'],
    'merchant_trans_id': p['merchant_trans_id'],
    'merchant_prepare_id': ?prepareId,
    'merchant_confirm_id': ?confirmId,
    'error': error,
    'error_note': note,
  };

  bool _amountOk(PaymentOrder o, String? amount) {
    final a = double.tryParse(amount ?? '');
    return a != null && (a - o.amountUzs).abs() < 0.01;
  }

  bool _signOk(Map<String, String> p, {required bool complete}) {
    final given = p['sign_string'] ?? '';
    final expected = sign(p, complete: complete);
    if (given.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < given.length; i++) {
      diff |= given.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return diff == 0;
  }

  Map<String, Object?> prepare(Map<String, String> p) {
    if (!_signOk(p, complete: false)) return _resp(p, -1, 'SIGN CHECK FAILED');
    if (p['action'] != '0') return _resp(p, -3, 'Action not found');
    if (p['service_id'] != serviceId) return _resp(p, -8, 'Error in request');
    final o = orders.byId(p['merchant_trans_id'] ?? '');
    if (o == null) return _resp(p, -5, 'Order not found');
    if (o.status == OrderStatus.paid) return _resp(p, -4, 'Already paid');
    if (o.status == OrderStatus.cancelled) {
      return _resp(p, -9, 'Transaction cancelled');
    }
    if (!_amountOk(o, p['amount'])) return _resp(p, -2, 'Incorrect amount');
    final prepId = _prepared.putIfAbsent(
      p['click_trans_id'] ?? '',
      () => ++_seq,
    );
    o
      ..status = OrderStatus.processing
      ..providerTxnId = p['click_trans_id'];
    return _resp(p, 0, 'Success', prepareId: prepId);
  }

  Map<String, Object?> complete(Map<String, String> p) {
    if (!_signOk(p, complete: true)) return _resp(p, -1, 'SIGN CHECK FAILED');
    if (p['action'] != '1') return _resp(p, -3, 'Action not found');
    final o = orders.byId(p['merchant_trans_id'] ?? '');
    if (o == null) return _resp(p, -5, 'Order not found');
    final prepId = _prepared[p['click_trans_id'] ?? ''];
    if (prepId == null || '$prepId' != p['merchant_prepare_id']) {
      return _resp(p, -6, 'Transaction not found');
    }
    if (o.status == OrderStatus.paid) {
      return _resp(p, -4, 'Already paid', confirmId: prepId);
    }
    if (o.status == OrderStatus.cancelled) {
      return _resp(p, -9, 'Transaction cancelled');
    }
    if (!_amountOk(o, p['amount'])) return _resp(p, -2, 'Incorrect amount');
    // CLICK tomonida xato bo'lsa (error < 0) — buyurtma bekor qilinadi.
    if ((int.tryParse(p['error'] ?? '0') ?? 0) < 0) {
      o.status = OrderStatus.cancelled;
      return _resp(p, -9, 'Transaction cancelled');
    }
    o
      ..status = OrderStatus.paid
      ..paidAt = DateTime.now().toUtc();
    onPaid(o);
    return _resp(p, 0, 'Success', confirmId: prepId);
  }
}
