import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';

enum PayMethod { click, payme, googlePay, applePay }

/// To'lov usullari:
/// * Click, Payme — rasmiy to'lov sahifasi orqali (karta ma'lumotlari ilovaga
///   kirmaydi), natija server webhook'i orqali tasdiqlanadi.
/// * Google Pay (Android), Apple Pay (iOS) — `pay` paketi token beradi, token
///   faqat MedLink serveriga yuboriladi.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.appointment});
  final Appointment appointment;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  PayMethod? _method;
  bool _busy = false;
  String? _pendingOrderId;
  bool _paid = false;
  Pay? _pay;
  bool _walletAvailable = false;

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWallet();
  }

  Future<void> _initWallet() async {
    if (!_isIos && !_isAndroid) return;
    try {
      final provider = _isIos ? PayProvider.apple_pay : PayProvider.google_pay;
      final config = await PaymentConfiguration.fromAsset(
        _isIos ? 'pay/apple_pay.json' : 'pay/google_pay.json',
      );
      final pay = Pay({provider: config});
      final can = await pay.userCanPay(provider);
      if (mounted) {
        setState(() {
          _pay = pay;
          _walletAvailable = can;
        });
      }
    } catch (_) {
      // Qurilmada hamyon sozlanmagan — usul ko'rsatilmaydi.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Foydalanuvchi Click/Payme sahifasidan qaytganda holatni tekshiramiz.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingOrderId != null) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final id = _pendingOrderId;
    if (id == null) return;
    try {
      final res = await context.read<Session>().api.get('/v1/payments/$id');
      if (res['status'] == 'paid' && mounted) setState(() => _paid = true);
    } catch (_) {}
  }

  Future<void> _payRedirect(String provider) async {
    final api = context.read<Session>().api;
    final res = await api.post('/v1/payments/checkout', {
      'appointmentId': widget.appointment.id,
      'provider': provider,
    });
    _pendingOrderId = res['id'] as String;
    await launchUrl(
      Uri.parse(res['checkoutUrl'] as String),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _payWallet() async {
    final api = context.read<Session>().api;
    final provider = _isIos ? PayProvider.apple_pay : PayProvider.google_pay;
    final result = await _pay!.showPaymentSelector(provider, [
      PaymentItem(
        label: 'MedLink qabul',
        amount: widget.appointment.priceUzs.toString(),
        status: PaymentItemStatus.final_price,
      ),
    ]);
    final String token;
    if (_isIos) {
      // Apple Pay: PKPaymentToken.paymentData (base64) — server Stripe orqali
      // tokenga aylantiradi.
      token = result['token'] as String;
    } else {
      // Google Pay + Stripe gateway: tokenizationData.token ichida Stripe token.
      final raw =
          (result['paymentMethodData'] as Map)['tokenizationData']['token']
              as String;
      token = (jsonDecode(raw) as Map<String, dynamic>)['id'] as String;
    }
    final res = await api.post('/v1/payments/wallet', {
      'appointmentId': widget.appointment.id,
      'provider': _isIos ? 'applePay' : 'googlePay',
      'token': token,
    });
    if (res['status'] == 'paid' && mounted) setState(() => _paid = true);
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      switch (_method!) {
        case PayMethod.click:
          await _payRedirect('click');
        case PayMethod.payme:
          await _payRedirect('payme');
        case PayMethod.googlePay:
        case PayMethod.applePay:
          await _payWallet();
      }
    } on ApiError catch (e) {
      if (mounted) showError(context, e);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('To\'lov amalga oshmadi')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    if (_paid) return _SuccessView(appointment: a);

    return Scaffold(
      appBar: AppBar(title: const Text('To\'lov')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(a.doctor?.fullName ?? 'Qabul'),
              subtitle: Text(formatDateTime(a.startsAt)),
              trailing: Text(
                formatUzs(a.priceUzs),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Brand.blue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('To\'lov usuli', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          RadioGroup<PayMethod>(
            groupValue: _method,
            onChanged: (v) => setState(() => _method = v),
            child: Column(
              children: [
                _option(
                  PayMethod.click,
                  'Click',
                  'Uzcard, Humo',
                  const Color(0xFF00A2E8),
                ),
                _option(
                  PayMethod.payme,
                  'Payme',
                  'Uzcard, Humo',
                  const Color(0xFF33CCCC),
                ),
                if (_isAndroid && _walletAvailable)
                  _option(
                    PayMethod.googlePay,
                    'Google Pay',
                    'Visa, Mastercard',
                    Colors.black87,
                  ),
                if (_isIos && _walletAvailable)
                  _option(
                    PayMethod.applePay,
                    'Apple Pay',
                    'Visa, Mastercard',
                    Colors.black,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _method != null && !_busy ? _submit : null,
            child: _busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('To\'lash · ${formatUzs(a.priceUzs)}'),
          ),
          if (_pendingOrderId != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _checkStatus,
              child: const Text('To\'lovni tekshirish'),
            ),
          ],
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Karta ma\'lumotlari MedLink serverlarida saqlanmaydi.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option(PayMethod m, String title, String subtitle, Color color) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          child: RadioListTile<PayMethod>(
            value: m,
            title: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
            subtitle: Text(subtitle),
          ),
        ),
      );
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Brand.success, size: 96),
            const SizedBox(height: 16),
            Text(
              'Qabul tasdiqlandi',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${appointment.doctor?.fullName ?? ''}\n'
              '${formatDateTime(appointment.startsAt)}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Bosh sahifaga'),
            ),
          ],
        ),
      ),
    ),
  );
}
