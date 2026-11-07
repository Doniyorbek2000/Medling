import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import 'consent_texts.dart';

/// Aniq rozilik ekrani: har bir maqsad alohida, hech biri oldindan
/// belgilanmagan. Majburiylari belgilanmaguncha davom etib bo'lmaydi.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, this.initial = false});

  /// true — ro'yxatdan o'tishdagi birinchi ekran; false — profil sozlamalari.
  final bool initial;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  List<ConsentDoc>? _docs;
  final _original = <String, bool>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<Session>().api.get('/v1/consents');
      final docs = [
        for (final d in res['documents'] as List)
          ConsentDoc.fromJson(d as Map<String, dynamic>),
      ];
      for (final d in docs) {
        _original[d.scope] = d.granted;
      }
      setState(() => _docs = docs);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  bool get _requiredOk =>
      _docs?.where((d) => d.required).every((d) => d.granted) ?? false;

  Future<void> _save() async {
    final session = context.read<Session>();
    final changed = _docs!.where(
      (d) => _original[d.scope] != d.granted || widget.initial,
    );
    if (!widget.initial && changed.any((d) => d.required && !d.granted)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Rozilikni qaytarib olish'),
          content: const Text(
            'Majburiy rozilikni qaytarib olsangiz, xizmatdan foydalana '
            'olmaysiz va hisobingizdan chiqasiz. Davom etasizmi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Bekor qilish'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Ha, qaytarib olaman'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      final res = await session.api.post('/v1/consents', {
        'decisions': [
          for (final d in changed)
            {'scope': d.scope, 'version': d.version, 'granted': d.granted},
        ],
      });
      session.updateMissing((res['missingConsents'] as List).cast<String>());
      if (!mounted) return;
      if (!widget.initial) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = _docs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozilik va maxfiylik'),
        automaticallyImplyLeading: !widget.initial,
        actions: [
          if (widget.initial)
            TextButton(
              onPressed: () => context.read<Session>().logout(),
              child: const Text('Chiqish'),
            ),
        ],
      ),
      body: docs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Ma\'lumotlaringiz qanday ishlatilishini o\'qib chiqing va '
                  'har bir band bo\'yicha alohida qaror qabul qiling. '
                  'Majburiy bandlar (*) xizmat ishlashi uchun zarur.',
                ),
                const SizedBox(height: 16),
                for (final d in docs) ...[
                  _ConsentTile(
                    doc: d,
                    onChanged: (v) => setState(() => d.granted = v),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: (_requiredOk || !widget.initial) && !_busy
                      ? _save
                      : null,
                  child: Text(
                    widget.initial ? 'Roziman, davom etish' : 'Saqlash',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versiya: ${docs.first.version}. Qaroringiz vaqti va '
                  'qurilma ma\'lumoti dalil sifatida saqlanadi.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({required this.doc, required this.onChanged});
  final ConsentDoc doc;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = consentTexts[doc.scope] ?? ConsentText(doc.scope, '', '');
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Checkbox(
            value: doc.granted,
            activeColor: Brand.teal,
            onChanged: (v) => onChanged(v ?? false),
          ),
          title: Text(
            '${t.title}${doc.required ? ' *' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(t.summary),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [Text(t.body)],
        ),
      ),
    );
  }
}
