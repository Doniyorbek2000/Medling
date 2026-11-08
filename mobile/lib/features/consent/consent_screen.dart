import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/legal_links.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';

/// Rozilik matnlari. DIQQAT: namunaviy — ishga tushirishdan oldin yurist
/// tekshirishi va backend versiyasi bilan moslashtirilishi shart.
({String title, String summary, String body}) consentText(
  AppLocalizations l,
  String scope,
) {
  return switch (scope) {
    'terms' => (
      title: l.consentTermsTitle,
      summary: l.consentTermsSummary,
      body: l.consentTermsBody,
    ),
    'personalData' => (
      title: l.consentPersonalTitle,
      summary: l.consentPersonalSummary,
      body: l.consentPersonalBody,
    ),
    'healthData' => (
      title: l.consentHealthTitle,
      summary: l.consentHealthSummary,
      body: l.consentHealthBody,
    ),
    'aiProcessing' => (
      title: l.consentAiTitle,
      summary: l.consentAiSummary,
      body: l.consentAiBody,
    ),
    'crossBorderTransfer' => (
      title: l.consentTransferTitle,
      summary: l.consentTransferSummary,
      body: l.consentTransferBody,
    ),
    'marketing' => (
      title: l.consentMarketingTitle,
      summary: l.consentMarketingSummary,
      body: l.consentMarketingBody,
    ),
    _ => (title: scope, summary: '', body: ''),
  };
}

/// Aniq rozilik ekrani: har bir maqsad alohida, hech biri oldindan
/// belgilanmagan. Majburiylari belgilanmaguncha davom etib bo'lmaydi.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, this.initial = false});

  /// true — ro'yxatdan o'tishdagi birinchi ekran; false — sozlamalar.
  final bool initial;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  List<ConsentDoc>? _docs;
  Object? _error;
  final _original = <String, bool>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final docs = await context.read<MedLinkRepository>().consents();
      for (final d in docs) {
        _original[d.scope] = d.granted;
      }
      if (mounted) setState(() => _docs = docs);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  bool get _requiredOk =>
      _docs?.where((d) => d.required).every((d) => d.granted) ?? false;

  Future<void> _save() async {
    final l = context.l10n;
    final session = context.read<Session>();
    final repo = context.read<MedLinkRepository>();
    final changed = _docs!
        .where((d) => widget.initial || _original[d.scope] != d.granted)
        .toList();
    if (changed.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    if (!widget.initial && changed.any((d) => d.required && !d.granted)) {
      final ok = await confirmDialog(
        context,
        title: l.withdrawTitle,
        message: l.withdrawMessage,
        confirm: l.withdrawConfirm,
        destructive: true,
      );
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      session.updateMissing(await repo.saveConsents(changed));
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
    final l = context.l10n;
    final docs = _docs;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.consentScreenTitle),
        automaticallyImplyLeading: !widget.initial,
        actions: [
          if (widget.initial)
            TextButton(
              onPressed: () => context.read<Session>().logout(),
              child: Text(l.logout),
            ),
        ],
      ),
      body: _error != null
          ? ErrorView(
              error: _error!,
              onRetry: () {
                setState(() => _error = null);
                _load();
              },
            )
          : docs == null
          ? const SkeletonList(count: 6, height: 76)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        l.consentIntro,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final d in docs) ...[
                        _ConsentTile(
                          doc: d,
                          onChanged: (v) => setState(() => d.granted = v),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        l.consentFooter(docs.first.version),
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => openLegal(context, 'privacy'),
                            child: Text(l.privacyPolicy),
                          ),
                          TextButton(
                            onPressed: () => openLegal(context, 'terms'),
                            child: Text(l.termsOfUse),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: ProgressButton(
                      label: widget.initial ? l.agreeContinue : l.save,
                      busy: _busy,
                      onPressed: _requiredOk || !widget.initial ? _save : null,
                    ),
                  ),
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
    final l = context.l10n;
    final t = consentText(l, doc.scope);
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          leading: Checkbox(
            value: doc.granted,
            activeColor: Brand.teal,
            onChanged: (v) => onChanged(v ?? false),
          ),
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: t.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (doc.required)
                  TextSpan(
                    text: '  ${l.required}',
                    style: TextStyle(
                      color: context.ink(Brand.danger),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          subtitle: Text(t.summary),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(t.body)],
        ),
      ),
    );
  }
}
