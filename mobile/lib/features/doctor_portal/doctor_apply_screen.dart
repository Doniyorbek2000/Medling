import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';
import '../doctors/specialty.dart';

/// Shifokor sifatida ro'yxatdan o'tish arizasi. Ariza moderatorlar
/// tomonidan tekshirilmaguncha profil bemorlarga ko'rinmaydi.
class DoctorApplyScreen extends StatefulWidget {
  const DoctorApplyScreen({super.key});

  @override
  State<DoctorApplyScreen> createState() => _DoctorApplyScreenState();
}

class _DoctorApplyScreenState extends State<DoctorApplyScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _license = TextEditingController();
  final _clinic = TextEditingController();
  final _city = TextEditingController(text: 'Toshkent');
  final _exp = TextEditingController();
  final _price = TextEditingController();
  final _bio = TextEditingController();
  final _docs = TextEditingController();
  String? _specialty;
  bool _confirm = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _license,
      _clinic,
      _city,
      _exp,
      _price,
      _bio,
      _docs,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || !_confirm) return;
    setState(() => _busy = true);
    try {
      await context.read<MedLinkRepository>().applyAsDoctor({
        'fullName': _name.text.trim(),
        'specialty': _specialty,
        'licenseNumber': _license.text.trim(),
        'clinic': _clinic.text.trim(),
        'city': _city.text.trim(),
        'experienceYears': int.parse(_exp.text),
        'priceUzs': int.parse(_price.text),
        'bio': _bio.text.trim(),
        // Prod'da: hujjatlar avval imzolangan URL orqali shifrlangan
        // bucket'ga yuklanadi, bu yerga faqat havolalar yuboriladi.
        'documentRefs': _docs.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      });
      if (!mounted) return;
      showMessage(context, context.l10n.applicationSent);
      Navigator.of(context).pop(true);
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
      appBar: AppBar(title: Text(l.doctorApplication)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              icon: Icons.verified_user_outlined,
              title: l.moderationHowTitle,
              child: Text(l.moderationHowBody),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v ?? '').trim().length < 5 ? l.fullNameInvalid : null,
              decoration: InputDecoration(labelText: l.fullName),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _specialty,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.specialty),
              items: [
                for (final code in specialtyCodes)
                  DropdownMenuItem(
                    value: code,
                    child: Text(specialtyName(l, code)),
                  ),
              ],
              validator: (v) => v == null ? l.requiredField : null,
              onChanged: (v) => setState(() => _specialty = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _license,
              validator: req,
              decoration: InputDecoration(labelText: l.licenseNumber),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clinic,
              validator: req,
              decoration: InputDecoration(labelText: l.clinicLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              validator: req,
              decoration: InputDecoration(labelText: l.city),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _exp,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: req,
                    decoration: InputDecoration(
                      labelText: l.experienceYearsLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: req,
                    decoration: InputDecoration(labelText: l.priceUzsLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bio,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: l.aboutYou,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _docs,
              maxLines: 3,
              validator: req,
              decoration: InputDecoration(
                labelText: l.documents,
                helperText: l.documentsHint,
                helperMaxLines: 2,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _confirm,
              activeColor: Brand.teal,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _confirm = v ?? false),
              title: Text(l.applicationConfirm),
            ),
            const SizedBox(height: 12),
            ProgressButton(
              label: l.sendApplication,
              busy: _busy,
              onPressed: _confirm ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
