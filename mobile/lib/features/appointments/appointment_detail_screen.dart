import 'dart:async';

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
import '../consultation/chat_screen.dart';
import '../consultation/conclusion_screen.dart';
import '../consultation/patient_info_screen.dart';
import '../consultation/video_call_screen.dart';
import '../doctors/specialty.dart';
import '../payments/payment_screen.dart';
import 'appointment_status.dart';
import 'reschedule_screen.dart';

/// Qabul tafsilotlari — bemor va shifokor uchun (rol serverdan `myRole`).
class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.openChat = false,
  });
  final Appointment appointment;

  /// Bildirishnomadan ("Yangi xabar") ochilganda — darhol chatga.
  final bool openChat;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late Appointment _a = widget.appointment;
  bool _busy = false;
  Timer? _clock;

  MedLinkRepository get _repo => context.read<MedLinkRepository>();
  bool get _isDoctor => _a.myRole == 'doctor';

  @override
  void initState() {
    super.initState();
    _refresh();
    // Video tugmasi qabul vaqti kelganda o'zi faollashsin.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    if (widget.openChat) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openChat());
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await _repo.appointment(_a.id);
      if (mounted) setState(() => _a = fresh);
    } catch (_) {}
  }

  String get _peerTitle => _isDoctor
      ? (_a.patientName ?? context.l10n.rolePatient)
      : (_a.doctor?.fullName ?? context.l10n.roleDoctor);

  Future<void> _openChat() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChatScreen(
        appointmentId: _a.id,
        title: _peerTitle,
        subtitle: context.fmt.dateTime(_a.startsAt),
      ),
    ),
  );

  Future<void> _openVideo() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            VideoCallScreen(appointmentId: _a.id, peerTitle: _peerTitle),
      ),
    );
    _refresh();
  }

  Future<void> _writeConclusion() async {
    final updated = await Navigator.of(context).push<Appointment>(
      MaterialPageRoute(builder: (_) => ConclusionScreen(appointment: _a)),
    );
    if (updated != null) _refresh();
  }

  Future<void> _cancel() async {
    final l = context.l10n;
    // Pul qaytarish siyosati oldindan aniq ko'rsatiladi.
    final String policy;
    if (_a.status != 'confirmed') {
      policy = l.cancelAppointmentConfirm;
    } else if (_isDoctor) {
      policy = l.cancelPolicyDoctor;
    } else if (_a.refundableByPatientAt(DateTime.now())) {
      policy = l.cancelPolicyRefund;
    } else {
      policy = l.cancelPolicyNoRefund;
    }
    final ok = await confirmDialog(
      context,
      title: l.cancelAppointment,
      message: policy,
      confirm: l.cancelAppointment,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final refund = await _repo.cancelAppointment(_a.id);
      if (mounted && refund == 'requested') {
        showMessage(context, l.refundRequested);
      } else if (mounted && refund == 'refunded') {
        showMessage(context, l.refundCompletedNow);
      }
      await _refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reschedule() async {
    final updated = await Navigator.of(context).push<Appointment>(
      MaterialPageRoute(builder: (_) => RescheduleScreen(appointment: _a)),
    );
    if (updated != null) await _refresh();
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
    final active = _a.status == 'confirmed' || _a.status == 'awaitingPayment';
    final chatOpen = _a.status == 'confirmed' || _a.status == 'completed';
    final started = !DateTime.now().isBefore(_a.startsAt);
    final canConclude =
        _isDoctor &&
        (_a.status == 'completed' || (_a.status == 'confirmed' && started));

    return Scaffold(
      appBar: AppBar(title: Text(l.appointmentDetails)),
      body: RefreshIndicator.adaptive(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Avatar(
                      initials: _isDoctor
                          ? _initials(_a.patientName)
                          : (d?.initials ?? '?'),
                      radius: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _peerTitle,
                      textAlign: TextAlign.center,
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (d != null && !_isDoctor)
                      Text(specialtyName(l, d.specialty)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        StatusChip(label: label, color: color),
                        StatusChip(
                          label: _a.isOnline ? l.online : l.inClinic,
                          color: _a.isOnline ? Brand.teal : Brand.blue,
                        ),
                        if (_a.refundStatus == 'requested')
                          StatusChip(
                            label: l.refundRequestedShort,
                            color: Brand.warning,
                          ),
                        if (_a.refundStatus == 'refunded')
                          StatusChip(label: l.refundDone, color: Brand.success),
                      ],
                    ),
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
                  if (d != null && !_a.isOnline)
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
            if (_a.isOnline && _a.status == 'confirmed') ...[
              const SizedBox(height: 12),
              _videoCard(context),
            ],
            if (chatOpen) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: Text(l.chat),
                  subtitle: Text(
                    _isDoctor ? l.chatSubtitleDoctor : l.chatSubtitle,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _openChat,
                ),
              ),
            ],
            if (_isDoctor && chatOpen) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_ind_outlined),
                  title: Text(l.patientInfo),
                  subtitle: Text(l.patientInfoSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PatientInfoScreen(appointment: _a),
                    ),
                  ),
                ),
              ),
            ],
            if (_a.reason.isNotEmpty && !_isDoctor) ...[
              const SizedBox(height: 12),
              SectionCard(title: l.visitReason, child: Text(_a.reason)),
            ],
            if (_a.conclusion != null) ...[
              const SizedBox(height: 12),
              ConclusionCard(conclusion: _a.conclusion!),
            ],
            if (_a.review != null) ...[
              const SizedBox(height: 12),
              SectionCard(
                title: _isDoctor ? l.patientReview : l.yourReview,
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
            if (canConclude) ...[
              FilledButton.icon(
                onPressed: _writeConclusion,
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(
                  _a.conclusion == null ? l.writeConclusion : l.editConclusion,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (!_isDoctor && _a.status == 'awaitingPayment') ...[
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
            if (!_isDoctor &&
                _a.status == 'completed' &&
                _a.review == null) ...[
              FilledButton.icon(
                onPressed: _review,
                icon: const Icon(Icons.star_rounded),
                label: Text(l.rateDoctor),
              ),
              const SizedBox(height: 8),
            ],
            if (!_isDoctor &&
                _a.doctor != null &&
                _a.canRescheduleAt(DateTime.now())) ...[
              OutlinedButton.icon(
                onPressed: _busy ? null : _reschedule,
                icon: const Icon(Icons.edit_calendar_rounded),
                label: Text(l.reschedule),
              ),
              const SizedBox(height: 8),
            ],
            if (active)
              OutlinedButton(
                onPressed: _busy ? null : _cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.ink(Brand.danger),
                ),
                child: Text(l.cancelAppointment),
              ),
          ],
        ),
      ),
    );
  }

  Widget _videoCard(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    // Vaqt kelgan VA video xizmati ulangan bo'lsagina "ochiq" ko'rinish.
    final open = _a.videoOpenAt(now) && _a.videoAvailable;
    final tooLate = now.isAfter(_a.startsAt.add(Appointment.lateJoin));
    final String hint;
    if (!_a.videoAvailable) {
      hint = _isDoctor ? l.videoNotConfiguredDoctor : l.videoNotConfigured;
    } else if (open) {
      hint = l.videoReady;
    } else if (tooLate) {
      hint = l.videoClosed;
    } else {
      hint = l.videoOpensAt(
        context.fmt.time(_a.startsAt.subtract(Appointment.earlyJoin)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: open ? Brand.gradient : null,
        color: open ? null : context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: open ? null : Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.videocam_rounded,
                color: open ? Colors.white : context.colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.onlineConsultation,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: open ? Colors.white : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(hint, style: TextStyle(color: open ? Colors.white : null)),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: open
                ? FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Brand.blue,
                  )
                : null,
            onPressed: open && _a.videoAvailable ? _openVideo : null,
            icon: const Icon(Icons.video_call_rounded),
            label: Text(l.joinVideo),
          ),
          if (!open && !tooLate) ...[
            const SizedBox(height: 8),
            Text(
              l.videoTips,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? '').split(' ').where((p) => p.isNotEmpty).take(2);
    return parts.isEmpty ? '+' : parts.map((p) => p[0]).join();
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
