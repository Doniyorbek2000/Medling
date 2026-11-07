import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pay/pay.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/deep_links.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';
import '../doctors/specialty.dart';

enum PayMethod { click, payme, googlePay, applePay }

/// To'lov usullari:
/// * Click, Payme — rasmiy to'lov sahifasi orqali (karta ma'lumotlari ilovaga
///   kirmaydi), natija server webhook'i orqali tasdiqlanadi va ilovaga
///   `medlink://payment-result` deep link orqali qaytiladi.
/// * Google Pay (Android), Apple Pay (iOS) — `pay` paketi token beradi, token
///   faqat MedLink serveriga yuboriladi.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.appointment});
  final Appointment appointment;

  static const holdDuration = Duration(minutes: 15);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  PayMethod? _method;
  bool _busy = false;
  bool _checking = false;
  String? _pendingOrderId;
  bool _paid = false;
  Pay? _pay;
  bool _walletAvailable = false;
  StreamSubscription<String>? _linkSub;
  Timer? _ticker;
  late final DateTime _holdUntil = DateTime.now().add(
    PaymentScreen.holdDuration,
  );

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  Duration get _left => _holdUntil.difference(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWallet();
    _linkSub = context.read<DeepLinks>().paymentReturns.listen((orderId) {
      if (orderId == _pendingOrderId) _checkStatus();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
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
    _linkSub?.cancel();
    _ticker?.cancel();
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
    if (id == null || _checking) return;
    setState(() => _checking = true);
    final repo = context.read<MedLinkRepository>();
    try {
      // Webhook bir necha soniya kechikishi mumkin — 3 marta tekshiramiz.
      for (var i = 0; i < 3 && mounted; i++) {
        final status = await repo.orderStatus(id);
        if (status == 'paid') {
          HapticFeedback.heavyImpact();
          if (mounted) setState(() => _paid = true);
          return;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (mounted) showMessage(context, context.l10n.paymentNotYet);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _payRedirect(String provider) async {
    final r = await context.read<MedLinkRepository>().checkout(
      widget.appointment.id,
      provider,
    );
    setState(() => _pendingOrderId = r.orderId);
    await launchUrl(r.checkoutUrl, mode: LaunchMode.externalApplication);
  }

  Future<void> _payWallet() async {
    final repo = context.read<MedLinkRepository>();
    final provider = _isIos ? PayProvider.apple_pay : PayProvider.google_pay;
    final result = await _pay!.showPaymentSelector(provider, [
      PaymentItem(
        label: 'MedLink',
        amount: widget.appointment.priceUzs.toString(),
        status: PaymentItemStatus.final_price,
      ),
    ]);
    final String token;
    if (_isIos) {
      // Apple Pay: PKPaymentToken.paymentData — server Stripe tokeniga aylantiradi.
      token = result['token'] as String;
    } else {
      // Google Pay + Stripe gateway: tokenizationData.token ichida Stripe token.
      final raw =
          (result['paymentMethodData'] as Map)['tokenizationData']['token']
              as String;
      token = (jsonDecode(raw) as Map<String, dynamic>)['id'] as String;
    }
    final ok = await repo.payWithWallet(
      widget.appointment.id,
      _isIos ? 'applePay' : 'googlePay',
      token,
    );
    if (!mounted) return;
    if (ok) {
      HapticFeedback.heavyImpact();
      setState(() => _paid = true);
    } else {
      showMessage(context, context.l10n.paymentFailed);
    }
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
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = widget.appointment;
    if (_paid) return _SuccessView(appointment: a);
    final expired = _left.isNegative;
    final mm = _left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _left.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: Text(l.payment)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Avatar(initials: a.doctor?.initials ?? '?', radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.doctor?.fullName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (a.doctor != null)
                          Text(specialtyName(l, a.doctor!.specialty)),
                        Text(
                          context.fmt.dateTime(a.startsAt),
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (expired ? Brand.danger : Brand.warning).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: expired ? Brand.danger : Brand.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(expired ? l.holdExpired : l.holdLeft('$mm:$ss')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.paymentMethod,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<PayMethod>(
            groupValue: _method,
            onChanged: (v) => setState(() => _method = v),
            child: Column(
              children: [
                _option(
                  PayMethod.click,
                  'Click',
                  l.localCards,
                  const Color(0xFF00A2E8),
                  Icons.credit_card,
                ),
                _option(
                  PayMethod.payme,
                  'Payme',
                  l.localCards,
                  const Color(0xFF26B5B5),
                  Icons.account_balance_wallet,
                ),
                if (_isAndroid && _walletAvailable)
                  _option(
                    PayMethod.googlePay,
                    'Google Pay',
                    l.intlCards,
                    context.colors.onSurface,
                    Icons.g_mobiledata_rounded,
                  ),
                if (_isIos && _walletAvailable)
                  _option(
                    PayMethod.applePay,
                    'Apple Pay',
                    l.intlCards,
                    context.colors.onSurface,
                    Icons.apple,
                  ),
              ],
            ),
          ),
          if (_pendingOrderId != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _checking ? null : _checkStatus,
              icon: _checking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(l.checkPayment),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.cardSafety,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ProgressButton(
            label: l.payAmount(context.fmt.money(a.priceUzs)),
            busy: _busy,
            onPressed: _method != null && !expired ? _submit : null,
          ),
        ),
      ),
    );
  }

  Widget _option(
    PayMethod m,
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: _method == m
              ? context.colors.primary
              : context.colors.outlineVariant,
          width: _method == m ? 1.6 : 1,
        ),
      ),
      child: RadioListTile<PayMethod>(
        value: m,
        controlAffinity: ListTileControlAffinity.trailing,
        secondary: Icon(icon, color: color, size: 30),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
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
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Brand.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Brand.success,
                    size: 72,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l.appointmentConfirmed,
                textAlign: TextAlign.center,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${appointment.doctor?.fullName ?? ''}\n'
                '${context.fmt.dateTime(appointment.startsAt)}',
                textAlign: TextAlign.center,
                style: context.text.bodyLarge,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(l.backToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
