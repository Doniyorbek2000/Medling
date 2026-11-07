import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../widgets/brand.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  String get _phone => '+998${_ctrl.text.replaceAll(RegExp(r'\D'), '')}';
  bool get _valid => _ctrl.text.replaceAll(RegExp(r'\D'), '').length == 9;

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await context.read<Session>().requestOtp(_phone);
      if (!mounted) return;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => OtpScreen(phone: _phone)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            const Center(child: MedLinkLogo(size: 110)),
            const SizedBox(height: 12),
            Text(
              'Sun\'iy intellekt yordamidagi tibbiy platforma',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 48),
            Text(
              'Telefon raqamingiz',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixText: '+998 ',
                hintText: '90 123 45 67',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _valid && !_busy ? _submit : null,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('SMS kod olish'),
            ),
          ],
        ),
      ),
    );
  }
}
