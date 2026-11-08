import 'dart:convert';

import 'package:http/http.dart' as http;

import 'orders.dart';

bool isWallet(PaymentProvider p) =>
    p == PaymentProvider.googlePay || p == PaymentProvider.applePay;

/// Google Pay / Apple Pay token'larini qabul qiluvchi xalqaro ekvayer
/// (bu yerda Stripe). Mobil ilova `pay` paketi orqali token oladi va uni
/// faqat serverga yuboradi; karta ma'lumotlari serverimizga tushmaydi
/// (PCI DSS doirasi minimal).
abstract class WalletGateway {
  /// Muvaffaqiyatli bo'lsa — provayder to'lov identifikatori, aks holda null.
  Future<String?> charge(PaymentOrder order, String token);

  /// To'liq pul qaytarish (avtomatik). Muvaffaqiyatli bo'lsa true; aks holda
  /// qaytarish admin navbatida qoladi.
  Future<bool> refund(PaymentOrder order);
}

class StripeWalletGateway implements WalletGateway {
  StripeWalletGateway(this.client, this.secretKey);
  final http.Client client;
  final String secretKey;

  /// Apple Pay: qurilmadan kelgan `PKPaymentToken.paymentData` avval Stripe
  /// kartasi tokeniga aylantiriladi. Google Pay (Stripe gateway) esa tayyor
  /// `tok_...` beradi.
  Future<String?> _toStripeToken(PaymentOrder order, String token) async {
    if (order.provider != PaymentProvider.applePay) return token;
    final res = await client.post(
      Uri.parse('https://api.stripe.com/v1/tokens'),
      headers: {'authorization': 'Bearer $secretKey'},
      body: {'pk_token': utf8.decode(base64.decode(token))},
    );
    if (res.statusCode != 200) return null;
    return (jsonDecode(res.body) as Map<String, dynamic>)['id'] as String?;
  }

  @override
  Future<String?> charge(PaymentOrder order, String token) async {
    final stripeToken = await _toStripeToken(order, token);
    if (stripeToken == null) return null;
    final res = await client.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'authorization': 'Bearer $secretKey',
        'content-type': 'application/x-www-form-urlencoded',
        // Qayta urinishda ikki marta yechib olinmasligi uchun.
        'idempotency-key': 'medlink-${order.id}',
      },
      body: {
        'amount': order.amountTiyin.toString(),
        'currency': 'uzs',
        'confirm': 'true',
        'payment_method_data[type]': 'card',
        'payment_method_data[card][token]': stripeToken,
        'metadata[order_id]': order.id,
        'description': 'MedLink qabul',
      },
    );
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return j['status'] == 'succeeded' ? j['id'] as String? : null;
  }

  /// Stripe Refunds API: to'lov kartaga qaytariladi (odatda 5–10 kun).
  @override
  Future<bool> refund(PaymentOrder order) async {
    final intent = order.providerTxnId;
    if (intent == null || secretKey.isEmpty) return false;
    try {
      final res = await client.post(
        Uri.parse('https://api.stripe.com/v1/refunds'),
        headers: {
          'authorization': 'Bearer $secretKey',
          'content-type': 'application/x-www-form-urlencoded',
          'idempotency-key': 'medlink-refund-${order.id}',
        },
        body: {'payment_intent': intent, 'metadata[order_id]': order.id},
      );
      if (res.statusCode != 200) return false;
      final status = (jsonDecode(res.body) as Map<String, dynamic>)['status'];
      return status == 'succeeded' || status == 'pending';
    } on Exception {
      return false;
    }
  }
}
