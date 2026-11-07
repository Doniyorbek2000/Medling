import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/session.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../appointments/appointments_screen.dart';
import '../doctors/doctors_screen.dart';

/// Tasdiqlangan shifokor uchun: unga yozilgan bemorlar ro'yxati.
class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  List<Appointment>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<Session>().api.get(
        '/v1/doctor/appointments',
      );
      if (!mounted) return;
      setState(
        () => _items = [
          for (final a in res['items'] as List)
            Appointment.fromJson(a as Map<String, dynamic>),
        ],
      );
    } catch (e) {
      if (mounted) {
        setState(() => _items = const []);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: const Text('Bemorlarim')),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.event_available,
                          text: 'Hozircha yozilgan bemorlar yo\'q',
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final a = items[i];
                        final (label, color) =
                            appointmentStatusLabels[a.status] ??
                            (a.status, Colors.grey);
                        return Card(
                          child: ListTile(
                            title: Text(formatDateTime(a.startsAt)),
                            subtitle: Text(
                              a.reason.isEmpty
                                  ? 'Sabab ko\'rsatilmagan'
                                  : a.reason,
                            ),
                            trailing: Text(
                              label,
                              style: TextStyle(color: color),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
