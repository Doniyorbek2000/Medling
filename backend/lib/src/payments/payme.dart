import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../persistence/changes.dart';
import 'orders.dart';

class PaymeError implements Exception {
  PaymeError(this.code, this.uz, {this.data});
  final int code;
  final String uz;
  final String? data;

  Map<String, Object?> toJson() => {
    'code': code,
    'message': {'uz': uz, 'ru': uz, 'en': uz},
    if (data != null) 'data': data,
  };
}

class _PaymeTxn {
  _PaymeTxn(
    this.paymeId,
    this.orderId,
    this.amount,
    this.time, {
    String? id,
    int? createTime,
  }) : id = id ?? const Uuid().v4(),
       createTime = createTime ?? DateTime.now().millisecondsSinceEpoch;
  final String id;
  final String paymeId;
  final String orderId;
  final int amount;
  final int time; // Payme vaqti (ms)
  final int createTime;
  int performTime = 0;
  int cancelTime = 0;
  int state = 1; // 1 yaratildi, 2 bajarildi, -1/-2 bekor qilindi
  int? reason;
}

/// Payme Merchant API (JSON-RPC 2.0).
/// Hujjat: https://developer.help.paycom.uz/metody-merchant-api/
class PaymeMerchant {
  PaymeMerchant({
    required this.merchantId,
    required this.key,
    required this.orders,
    required this.onPaid,
    required this.onRefunded,
    this.testMode = true,
  });

  final String merchantId;
  final String key;
  final OrderRepository orders;
  final void Function(PaymentOrder) onPaid;
  final void Function(PaymentOrder) onRefunded;
  final bool testMode;

  static const timeoutMs = 12 * 60 * 60 * 1000;
  final _txns = <String, _PaymeTxn>{};

  /// Tranzaksiya va uning buyurtmasini bazaga yozish uchun belgilaydi.
  void _persist(_PaymeTxn t) {
    changes.save(
      'payme_transactions',
      t.paymeId,
      () => (
        columns: {'order_id': t.orderId},
        data: {
          'id': t.id,
          'amount': t.amount,
          'time': t.time,
          'createTime': t.createTime,
          'performTime': t.performTime,
          'cancelTime': t.cancelTime,
          'state': t.state,
          'reason': t.reason,
        },
      ),
    );
    final o = orders.byId(t.orderId);
    if (o != null) orders.persist(o);
  }

  /// Ishga tushganda bazadan tiklash.
  void restore(List<Map<String, dynamic>> rows) {
    for (final r in rows) {
      final j = r['data'] as Map<String, dynamic>;
      _txns[r['id'] as String] =
          _PaymeTxn(
              r['id'] as String,
              r['order_id'] as String,
              j['amount'] as int,
              j['time'] as int,
              id: j['id'] as String,
              createTime: j['createTime'] as int,
            )
            ..performTime = j['performTime'] as int
            ..cancelTime = j['cancelTime'] as int
            ..state = j['state'] as int
            ..reason = j['reason'] as int?;
    }
  }

  Uri checkoutUrl(PaymentOrder o, String returnUrl) {
    final params =
        'm=$merchantId;ac.order_id=${o.id};a=${o.amountTiyin};c=$returnUrl';
    final host = testMode ? 'checkout.test.paycom.uz' : 'checkout.paycom.uz';
    return Uri.parse('https://$host/${base64.encode(utf8.encode(params))}');
  }

