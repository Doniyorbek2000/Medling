import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../widgets/brand.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});
  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await context.read<Session>().verifyOtp(widget.phone, _ctrl.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasdiqlash')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('${widget.phone} raqamiga yuborilgan 6 xonali kodni kiriting'),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, letterSpacing: 12),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (v) {
              setState(() {});
              if (v.length == 6 && !_busy) _verify();
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _ctrl.text.length == 6 && !_busy ? _verify : null,
            child: const Text('Kirish'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => context
                      .read<Session>()
                      .requestOtp(widget.phone)
                      .catchError((Object e) {
                        if (context.mounted) showError(context, e);
                      }),
            child: const Text('Kodni qayta yuborish'),
          ),
        ],
      ),
    );
  }
}
