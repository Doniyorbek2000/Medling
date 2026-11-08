import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';
import 'moderation_screen.dart';

/// Admin paneli: statistika, shifokor arizalari, pul qaytarish navbati.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.tabAdmin),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: [
              Tab(text: l.statistics),
              Tab(text: l.applications),
              Tab(text: l.refunds),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StatsTab(),
            ModerationScreen(embedded: true),
            _RefundsTab(),
          ],
        ),
      ),
    );
  }
}

class _StatsTab extends StatefulWidget {
  const _StatsTab();

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  AdminStats? _s;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await context.read<MedLinkRepository>().adminStats();
      if (mounted) {
        setState(() {
          _s = s;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = _s;
    if (_error != null && s == null) {
      return ErrorView(error: _error!, onRetry: _load);
    }
    if (s == null) return const SkeletonList(count: 4, height: 90);
    final tiles = <(IconData, String, String, Color)>[
      (Icons.people_alt_outlined, l.statUsers, '${s.users}', Brand.blue),
      (
        Icons.verified_outlined,
        l.statDoctors,
        '${s.doctorsApproved}',
        Brand.teal,
      ),
      (
        Icons.pending_actions_outlined,
        l.statPendingApplications,
        '${s.doctorsPending}',
        Brand.warning,
      ),
      (Icons.today_outlined, l.statToday, '${s.appointmentsToday}', Brand.blue),
      (
        Icons.payments_outlined,
        l.statRevenue30d,
        context.fmt.money(s.revenue30dUzs),
        Brand.success,
      ),
      (
        Icons.videocam_outlined,
        l.statOnlineShare,
        '${s.onlineShare}%',
        Brand.teal,
      ),
      (
        Icons.undo_rounded,
        l.statRefundsPending,
        '${s.refundsPending} · ${context.fmt.money(s.refundsPendingUzs)}',
        s.refundsPending > 0 ? Brand.danger : Brand.success,
      ),
    ];
    final statuses = s.appointmentsByStatus;
    return RefreshIndicator.adaptive(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 104,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: tiles.length,
            itemBuilder: (_, i) {
              final (icon, label, value, color) = tiles[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: context.ink(color), size: 22),
                      const Spacer(),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: context.text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l.statAppointments,
            icon: Icons.event_note_outlined,
            child: Column(
              children: [
                for (final (key, label) in [
                  ('confirmed', l.statusConfirmed),
                  ('awaitingPayment', l.statusAwaitingPayment),
                  ('completed', l.statusCompleted),
                  ('cancelled', l.statusCancelled),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(label)),
                        Text(
                          '${statuses[key] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundsTab extends StatefulWidget {
  const _RefundsTab();

  @override
  State<_RefundsTab> createState() => _RefundsTabState();
}

class _RefundsTabState extends State<_RefundsTab> {
  int _version = 0;

  String _reason(AppLocalizations l, String r) => switch (r) {
    'doctor_cancelled' => l.refundReasonDoctor,
    'patient_cancelled_early' => l.refundReasonPatient,
    _ => r,
  };

  Future<void> _complete(RefundRequest r) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.markRefunded,
      message: l.markRefundedConfirm(r.provider == 'payme' ? 'Payme' : 'Click'),
      confirm: l.markRefunded,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<MedLinkRepository>().completeRefund(r.orderId);
      if (mounted) setState(() => _version++);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AsyncList<RefundRequest>(
      key: ValueKey(_version),
      load: context.read<MedLinkRepository>().refunds,
      empty: EmptyView(icon: Icons.task_alt_rounded, title: l.noRefunds),
      itemBuilder: (context, r, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.fmt.money(r.amountUzs),
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: r.provider.toUpperCase(),
                    color: Brand.blue,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(_reason(l, r.reason)),
              Text(
                l.requestedAt(context.fmt.dateTime(r.requestedAt)),
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              if (r.providerTxnId != null)
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: r.providerTxnId!));
                    showMessage(context, l.copied);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.copy_rounded, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l.transactionId(r.providerTxnId!),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _complete(r),
                icon: const Icon(Icons.check_rounded),
                label: Text(l.markRefunded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
