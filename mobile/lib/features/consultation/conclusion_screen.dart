import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';

/// Shifokor: qabul xulosasi — tashxis, tavsiyalar, retsept, qayta ko'rik.
class ConclusionScreen extends StatefulWidget {
  const ConclusionScreen({super.key, required this.appointment});
  final Appointment appointment;

  @override
  State<ConclusionScreen> createState() => _ConclusionScreenState();
}

class _RxForm {
  _RxForm([Prescription? p])
    : drug = TextEditingController(text: p?.drug),
      dose = TextEditingController(text: p?.dose),
      frequency = TextEditingController(text: p?.frequency),
      days = TextEditingController(
        text: (p?.durationDays ?? 0) > 0 ? '${p!.durationDays}' : '',
      ),
      notes = TextEditingController(text: p?.notes);

  final TextEditingController drug, dose, frequency, days, notes;

  Prescription toModel() => Prescription(
    drug: drug.text.trim(),
    dose: dose.text.trim(),
    frequency: frequency.text.trim(),
    durationDays: int.tryParse(days.text) ?? 0,
    notes: notes.text.trim(),
  );

  void dispose() {
    for (final c in [drug, dose, frequency, days, notes]) {
      c.dispose();
    }
  }
}

class _ConclusionScreenState extends State<ConclusionScreen> {
  final _form = GlobalKey<FormState>();
  late final _diagnosis = TextEditingController(
    text: widget.appointment.conclusion?.diagnosis,
  );
  late final _recommendations = TextEditingController(
    text: widget.appointment.conclusion?.recommendations,
  );
  late final List<_RxForm> _rx = [
    for (final p in widget.appointment.conclusion?.prescriptions ?? const [])
      _RxForm(p),
  ];
  late int? _followUp = widget.appointment.conclusion?.followUpDays;
  bool _busy = false;

  @override
  void dispose() {
    _diagnosis.dispose();
    _recommendations.dispose();
    for (final r in _rx) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.saveConclusion,
      message: l.saveConclusionConfirm,
      confirm: l.save,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await context.read<MedLinkRepository>().saveConclusion(
        widget.appointment.id,
        Conclusion(
          diagnosis: _diagnosis.text.trim(),
          recommendations: _recommendations.text.trim(),
          prescriptions: [
            for (final r in _rx)
              if (r.drug.text.trim().isNotEmpty) r.toModel(),
          ],
          followUpDays: _followUp,
        ),
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showMessage(context, l.conclusionSaved);
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String? req(String? v) =>
        (v == null || v.trim().isEmpty) ? l.requiredField : null;
    return Scaffold(
      appBar: AppBar(title: Text(l.conclusion)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _diagnosis,
              validator: req,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.diagnosis,
                helperText: l.diagnosisHint,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _recommendations,
              minLines: 4,
              maxLines: 10,
              maxLength: 4000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.recommendations,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.prescription,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _rx.length >= 20
                      ? null
                      : () => setState(() => _rx.add(_RxForm())),
                  icon: const Icon(Icons.add),
                  label: Text(l.addMedication),
                ),
              ],
            ),
            if (_rx.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.noPrescription,
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
              ),
            for (final (i, r) in _rx.indexed) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medication_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${l.medication} ${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => setState(() {
                              _rx.removeAt(i).dispose();
                            }),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: r.drug,
                              validator: req,
                              decoration: InputDecoration(
                                labelText: l.drugName,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: r.dose,
                                    decoration: InputDecoration(
                                      labelText: l.dose,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: r.days,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: l.durationDays,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: r.frequency,
                              decoration: InputDecoration(
                                labelText: l.frequency,
                                hintText: l.frequencyHint,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: r.notes,
                              decoration: InputDecoration(labelText: l.notes),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _followUp,
              decoration: InputDecoration(labelText: l.followUp),
              items: [
                DropdownMenuItem(value: null, child: Text(l.followUpNone)),
                for (final d in const [3, 7, 14, 30, 90])
                  DropdownMenuItem(value: d, child: Text(l.inDays(d))),
              ],
              onChanged: (v) => setState(() => _followUp = v),
            ),
            const SizedBox(height: 12),
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
                    l.conclusionPrivacy,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ProgressButton(
            label: l.saveConclusion,
            busy: _busy,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}

/// Bemor va shifokor uchun xulosani ko'rsatish.
class ConclusionCard extends StatelessWidget {
  const ConclusionCard({super.key, required this.conclusion});
  final Conclusion conclusion;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = conclusion;
    return SectionCard(
      title: l.conclusion,
      icon: Icons.assignment_turned_in_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.diagnosis, style: context.text.labelMedium),
          const SizedBox(height: 2),
          Text(
            c.diagnosis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          if (c.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l.recommendations, style: context.text.labelMedium),
            const SizedBox(height: 2),
            SelectableText(c.recommendations),
          ],
          if (c.prescriptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l.prescription, style: context.text.labelMedium),
            const SizedBox(height: 4),
            for (final p in c.prescriptions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.medication_rounded,
                      size: 20,
                      color: context.ink(Brand.teal),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [p.drug, if (p.dose.isNotEmpty) p.dose].join(' · '),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (p.frequency.isNotEmpty || p.durationDays > 0)
                            Text(
                              [
                                if (p.frequency.isNotEmpty) p.frequency,
                                if (p.durationDays > 0)
                                  l.forDays(p.durationDays),
                              ].join(', '),
                            ),
                          if (p.notes.isNotEmpty)
                            Text(
                              p.notes,
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (c.followUpDays != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event_repeat_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(l.followUpIn(c.followUpDays!))),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l.conclusionDisclaimer,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
