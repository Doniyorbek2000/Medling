import 'dart:async';

import 'package:app_links/app_links.dart';

/// `medlink://payment-result?order=<id>` — Click/Payme sahifasidan qaytish.
class DeepLinks {
  DeepLinks([AppLinks? links]) : _links = links;
  final AppLinks? _links;
  final _payments = StreamController<String>.broadcast();
  StreamSubscription<Uri>? _sub;

  /// To'lov sahifasidan qaytgan buyurtma ID'lari.
  Stream<String> get paymentReturns => _payments.stream;

  void start() {
    try {
      final links = _links ?? AppLinks();
      _sub = links.uriLinkStream.listen(_handle, onError: (_) {});
    } catch (_) {
      // Platforma qo'llab-quvvatlamaydi (masalan, testlar).
    }
  }

  void _handle(Uri uri) {
    if (uri.scheme == 'medlink' && uri.host == 'payment-result') {
      final order = uri.queryParameters['order'];
      if (order != null) _payments.add(order);
    }
  }

  void dispose() {
    _sub?.cancel();
    _payments.close();
  }
}
