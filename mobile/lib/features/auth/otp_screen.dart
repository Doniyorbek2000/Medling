import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/states.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});
  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  int _resendIn = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 1) t.cancel();
      if (mounted) setState(() => _resendIn--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<Session>().verifyOtp(widget.phone, _ctrl.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      _ctrl.clear();
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await context.read<Session>().requestOtp(widget.phone);
      _startTimer();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  /// +998901234567 -> +998 90 123 45 67
  static String _pretty(String p) => p.length == 13
      ? '${p.substring(0, 4)} ${p.substring(4, 6)} ${p.substring(6, 9)} '
            '${p.substring(9, 11)} ${p.substring(11)}'
      : p;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final code = _ctrl.text;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(
            l.otpTitle,
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.otpSubtitle(_pretty(widget.phone)),
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          // Ko'rinadigan 6 ta katakcha + ko'rinmas haqiqiy maydon
          // (SMS'dan avtomatik to'ldirish ishlashi uchun).
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 6; i++)
                    _Cell(
                      char: i < code.length ? code[i] : '',
                      active: i == code.length && _focus.hasFocus,
                    ),
                ],
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    showCursor: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (v) {
                      setState(() {});
                      if (v.length == 6) _verify();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ProgressButton(
            label: l.login,
            busy: _busy,
            onPressed: code.length == 6 ? _verify : null,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _resendIn > 0 ? null : _resend,
            child: Text(_resendIn > 0 ? l.resendIn(_resendIn) : l.resendCode),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.char, required this.active});
  final String char;
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: context.motion(const Duration(milliseconds: 150)),
    width: 48,
    height: 58,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: active || char.isNotEmpty
            ? context.colors.primary
            : context.colors.outlineVariant,
        width: active ? 2 : 1.2,
      ),
    ),
    child: Text(
      char,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    ),
  );
}
