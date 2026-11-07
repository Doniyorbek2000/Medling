import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';

/// Tibbiy profil: allergiyalar, surunkali kasalliklar, dorilar. Serverda
/// shifrlangan holda saqlanadi va AI tahliliga avtomatik qo'shiladi.
class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({super.key});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  final _name = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  DateTime? _birth;
  String? _sex;
  String? _blood;
  List<String> _allergies = [];
  List<String> _chronic = [];
  List<String> _meds = [];
  bool _loading = true;
  Object? _error;
  bool _busy = false;

  static const _bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await context.read<MedLinkRepository>().profile();
      if (!mounted) return;
      setState(() {
        _name.text = p.fullName;
        _height.text = p.heightCm?.toString() ?? '';
        _weight.text = p.weightKg?.toString() ?? '';
        _birth = p.birthDate;
        _sex = p.sex;
        _blood = p.bloodType;
        _allergies = [...p.allergies];
        _chronic = [...p.chronicConditions];
        _meds = [...p.medications];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await context.read<MedLinkRepository>().saveProfile(
        MedicalProfile(
          fullName: _name.text.trim(),
          birthDate: _birth,
          sex: _sex,
          bloodType: _blood,
          heightCm: int.tryParse(_height.text),
          weightKg: int.tryParse(_weight.text),
          allergies: _allergies,
          chronicConditions: _chronic,
          medications: _meds,
        ),
      );
      if (!mounted) return;
      showMessage(context, context.l10n.saved);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (d != null) setState(() => _birth = d);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.medicalProfile)),
      body: _error != null
          ? ErrorView(error: _error!, onRetry: _load)
          : _loading
          ? const SkeletonList(count: 4, height: 120)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                        l.medicalProfileNote,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l.fullName),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickBirth,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l.birthDate,
                      suffixIcon: const Icon(Icons.calendar_month_outlined),
                    ),
                    child: Text(
                      _birth == null ? '—' : context.fmt.fullDate(_birth!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 'female', label: Text(l.female)),
                      ButtonSegment(value: 'male', label: Text(l.male)),
                    ],
                    selected: {?_sex},
                    onSelectionChanged: (s) =>
                        setState(() => _sex = s.firstOrNull),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _blood,
                        decoration: InputDecoration(labelText: l.bloodType),
                        items: [
                          for (final b in _bloodTypes)
                            DropdownMenuItem(value: b, child: Text(b)),
                        ],
                        onChanged: (v) => setState(() => _blood = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _height,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(labelText: l.heightCm),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weight,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(labelText: l.weightKg),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _TagEditor(
                  title: l.allergies,
                  icon: Icons.coronavirus_outlined,
                  hint: l.allergiesHint,
                  values: _allergies,
                  onChanged: (v) => setState(() => _allergies = v),
                ),
                const SizedBox(height: 12),
                _TagEditor(
                  title: l.chronicConditions,
                  icon: Icons.monitor_heart_outlined,
                  hint: l.chronicHint,
                  values: _chronic,
                  onChanged: (v) => setState(() => _chronic = v),
                ),
                const SizedBox(height: 12),
                _TagEditor(
                  title: l.medications,
                  icon: Icons.medication_outlined,
                  hint: l.medicationsHint,
                  values: _meds,
                  onChanged: (v) => setState(() => _meds = v),
                ),
                const SizedBox(height: 24),
              ],
            ),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ProgressButton(
                  label: l.save,
                  busy: _busy,
                  onPressed: _save,
                ),
              ),
            ),
    );
  }
}

class _TagEditor extends StatefulWidget {
  const _TagEditor({
    required this.title,
    required this.icon,
    required this.hint,
    required this.values,
    required this.onChanged,
  });
  final String title;
  final IconData icon;
  final String hint;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final v = _ctrl.text.trim();
    if (v.isEmpty || widget.values.contains(v)) return;
    widget.onChanged([...widget.values, v]);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    title: widget.title,
    icon: widget.icon,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.values.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in widget.values)
                InputChip(
                  label: Text(v),
                  onDeleted: () => widget.onChanged(
                    widget.values.where((x) => x != v).toList(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _ctrl,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _add(),
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: IconButton(
              tooltip: context.l10n.add,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _add,
            ),
          ),
        ),
      ],
    ),
  );
}
