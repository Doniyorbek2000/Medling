import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/session.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../payments/payment_screen.dart';
import 'doctors_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  const DoctorDetailScreen({super.key, required this.doctor, this.triageId});
  final Doctor doctor;
  final String? triageId;

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  late DateTime _day;
  List<DateTime>? _slots;
  DateTime? _selected;
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _slots = null;
      _selected = null;
    });
    final d = _day;
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      final res = await context.read<Session>().api.get(
        '/v1/doctors/${widget.doctor.id}/slots',
        {'date': date},
      );
      if (!mounted) return;
      setState(
        () => _slots = [
          for (final s in res['items'] as List)
            DateTime.parse(s as String).toLocal(),
        ],
      );
    } catch (e) {
      if (mounted) {
        setState(() => _slots = const []);
        showError(context, e);
      }
    }
  }

  Future<void> _book() async {
    setState(() => _busy = true);
    try {
      final res = await context.read<Session>().api.post('/v1/appointments', {
        'doctorId': widget.doctor.id,
        'startsAt': _selected!.toUtc().toIso8601String(),
        'reason': _reason.text.trim(),
        'triageId': ?widget.triageId,
      });
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(appointment: Appointment.fromJson(res)),
        ),
      );
    } catch (e) {
      if (mounted) showError(context, e);
      _loadSlots();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doctor;
    final days = List.generate(
      7,
      (i) => _dayOnly(DateTime.now()).add(Duration(days: i)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Shifokor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DoctorCard(doctor: d),
          if (d.bio.isNotEmpty) ...[const SizedBox(height: 12), Text(d.bio)],
          const SizedBox(height: 8),
          Text(
            '${d.city} · ${d.clinic}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Text('Kunni tanlang', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final day in days)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(formatDate(day)),
                      selected: day == _day,
                      onSelected: (_) {
                        _day = day;
                        _loadSlots();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Text('Vaqt', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_slots == null)
            const Center(child: CircularProgressIndicator())
          else if (_slots!.isEmpty)
            const Text('Bu kunda bo\'sh vaqt yo\'q')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _slots!)
                  ChoiceChip(
                    label: Text(formatTime(s)),
                    selected: s == _selected,
                    onSelected: (_) => setState(() => _selected = s),
                  ),
              ],
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _reason,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Murojaat sababi (shifokor ko\'radi)',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _selected != null && !_busy ? _book : null,
            child: Text(
              _selected == null
                  ? 'Vaqtni tanlang'
                  : 'Yozilish · ${formatUzs(d.priceUzs)}',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bron 15 daqiqa davomida saqlanadi — shu vaqt ichida to\'lovni '
            'amalga oshiring.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
