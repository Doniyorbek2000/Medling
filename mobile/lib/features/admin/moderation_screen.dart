import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';
import '../doctors/specialty.dart';

/// Admin: shifokor arizalarini tekshirish (tasdiqlash / rad etish).
/// Har bir qaror serverda moderator ID'si va vaqti bilan audit jurnaliga yoziladi.
class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  int _version = 0;

  Future<void> _decide(Map<String, dynamic> d, String decision) async {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    String? note;
    if (decision == 'rejected') {
      note = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (c) => const _RejectSheet(),
      );
      if (note == null || note.isEmpty) return;
    } else {
      final ok = await confirmDialog(
        context,
        title: l.approve,
        message: l.approveConfirm(d['fullName'] as String),
        confirm: l.approve,
      );
      if (!ok) return;
    }
    try {
      await repo.moderate(d['id'] as String, decision, note: note);
      if (mounted) setState(() => _version++);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabModeration),
        automaticallyImplyLeading: false,
      ),
      body: AsyncList<Map<String, dynamic>>(
        key: ValueKey(_version),
        load: repo.pendingDoctors,
        empty: EmptyView(icon: Icons.task_alt_rounded, title: l.noPending),
        itemBuilder: (context, d, _) => _card(context, d),
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> d) {
    final l = context.l10n;
    final name = d['fullName'] as String;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(
                  initials: name.split(' ').take(2).map((p) => p[0]).join(),
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(specialtyName(l, d['specialty'] as String)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _row(l.licenseNumber, d['licenseNumber'] as String),
            _row(l.clinicLabel, '${d['clinic']}, ${d['city']}'),
            _row(l.experienceLabel, '${d['experienceYears']}'),
            _row(l.priceLabel, context.fmt.money(d['priceUzs'] as int)),
            const SizedBox(height: 8),
            Text(
              l.documents,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final ref in (d['documentRefs'] as List).cast<String>())
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => launchUrl(Uri.parse(ref)),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: Text(ref, overflow: TextOverflow.ellipsis),
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
                    child: Text(l.reject),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _decide(d, 'approved'),
                    child: Text(l.approve),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            k,
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet();

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.rejectReason,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(hintText: l.rejectReasonHint),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Brand.danger),
            onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
            child: Text(l.reject),
          ),
        ],
      ),
    );
  }
}
