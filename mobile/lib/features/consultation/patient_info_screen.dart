import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';
import '../triage/triage_result_screen.dart';

/// Shifokor: qabul oldidan bemorning tibbiy profili va AI tahlili.
/// Har bir ochilish serverda audit jurnaliga yoziladi.
class PatientInfoScreen extends StatefulWidget {
  const PatientInfoScreen({super.key, required this.appointment});
  final Appointment appointment;

  @override
  State<PatientInfoScreen> createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends State<PatientInfoScreen> {
  PatientInfo? _info;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final info = await context.read<MedLinkRepository>().patientInfo(
        widget.appointment.id,
      );
      if (mounted) setState(() => _info = info);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final info = _info;
    return Scaffold(
      appBar: AppBar(title: Text(l.patientInfo)),
      body: _error != null
          ? ErrorView(error: _error!, onRetry: _load)
          : info == null
          ? const SkeletonList(count: 3, height: 140)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _profileCard(context, info.profile),
                if (widget.appointment.reason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: l.visitReason,
                    icon: Icons.notes_outlined,
                    child: Text(widget.appointment.reason),
                  ),
                ],
                if (info.triage != null) ...[
                  const SizedBox(height: 12),
                  _triageCard(context, info),
                ],
              ],
            ),
    );
  }

  Widget _profileCard(BuildContext context, MedicalProfile p) {
    final l = context.l10n;
    String orDash(String? v) => (v == null || v.isEmpty) ? '—' : v;
    final rows = <(String, String)>[
      (l.fullName, orDash(p.fullName)),
      (
        l.age,
        p.ageYears == null
            ? '—'
            : '${p.ageYears} (${context.fmt.fullDate(p.birthDate!)})',
      ),
      (
        l.sex,
        switch (p.sex) {
          'male' => l.male,
          'female' => l.female,
          _ => '—',
        },
      ),
      (l.bloodType, orDash(p.bloodType)),
      (l.heightWeight, '${p.heightCm ?? '—'} / ${p.weightKg ?? '—'}'),
    ];
    Widget chips(String title, List<String> v, Color color) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.labelMedium),
          const SizedBox(height: 4),
          v.isEmpty
              ? const Text('—')
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final x in v) StatusChip(label: x, color: color),
                  ],
                ),
        ],
      ),
    );
    return SectionCard(
      title: l.medicalProfile,
      icon: Icons.assignment_ind_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      k,
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      v,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          // Allergiyalar — eng muhim: qizil rangda.
          chips(l.allergies, p.allergies, Brand.danger),
          chips(l.chronicConditions, p.chronicConditions, Brand.warning),
          chips(l.medications, p.medications, Brand.blue),
        ],
      ),
    );
  }

  Widget _triageCard(BuildContext context, PatientInfo info) {
    final l = context.l10n;
    final t = info.triage!;
    final u = urgencyInfo(l, t.urgency);
    return SectionCard(
      title: l.aiPreTriage,
      icon: Icons.auto_awesome_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(label: u.title, color: u.color),
          if (info.triageInput != null) ...[
            const SizedBox(height: 8),
            Text('"${info.triageInput}"'),
          ],
          if (t.conditions.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final c in t.conditions) Text('• ${c.name}'),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TriageResultScreen(result: t)),
            ),
            child: Text(l.viewDetails),
          ),
        ],
      ),
    );
  }
}
