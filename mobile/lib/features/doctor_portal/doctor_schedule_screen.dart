import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';
import '../appointments/appointment_status.dart';

/// Tasdiqlangan shifokor uchun: unga yozilgan bemorlar ro'yxati.
class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  int _version = 0;

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
      ),
      body: AsyncList<Appointment>(
        key: ValueKey(_version),
        load: repo.doctorAppointments,
        empty: EmptyView(
          icon: Icons.event_available_rounded,
          title: l.noPatients,
        ),
        itemBuilder: (context, a, _) {
          final (label, color) = appointmentStatus(l, a.status);
          final canComplete =
              a.status == 'confirmed' && a.startsAt.isBefore(DateTime.now());
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 18),
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
                  Text(a.reason.isEmpty ? l.noReason : a.reason),
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
          );
        },
      ),
    );
  }
}
