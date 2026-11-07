import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';
import '../settings/language_picker.dart';
import 'otp_screen.dart';

/// "90 123 45 67" ko'rinishida formatlaydi.
class UzPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final d = digits.length > 9 ? digits.substring(0, 9) : digits;
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 2 || i == 5 || i == 7) b.write(' ');
      b.write(d[i]);
    }
    final text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  String get _digits => _ctrl.text.replaceAll(RegExp(r'\D'), '');
  String get _phone => '+998$_digits';
  bool get _valid => _digits.length == 9;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(actions: const [LanguageButton(), SizedBox(width: 8)]),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const SizedBox(height: 16),
            const Center(child: MedLinkLogo(size: 104)),
            const SizedBox(height: 16),
            Text(
              l.tagline,
              textAlign: TextAlign.center,
              style: context.text.bodyLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              l.phoneTitle,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.phoneSubtitle,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [UzPhoneFormatter()],
              style: const TextStyle(fontSize: 20, letterSpacing: 1),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _valid ? _submit() : null,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_iphone_rounded,
                        size: 20,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '+998',
                        style: TextStyle(fontSize: 20, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(),
                hintText: '90 123 45 67',
                semanticCounterText: l.phoneTitle,
              ),
            ),
            const SizedBox(height: 24),
            ProgressButton(
              label: l.getCode,
              busy: _busy,
              onPressed: _valid ? _submit : null,
            ),
            const SizedBox(height: 16),
            Text(
              l.loginLegal,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
