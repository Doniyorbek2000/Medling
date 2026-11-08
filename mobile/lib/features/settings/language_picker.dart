import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/settings.dart';

const languageNames = {'uz': 'O\'zbekcha', 'ru': 'Русский', 'en': 'English'};

Future<void> showLanguagePicker(BuildContext context) {
  final settings = context.read<AppSettings>();
  final current = Localizations.localeOf(context).languageCode;
  return showModalBottomSheet<void>(
    context: context,
    builder: (c) => SafeArea(
      child: RadioGroup<String>(
        groupValue: settings.locale == null ? 'system' : current,
        onChanged: (v) {
          settings.setLocale(v == 'system' ? null : Locale(v!));
          Navigator.pop(c);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                context.l10n.language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioListTile<String>(
              value: 'system',
              title: Text(context.l10n.systemDefault),
            ),
            for (final e in languageNames.entries)
              RadioListTile<String>(value: e.key, title: Text(e.value)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return TextButton.icon(
      onPressed: () => showLanguagePicker(context),
      icon: const Icon(Icons.language, size: 18),
      label: Text(code.toUpperCase()),
    );
  }
}
