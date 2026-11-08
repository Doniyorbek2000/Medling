import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/clinic_time.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';

/// Qabulni shu shifokorning boshqa bo'sh vaqtiga ko'chirish. To'lov
/// saqlanadi; qoidalar (24 soat, 2 marta) serverda ham tekshiriladi.
/// Muvaffaqiyatli bo'lsa yangilangan [Appointment] qaytariladi.
class RescheduleScreen extends StatefulWidget {
  const RescheduleScreen({super.key, required this.appointment});
  final Appointment appointment;

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  late final List<DateTime> _days;
  late DateTime _day;
  List<DateTime>? _slots;
  Object? _error;
  DateTime? _selected;
  bool _busy = false;

  MedLinkRepository get _repo => context.read<MedLinkRepository>();
  Appointment get _a => widget.appointment;

  @override
  void initState() {
    super.initState();
    final today = clinicToday();
    _days = List.generate(14, (i) => today.add(Duration(days: i)));
    // Joriy qabul kunidan boshlaymiz (odatda yaqin kunga ko'chiriladi).
    final current = clinicWall(_a.startsAt);
    _day = _days.firstWhere(
      (d) =>
          d.year == current.year &&
          d.month == current.month &&
          d.day == current.day,
      orElse: () => _days.first,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _slots = null;
      _error = null;
      _selected = null;
    });
    try {
      final s = await _repo.slots(_a.doctor!.id, _day);
      if (mounted) setState(() => _slots = s);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _confirm() async {
    final l = context.l10n;
    final t = _selected!;
    final ok = await confirmDialog(
      context,
      title: l.reschedule,
      message: l.rescheduleConfirm(context.fmt.dateTime(t)),
      confirm: l.reschedule,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await _repo.reschedule(_a.id, t);
      HapticFeedback.lightImpact();
      if (!mounted) return;
      showMessage(context, l.rescheduled);
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.rescheduleTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_rounded),
              title: Text(l.currentTime),
              subtitle: Text(context.fmt.dateTime(_a.startsAt)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.rescheduleHint(_a.reschedulesLeft),
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.chooseDay,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = _days[i];
                return ChoiceChip(
                  label: Text(
                    i == 0
                        ? l.today
                        : '${context.fmt.weekdayShort(d)} ${d.day}',
                  ),
                  selected: d == _day,
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() => _day = d);
                    _load();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _slotsView(context),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: _selected == null || _busy ? null : _confirm,
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : Text(l.reschedule),
        ),
      ),
    );
  }

  Widget _slotsView(BuildContext context) {
    final l = context.l10n;
    if (_error != null) {
      return Row(
        children: [
          Expanded(child: Text(errorText(context, _error!))),
          TextButton(onPressed: _load, child: Text(l.retry)),
        ],
      );
    }
    final slots = _slots;
    if (slots == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final free = slots.where((s) => s != _a.startsAt).toList();
    if (free.isEmpty) {
      return Text(
        l.noSlots,
        style: TextStyle(color: context.colors.onSurfaceVariant),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in free)
          ChoiceChip(
            label: Text(context.fmt.time(s)),
            selected: s == _selected,
            showCheckmark: false,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              setState(() => _selected = s);
            },
          ),
      ],
    );
  }
}
