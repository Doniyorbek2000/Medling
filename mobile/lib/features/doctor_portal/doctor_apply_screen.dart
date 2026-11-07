import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../widgets/brand.dart';
import '../doctors/doctors_screen.dart';

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

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _specialty == null || !_confirm) {
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<Session>().api.post('/v1/doctors/apply', {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ariza yuborildi. Moderatsiya 1–3 ish kuni davom etadi.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Majburiy maydon' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shifokor arizasi')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Arizangiz moderatorlar tomonidan tekshiriladi: diplom, '
              'litsenziya (Sog\'liqni saqlash vazirligi reyestri) va shaxsni '
              'tasdiqlovchi hujjat. Tasdiqlangandan so\'ng profilingiz '
              '"tekshirilgan" belgisi bilan bemorlarga ko\'rinadi.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              validator: (v) => (v ?? '').trim().length < 5
                  ? 'To\'liq F.I.Sh. kiriting'
                  : null,
              decoration: const InputDecoration(labelText: 'F.I.Sh.'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _specialty,
              decoration: const InputDecoration(labelText: 'Mutaxassislik'),
              items: [
                for (final code in const [
                  'therapist',
                  'pediatrician',
                  'cardiologist',
                  'neurologist',
                  'gastroenterologist',
                  'pulmonologist',
                  'endocrinologist',
                  'dermatologist',
                  'ent',
                  'ophthalmologist',
                  'gynecologist',
                  'urologist',
                  'traumatologist',
                  'psychiatrist',
                ])
                  DropdownMenuItem(
                    value: code,
                    child: Text(DoctorsScreen.specialtyLabel(code)),
                  ),
              ],
              validator: (v) => v == null ? 'Tanlang' : null,
              onChanged: (v) => setState(() => _specialty = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _license,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Litsenziya raqami'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clinic,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Klinika'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Shahar'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _exp,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Tajriba (yil)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Narx (so\'m)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bio,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'O\'zingiz haqingizda',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _docs,
              maxLines: 3,
              validator: _required,
              decoration: const InputDecoration(
                labelText: 'Hujjatlar (har qatorda bitta havola)',
                helperText: 'Diplom, litsenziya, pasport nusxalari',
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _confirm,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _confirm = v ?? false),
              title: const Text(
                'Ma\'lumotlar to\'g\'riligini tasdiqlayman va ular '
                'tekshirilishiga roziman',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _confirm && !_busy ? _submit : null,
              child: const Text('Arizani yuborish'),
            ),
          ],
        ),
      ),
    );
  }
}
