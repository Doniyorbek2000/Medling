import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';
import '../doctors/specialty.dart';
import '../payments/payment_screen.dart';
import 'appointment_status.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key, required this.appointment});
  final Appointment appointment;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late Appointment _a = widget.appointment;
  bool _busy = false;

  Future<void> _refresh() async {
    final all = await context.read<MedLinkRepository>().appointments();
    final fresh = all.where((x) => x.id == _a.id).firstOrNull;
    if (fresh != null && mounted) setState(() => _a = fresh);
  }

  Future<void> _cancel() async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.cancelAppointment,
      message: l.cancelAppointmentConfirm,
      confirm: l.cancelAppointment,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<MedLinkRepository>().cancelAppointment(_a.id);
      await _refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review() async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReviewSheet(appointment: _a),
    );
    if (done == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = _a.doctor;
    final (label, color) = appointmentStatus(l, _a.status);
    final canCancel =
        _a.status == 'confirmed' || _a.status == 'awaitingPayment';

    return Scaffold(
      appBar: AppBar(title: Text(l.appointmentDetails)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Avatar(initials: d?.initials ?? '?', radius: 36),
                  const SizedBox(height: 12),
                  Text(
                    d?.fullName ?? '',
                    textAlign: TextAlign.center,
                    style: context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (d != null) Text(specialtyName(l, d.specialty)),
                  const SizedBox(height: 12),
                  StatusChip(label: label, color: color),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              children: [
                _row(
                  Icons.calendar_today_rounded,
                  l.dateLabel,
                  context.fmt.fullDate(_a.startsAt),
                ),
                _row(
                  Icons.schedule_rounded,
                  l.timeLabel,
                  context.fmt.time(_a.startsAt),
                ),
                if (d != null)
                  _row(
                    Icons.local_hospital_outlined,
                    l.clinicLabel,
                    '${d.clinic}, ${d.city}',
                  ),
                _row(
                  Icons.payments_outlined,
                  l.priceLabel,
                  context.fmt.money(_a.priceUzs),
                ),
              ],
            ),
          ),
          if (_a.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(title: l.visitReason, child: Text(_a.reason)),
          ],
          if (_a.review != null) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: l.yourReview,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStars(rating: _a.review!.rating.toDouble(), size: 22),
                  if (_a.review!.comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(_a.review!.comment),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_a.status == 'awaitingPayment') ...[
            FilledButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(appointment: _a),
                  ),
                );
                _refresh();
              },
              child: Text(l.pay),
            ),
            const SizedBox(height: 8),
          ],
          if (_a.status == 'completed' && _a.review == null) ...[
            FilledButton.icon(
              onPressed: _review,
              icon: const Icon(Icons.star_rounded),
              label: Text(l.rateDoctor),
            ),
            const SizedBox(height: 8),
          ],
          if (canCancel)
            OutlinedButton(
              onPressed: _busy ? null : _cancel,
              style: OutlinedButton.styleFrom(foregroundColor: Brand.danger),
              child: Text(l.cancelAppointment),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 20, color: context.colors.primary),
        const SizedBox(width: 12),
        Text(k, style: TextStyle(color: context.colors.onSurfaceVariant)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class ReviewSheet extends StatefulWidget {
  const ReviewSheet({super.key, required this.appointment});
  final Appointment appointment;

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _rating = 0;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await context.read<MedLinkRepository>().review(
        widget.appointment.id,
        _rating,
        _comment.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.rateDoctor,
            textAlign: TextAlign.center,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i',
                  iconSize: 40,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = i);
                  },
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFB300),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.reviewHint),
          ),
          const SizedBox(height: 8),
          ProgressButton(
            label: l.submit,
            busy: _busy,
            onPressed: _rating == 0 ? null : _submit,
          ),
        ],
      ),
    );
  }
}
