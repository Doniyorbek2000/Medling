import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';
import '../appointments/appointment_detail_screen.dart';
import '../appointments/appointment_status.dart';
import '../notifications/notifications_screen.dart';
import 'doctor_settings_screen.dart';

/// Tasdiqlangan shifokor uchun: unga yozilgan bemorlar ro'yxati.
class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  int _version = 0;
  bool _upcoming = true;

  Future<void> _complete(Appointment a) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.completeVisit,
      message: l.completeVisitConfirm,
      confirm: l.completeVisit,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<MedLinkRepository>().completeAppointment(a.id);
      setState(() => _version++);
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
        title: Text(l.tabPatients),
        automaticallyImplyLeading: false,
        actions: [
          const NotificationBell(),
          IconButton(
            tooltip: l.scheduleAndPrices,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DoctorSettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _StatsStrip(key: ValueKey(_version)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: true, label: Text(l.upcoming)),
                  ButtonSegment(value: false, label: Text(l.past)),
                ],
                selected: {_upcoming},
                onSelectionChanged: (v) => setState(() => _upcoming = v.first),
              ),
            ),
          ),
          Expanded(
            child: AsyncList<Appointment>(
              key: ValueKey('$_version|$_upcoming'),
              load: () async {
                final all = await repo.doctorAppointments();
                return _upcoming
                    ? all.where((a) => a.isUpcoming).toList()
                    : all
                          .where((a) => !a.isUpcoming)
                          .toList()
                          .reversed
                          .toList();
              },
              empty: EmptyView(
                icon: Icons.event_available_rounded,
                title: l.noPatients,
              ),
              itemBuilder: (context, a, _) => _tile(context, a),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Appointment a) {
    final l = context.l10n;
    final (label, color) = appointmentStatus(l, a.status);
    final canComplete =
        a.status == 'confirmed' &&
        !a.isOnline &&
        a.startsAt.isBefore(DateTime.now());
    final videoNow = a.videoOpenAt(DateTime.now()) && a.videoAvailable;
    return Card(
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AppointmentDetailScreen(appointment: a),
            ),
          );
          setState(() => _version++);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    a.isOnline
                        ? Icons.videocam_rounded
                        : Icons.local_hospital_outlined,
                    size: 18,
                    color: context.ink(a.isOnline ? Brand.teal : Brand.blue),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.fmt.dateTime(a.startsAt),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusChip(label: label, color: color),
                ],
              ),
              const SizedBox(height: 8),
              if (a.patientName != null)
                Text(
                  a.patientName!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              Text(
                a.reason.isEmpty ? l.noReason : a.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (videoNow) ...[
                const SizedBox(height: 8),
                StatusChip(label: l.videoReadyShort, color: Brand.teal),
              ],
              if (canComplete) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _complete(a),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: Text(l.completeVisit),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shifokor ish stoli: bugun, kelgusi, xulosa kutayotganlar, 30 kunlik
/// daromad.
class _StatsStrip extends StatefulWidget {
  const _StatsStrip({super.key});

  @override
  State<_StatsStrip> createState() => _StatsStripState();
}

class _StatsStripState extends State<_StatsStrip> {
  DoctorStats? _s;

  @override
  void initState() {
    super.initState();
    context.read<MedLinkRepository>().doctorStats().then(
      (s) => mounted ? setState(() => _s = s) : null,
      onError: (Object _) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = _s;
    if (s == null) return const SizedBox(height: 8);
    final items = <(String, String, Color)>[
      ('${s.today}', l.today, Brand.blue),
      ('${s.upcoming}', l.upcoming, Brand.teal),
      (
        '${s.awaitingConclusion}',
        l.statAwaitingConclusion,
        s.awaitingConclusion > 0 ? Brand.warning : Brand.success,
      ),
      (context.fmt.money(s.earnings30dUzs), l.statEarnings30d, Brand.success),
    ];
    return SizedBox(
      height: 84,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label, color) = items[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.ink(color),
                  ),
                ),
                Text(label, style: context.text.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}
