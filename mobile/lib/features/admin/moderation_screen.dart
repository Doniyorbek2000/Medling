import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/brand.dart';
import '../doctors/doctors_screen.dart';

/// Admin: shifokor arizalarini tekshirish (tasdiqlash / rad etish).
/// Har bir qaror serverda moderator ID'si va vaqti bilan audit jurnaliga yoziladi.
class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  List<Map<String, dynamic>>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<Session>().api.get(
        '/v1/admin/doctors/pending',
      );
      if (!mounted) return;
      setState(
        () => _items = (res['items'] as List).cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _items = const []);
        showError(context, e);
      }
    }
  }

  Future<void> _decide(Map<String, dynamic> d, String decision) async {
    String? note;
    if (decision == 'rejected') {
      final ctrl = TextEditingController();
      note = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Rad etish sababi'),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Masalan: litsenziya reyestrda topilmadi',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Bekor'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, ctrl.text.trim()),
              child: const Text('Rad etish'),
            ),
          ],
        ),
      );
      if (note == null || note.isEmpty) return;
    }
    if (!mounted) return;
    try {
      await context.read<Session>().api.post(
        '/v1/admin/doctors/${d['id']}/moderate',
        {'decision': decision, 'note': ?note},
      );
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: const Text('Moderatsiya')),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.task_alt,
                          text: 'Tekshirilishi kerak bo\'lgan arizalar yo\'q',
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _card(items[i]),
                    ),
            ),
    );
  }

  Widget _card(Map<String, dynamic> d) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d['fullName'] as String,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          Text(DoctorsScreen.specialtyLabel(d['specialty'] as String)),
          const SizedBox(height: 8),
          _row('Litsenziya', d['licenseNumber'] as String),
          _row('Klinika', '${d['clinic']}, ${d['city']}'),
          _row('Tajriba', '${d['experienceYears']} yil'),
          _row('Narx', formatUzs(d['priceUzs'] as int)),
          const SizedBox(height: 6),
          const Text(
            'Hujjatlar:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          for (final ref in (d['documentRefs'] as List).cast<String>())
            InkWell(
              onTap: () => launchUrl(Uri.parse(ref)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  ref,
                  style: const TextStyle(
                    color: Brand.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _decide(d, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Brand.danger,
                  ),
                  child: const Text('Rad etish'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _decide(d, 'approved'),
                  child: const Text('Tasdiqlash'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(k)),
        Expanded(
          child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}
