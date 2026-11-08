import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/brand.dart';
import '../../widgets/reason_sheet.dart';
import '../../widgets/states.dart';
import '../doctors/specialty.dart';
import 'admin_tabs.dart';

/// Admin: shifokor kartasi — hujjatlar, ko'rsatkichlar, to'xtatish/tiklash,
/// sharhlarni moderatsiya qilish.
class AdminDoctorScreen extends StatefulWidget {
  const AdminDoctorScreen({super.key, required this.doctorId});
  final String doctorId;

  @override
  State<AdminDoctorScreen> createState() => _AdminDoctorScreenState();
}

class _AdminDoctorScreenState extends State<AdminDoctorScreen> {
  Map<String, dynamic>? _d;
  Object? _error;
  bool _busy = false;

  MedLinkRepository get _repo => context.read<MedLinkRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _repo.adminDoctor(widget.doctorId);
      if (mounted) {
        setState(() {
          _d = d;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _suspend() async {
    final l = context.l10n;
    final d = _d!;
    final note = await askReason(
      context,
      title: l.suspendDoctor,
      hint: l.suspendReasonHint,
      confirm: l.suspendDoctor,
      warning: l.suspendWarning((d['stats'] as Map)['upcoming'] as int),
    );
    if (note == null) return;
    await _run(() => _repo.moderate(widget.doctorId, 'suspended', note: note));
  }

  Future<void> _reinstate() async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.reinstateDoctor,
      message: l.reinstateConfirm(_d!['fullName'] as String),
      confirm: l.reinstateDoctor,
    );
    if (!ok) return;
    await _run(() => _repo.moderate(widget.doctorId, 'approved'));
  }

  Future<void> _toggleReview(Map<String, dynamic> r) async {
    final l = context.l10n;
    final hidden = r['hidden'] as bool? ?? false;
    String? reason;
    if (!hidden) {
      reason = await askReason(
        context,
        title: l.hideReviewTitle,
        hint: l.hideReviewHint,
        confirm: l.hideReview,
      );
      if (reason == null) return;
    }
    await _run(
      () => _repo.setReviewHidden(
        r['appointmentId'] as String,
        hidden: !hidden,
        reason: reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = _d;
    return Scaffold(
      appBar: AppBar(title: Text(d?['fullName'] as String? ?? '')),
      body: d == null
          ? (_error != null
                ? ErrorView(error: _error!, onRetry: _load)
                : const SkeletonList(count: 4, height: 90))
          : RefreshIndicator.adaptive(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _content(context, l, d),
              ),
            ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    AppLocalizations l,
    Map<String, dynamic> d,
  ) {
    final status = d['status'] as String;
    final (label, color) = doctorStatus(l, status);
    final stats = d['stats'] as Map<String, dynamic>;
    final reviews = (d['reviews'] as List).cast<Map<String, dynamic>>();
    final docs = (d['documentRefs'] as List).cast<String>();
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              '${specialtyName(l, d['specialty'] as String)} · '
              '${d['experienceYears']} ${l.experienceLabel.toLowerCase()}',
              style: context.text.titleMedium,
            ),
          ),
          StatusChip(label: label, color: color),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        '${d['clinic']}, ${d['city']}',
        style: TextStyle(color: context.colors.onSurfaceVariant),
      ),
      if (d['moderationNote'] != null &&
          (d['moderationNote'] as String).isNotEmpty &&
          status != 'approved') ...[
        const SizedBox(height: 8),
        Text('${l.reason}: ${d['moderationNote']}'),
      ],
      const SizedBox(height: 16),
      SectionCard(
        title: l.statistics,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _stat(context, l.upcoming, '${stats['upcoming']}'),
            _stat(context, l.statCompleted30d, '${stats['completed30d']}'),
            _stat(
              context,
              l.statEarnings30d,
              context.fmt.money(stats['earnings30dUzs'] as int),
            ),
            _stat(
              context,
              l.rating,
              '★ ${(stats['rating'] as num).toStringAsFixed(1)} '
              '(${stats['reviewCount']})',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SectionCard(
        title: l.documents,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l.licenseNumber}: ${d['licenseNumber']}'),
            for (final ref in docs)
              TextButton.icon(
                onPressed: () => launchUrl(Uri.parse(ref)),
                icon: const Icon(Icons.description_outlined),
                label: Text(ref, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (status == 'approved')
        OutlinedButton.icon(
          onPressed: _busy ? null : _suspend,
          style: OutlinedButton.styleFrom(
            foregroundColor: context.ink(Brand.danger),
          ),
          icon: const Icon(Icons.pause_circle_outline_rounded),
          label: Text(l.suspendDoctor),
        )
      else if (status == 'suspended')
        FilledButton.icon(
          onPressed: _busy ? null : _reinstate,
          icon: const Icon(Icons.play_circle_outline_rounded),
          label: Text(l.reinstateDoctor),
        ),
      const SizedBox(height: 20),
      Text(
        l.reviews,
        style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      if (reviews.isEmpty)
        Text(
          l.noReviewsYet,
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
      for (final r in reviews)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RatingStars(
                      rating: (r['rating'] as int).toDouble(),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${r['authorName']} · '
                        '${context.fmt.date(DateTime.parse(r['at'] as String).toLocal())}',
                        style: context.text.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _toggleReview(r),
                      child: Text(
                        (r['hidden'] as bool? ?? false)
                            ? l.showReview
                            : l.hideReview,
                      ),
                    ),
                  ],
                ),
                if ((r['comment'] as String).isNotEmpty)
                  Text(
                    r['comment'] as String,
                    style: (r['hidden'] as bool? ?? false)
                        ? TextStyle(color: context.colors.onSurfaceVariant)
                        : null,
                  ),
                if (r['hidden'] as bool? ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l.hiddenReview(r['hiddenReason'] as String? ?? ''),
                      style: context.text.bodySmall?.copyWith(
                        color: context.ink(Brand.danger),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _stat(BuildContext context, String label, String value) => SizedBox(
    width: 140,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.colors.primary,
          ),
        ),
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
