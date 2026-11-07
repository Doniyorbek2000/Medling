import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/l10n.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';
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
  List<String> _chronic = const [];
  bool _busy = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  /// Tibbiy profil to'ldirilgan bo'lsa — yosh, jins va surunkali
  /// kasalliklar avtomatik qo'yiladi.
  Future<void> _prefill() async {
    try {
      final p = await context.read<MedLinkRepository>().profile();
      if (!mounted) return;
      setState(() {
        if (p.ageYears != null) _age.text = '${p.ageYears}';
        if (p.sex != null) _sex = p.sex!;
        _chronic = p.chronicConditions;
        _prefilled = p.ageYears != null;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _symptoms.dispose();
    _age.dispose();
    _days.dispose();
    super.dispose();
  }

  bool get _valid {
    final age = int.tryParse(_age.text);
    return _symptoms.text.trim().length >= 5 &&
        age != null &&
        age >= 0 &&
        age <= 120;
  }

  Future<void> _analyze() async {
    FocusScope.of(context).unfocus();
    final session = context.read<Session>();
    setState(() => _busy = true);
    try {
      final result = await context.read<MedLinkRepository>().analyze(
        symptoms: _symptoms.text.trim(),
        ageYears: int.parse(_age.text),
        sex: _sex,
        durationDays: int.tryParse(_days.text),
        chronicConditions: _chronic,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => TriageResultScreen(result: result)),
      );
    } on ApiError catch (e) {
      if (e.consentRequired) {
        await session.reloadMe();
      } else if (mounted) {
        showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<Session>();
    final needsAiConsent =
        !session.hasConsent('aiProcessing') ||
        !session.hasConsent('crossBorderTransfer');

    return Scaffold(
      appBar: AppBar(title: Text(l.triageTitle)),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const EmergencyBanner(),
            const SizedBox(height: 16),
            if (needsAiConsent)
              SectionCard(
                title: l.aiConsentNeededTitle,
                icon: Icons.privacy_tip_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.aiConsentNeededBody),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ConsentScreen(),
                        ),
                      ),
                      child: Text(l.consentSettings),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                l.symptomsQuestion,
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _symptoms,
                minLines: 5,
                maxLines: 10,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(hintText: l.symptomsHint),
              ),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.noPiiHint,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                      decoration: InputDecoration(labelText: l.age),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _days,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(labelText: l.durationDays),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'female',
                      label: Text(l.female),
                      icon: const Icon(Icons.female),
                    ),
                    ButtonSegment(
                      value: 'male',
                      label: Text(l.male),
                      icon: const Icon(Icons.male),
                    ),
                  ],
                  selected: {_sex},
                  onSelectionChanged: (s) => setState(() => _sex = s.first),
                ),
              ),
              if (_prefilled || _chronic.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.assignment_ind_outlined,
                      size: 16,
                      color: Brand.teal,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _chronic.isEmpty
                            ? l.prefilledFromProfile
                            : l.chronicIncluded(_chronic.join(', ')),
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              ProgressButton(
                label: _busy ? l.analyzing : l.analyze,
                icon: Icons.auto_awesome_rounded,
                busy: _busy,
                onPressed: _valid ? _analyze : null,
              ),
              const SizedBox(height: 12),
              Text(
                l.triagePoweredBy,
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
