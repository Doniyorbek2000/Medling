import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../doctors/doctors_screen.dart';
import '../payments/payment_screen.dart';

const appointmentStatusLabels = {
  'awaitingPayment': ('To\'lov kutilmoqda', Brand.warning),
  'confirmed': ('Tasdiqlangan', Brand.success),
  'completed': ('Yakunlangan', Brand.blue),
  'cancelled': ('Bekor qilingan', Colors.grey),
};

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Appointment>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<Session>().api.get('/v1/appointments');
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

  Future<void> _cancel(Appointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Qabulni bekor qilish'),
        content: const Text('Haqiqatan ham bekor qilmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Yo\'q'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Ha'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<Session>().api.post('/v1/appointments/${a.id}/cancel');
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: const Text('Qabullarim')),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.event_busy,
                          text: 'Hozircha qabullar yo\'q',
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _tile(items[i]),
                    ),
            ),
    );
  }

  Widget _tile(Appointment a) {
    final (label, color) =
        appointmentStatusLabels[a.status] ?? (a.status, Colors.grey);
    final active = a.status == 'confirmed' || a.status == 'awaitingPayment';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    a.doctor?.fullName ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    label,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                ),
              ],
            ),
            Text(a.doctor?.specialtyName ?? ''),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 4),
                Text(formatDateTime(a.startsAt)),
                const Spacer(),
                Text(formatUzs(a.priceUzs)),
              ],
            ),
            if (active) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (a.status == 'awaitingPayment')
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(appointment: a),
                            ),
                          );
                          _load();
                        },
                        child: const Text('To\'lash'),
                      ),
                    ),
                  if (a.status == 'awaitingPayment') const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancel(a),
                      child: const Text('Bekor qilish'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
