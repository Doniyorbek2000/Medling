import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';
import '../doctors/specialty.dart';
import '../home/home_shell.dart';
import 'appointment_detail_screen.dart';
import 'appointment_status.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _upcoming = true;
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabAppointments),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
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
                onSelectionChanged: (s) => setState(() => _upcoming = s.first),
              ),
            ),
          ),
          Expanded(
            child: AsyncList<Appointment>(
              key: ValueKey('$_upcoming|$_version'),
              load: () async {
                final all = await repo.appointments();
                return _upcoming
                    ? all.where((a) => a.isUpcoming).toList()
                    : (all
                          .where((a) => !a.isUpcoming)
                          .toList()
                          .reversed
                          .toList());
              },
              empty: EmptyView(
                icon: Icons.event_busy_rounded,
                title: _upcoming ? l.noUpcoming : l.noPast,
                action: _upcoming
                    ? FilledButton(
                        onPressed: () =>
                            HomeTabs.of(context)?.select('doctors'),
                        child: Text(l.findDoctor),
                      )
                    : null,
              ),
              itemBuilder: (context, a, reload) => _AppointmentTile(
                appointment: a,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AppointmentDetailScreen(appointment: a),
                    ),
                  );
                  setState(() => _version++);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment, required this.onTap});
  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = appointment;
    final (label, color) = appointmentStatus(l, a.status);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Avatar(initials: a.doctor?.initials ?? '?', radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.doctor?.fullName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (a.doctor != null)
                      Text(
                        specialtyName(l, a.doctor!.specialty),
                        style: context.text.bodySmall,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          a.isOnline
                              ? Icons.videocam_rounded
                              : Icons.schedule_rounded,
                          size: 16,
                          color: a.isOnline ? context.ink(Brand.teal) : null,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            context.fmt.dateTime(a.startsAt),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusChip(label: label, color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