  bool authorized(String? header) {
    if (header == null || !header.startsWith('Basic ')) return false;
    final expected = base64.encode(utf8.encode('Paycom:$key'));
    final given = header.substring(6).trim();
    if (given.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < given.length; i++) {
      diff |= given.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Bitta JSON-RPC so'rovini qayta ishlaydi. HTTP holati doim 200.
  Map<String, Object?> handle(String? authHeader, String body) {
    Object? id;
    try {
      final req = jsonDecode(body) as Map<String, dynamic>;
      id = req['id'];
      if (!authorized(authHeader)) {
        throw PaymeError(-32504, 'Ruxsat yo\'q');
      }
      final params = (req['params'] as Map?)?.cast<String, dynamic>() ?? {};
      final result = switch (req['method']) {
        'CheckPerformTransaction' => _checkPerform(params),
        'CreateTransaction' => _create(params),
        'PerformTransaction' => _perform(params),
        'CancelTransaction' => _cancel(params),
        'CheckTransaction' => _check(params),
        'GetStatement' => _statement(params),
        _ => throw PaymeError(-32601, 'Metod topilmadi'),
      };
      return {'jsonrpc': '2.0', 'id': id, 'result': result};
    } on PaymeError catch (e) {
      return {'jsonrpc': '2.0', 'id': id, 'error': e.toJson()};
    } on FormatException {
      return {
        'jsonrpc': '2.0',
        'id': id,
        'error': PaymeError(-32700, 'JSON xatosi').toJson(),
      };
    } on TypeError {
      return {
        'jsonrpc': '2.0',
        'id': id,
        'error': PaymeError(-32600, 'Noto\'g\'ri so\'rov').toJson(),
      };
    }
  }

  PaymentOrder _validOrder(Map<String, dynamic> p) {
    final orderId = (p['account'] as Map?)?['order_id'] as String?;
    final o = orderId == null ? null : orders.byId(orderId);
    if (o == null || o.provider != PaymentProvider.payme) {
      throw PaymeError(-31050, 'Buyurtma topilmadi', data: 'order_id');
    }
    if (o.status == OrderStatus.paid || o.status == OrderStatus.cancelled) {
      throw PaymeError(
        -31051,
        'Buyurtma to\'lab bo\'lingan yoki bekor qilingan',
        data: 'order_id',
      );
    }
    if (p['amount'] != o.amountTiyin) {
      throw PaymeError(-31001, 'Noto\'g\'ri summa');
    }
    return o;
  }

  Map<String, Object?> _checkPerform(Map<String, dynamic> p) {
    _validOrder(p);
    return {'allow': true};
  }

  _PaymeTxn _txn(Map<String, dynamic> p) =>
      _txns[p['id']] ?? (throw PaymeError(-31003, 'Tranzaksiya topilmadi'));

  bool _expired(_PaymeTxn t) =>
      DateTime.now().millisecondsSinceEpoch - t.createTime > timeoutMs;

  void _cancelTxn(_PaymeTxn t, int reason) {
    final o = orders.byId(t.orderId)!;
    t
      ..cancelTime = DateTime.now().millisecondsSinceEpoch
      ..reason = reason;
    if (t.state == 2) {
      t.state = -2;
      o.status = OrderStatus.refunded;
      onRefunded(o);
    } else {
      t.state = -1;
      o.status = OrderStatus.pending;
    }
    _persist(t);
  }

  Map<String, Object?> _create(Map<String, dynamic> p) {
    final existing = _txns[p['id']];
    if (existing != null) {
      if (existing.state != 1) {
        throw PaymeError(-31008, 'Amalni bajarib bo\'lmaydi');
      }
      if (_expired(existing)) {
        _cancelTxn(existing, 4);
        throw PaymeError(-31008, 'Tranzaksiya muddati o\'tgan');
      }
      return _createResult(existing);
    }
    final o = _validOrder(p);
    // Bitta buyurtma uchun faqat bitta faol tranzaksiya.
    final busy = _txns.values.any((t) => t.orderId == o.id && t.state == 1);
    if (busy) {
      throw PaymeError(-31099, 'Buyurtma boshqa to\'lovda', data: 'order_id');
    }
    final t = _PaymeTxn(
      p['id'] as String,
      o.id,
      p['amount'] as int,
      p['time'] as int,
    );
    _txns[t.paymeId] = t;
    o
      ..status = OrderStatus.processing
      ..providerTxnId = t.paymeId;
    _persist(t);
    return _createResult(t);
  }

  Map<String, Object?> _createResult(_PaymeTxn t) => {
    'create_time': t.createTime,
    'transaction': t.id,
    'state': t.state,
  };

  Map<String, Object?> _perform(Map<String, dynamic> p) {
    final t = _txn(p);
    if (t.state == 1) {
      if (_expired(t)) {
        _cancelTxn(t, 4);
        throw PaymeError(-31008, 'Tranzaksiya muddati o\'tgan');
      }
      final o = orders.byId(t.orderId)!;
      t
        ..state = 2
        ..performTime = DateTime.now().millisecondsSinceEpoch;
      o
        ..status = OrderStatus.paid
        ..paidAt = DateTime.now().toUtc();
      _persist(t);
      onPaid(o);
    } else if (t.state != 2) {
      throw PaymeError(-31008, 'Amalni bajarib bo\'lmaydi');
    }
    return {
      'transaction': t.id,
      'perform_time': t.performTime,
      'state': t.state,
    };
  }

  Map<String, Object?> _cancel(Map<String, dynamic> p) {
    final t = _txn(p);
    if (t.state == 1 || t.state == 2) _cancelTxn(t, p['reason'] as int? ?? 0);
    return {'transaction': t.id, 'cancel_time': t.cancelTime, 'state': t.state};
  }

  Map<String, Object?> _txnJson(_PaymeTxn t) => {
    'create_time': t.createTime,
    'perform_time': t.performTime,
    'cancel_time': t.cancelTime,
    'transaction': t.id,
    'state': t.state,
    'reason': t.reason,
  };

  Map<String, Object?> _check(Map<String, dynamic> p) => _txnJson(_txn(p));

  Map<String, Object?> _statement(Map<String, dynamic> p) {
    final from = p['from'] as int, to = p['to'] as int;
    return {
      'transactions': [
        for (final t in _txns.values)
          if (t.time >= from && t.time <= to)
            {
              'id': t.paymeId,
              'time': t.time,
              'amount': t.amount,
              'account': {'order_id': t.orderId},
              ..._txnJson(t),
            },
      ],
    };
  }
}
