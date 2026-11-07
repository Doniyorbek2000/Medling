import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../consent/consent_screen.dart';
import 'triage_result_screen.dart';

class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  final _symptoms = TextEditingController();
  final _age = TextEditingController();
  final _days = TextEditingController();
  String _sex = 'female';
  bool _busy = false;

  bool get _valid =>
      _symptoms.text.trim().length >= 5 && int.tryParse(_age.text) != null;

  Future<void> _analyze() async {
    final session = context.read<Session>();
    setState(() => _busy = true);
    try {
      final res = await session.api.post('/v1/triage', {
        'symptoms': _symptoms.text.trim(),
        'ageYears': int.parse(_age.text),
        'sex': _sex,
        if (int.tryParse(_days.text) != null)
          'durationDays': int.parse(_days.text),
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              TriageResultScreen(result: TriageResult.fromJson(res)),
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.consentRequired) {
        await session.refreshConsents();
      } else {
        showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missing = context.watch<Session>().missingConsents;
    final needsAiConsent =
        missing.contains('aiProcessing') ||
        missing.contains('crossBorderTransfer');

    return Scaffold(
      appBar: AppBar(title: const Text('AI alomatlar tahlili')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EmergencyBanner(),
          const SizedBox(height: 16),
          if (needsAiConsent)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI tahlili uchun rozilik kerak',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '"Sun\'iy intellekt tahlili" va "Ma\'lumotni xorijga '
                      'uzatish" bandlariga rozilik bering. Bu ixtiyoriy — '
                      'usiz ham shifokorga yozilishingiz mumkin.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ConsentScreen(),
                        ),
                      ),
                      child: const Text('Rozilik sozlamalari'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Text(
              'Nima bezovta qilyapti?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _symptoms,
              minLines: 4,
              maxLines: 8,
              maxLength: 2000,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText:
                    'Masalan: 3 kundan beri harorat 38.5, tomoq og\'riyapti, '
                    'yutishda og\'riq bor...',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ism, telefon yoki pasport ma\'lumotlarini yozmang.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Yosh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _days,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Necha kundan beri',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'female', label: Text('Ayol')),
                ButtonSegment(value: 'male', label: Text('Erkak')),
              ],
              selected: {_sex},
              onSelectionChanged: (s) => setState(() => _sex = s.first),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _valid && !_busy ? _analyze : null,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_busy ? 'Tahlil qilinmoqda...' : 'Tahlil qilish'),
            ),
            const SizedBox(height: 12),
            Text(
              'Tahlil Google Med-PaLM 2 modeli yordamida bajariladi va '
              'tashxis hisoblanmaydi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
