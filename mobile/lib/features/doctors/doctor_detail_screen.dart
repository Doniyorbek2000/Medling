import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/clinic_time.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';
import '../payments/payment_screen.dart';
import 'specialty.dart';

class DoctorDetailScreen extends StatefulWidget {
  const DoctorDetailScreen({super.key, required this.doctor, this.triageId});
  final Doctor doctor;
  final String? triageId;

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  late final List<DateTime> _days;
  late DateTime _day;
  List<DateTime>? _slots;
  Object? _slotsError;
  DateTime? _selected;
  List<Review>? _reviews;
  final _reason = TextEditingController();
  bool _busy = false;

  MedLinkRepository get _repo => context.read<MedLinkRepository>();

  @override
  void initState() {
    super.initState();
    final today = clinicToday();
    _days = List.generate(14, (i) => today.add(Duration(days: i)));
    _day = _days.first;
    _loadSlots();
    _repo
        .reviews(widget.doctor.id)
        .then(
          (r) => mounted ? setState(() => _reviews = r) : null,
          onError: (Object _) {},
        );
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool _autoAdvanced = false;

  Future<void> _loadSlots() async {
    setState(() {
      _slots = null;
      _slotsError = null;
      _selected = null;
    });
    try {
      final s = await _repo.slots(widget.doctor.id, _day);
      // Bugun bo'sh vaqt qolmagan bo'lsa — ertangi kunga o'tamiz (bir marta).
      if (s.isEmpty && !_autoAdvanced && _day == _days.first) {
        _autoAdvanced = true;
        if (mounted) setState(() => _day = _days[1]);
        return await _loadSlots();
      }
      _autoAdvanced = true;
      if (mounted) setState(() => _slots = s);
    } catch (e) {
      if (mounted) setState(() => _slotsError = e);
    }
  }

  Future<void> _book() async {
    setState(() => _busy = true);
    try {
      final appt = await _repo.book(
        doctorId: widget.doctor.id,
        startsAt: _selected!,
        reason: _reason.text.trim(),
        triageId: widget.triageId,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PaymentScreen(appointment: appt)),
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
    final l = context.l10n;
    final d = widget.doctor;
    return Scaffold(
      appBar: AppBar(title: Text(specialtyName(l, d.specialty))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // ---- Sarlavha ----
          Row(
            children: [
              Avatar(initials: d.initials, radius: 38),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.fullName,
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (d.verified)
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Brand.teal,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l.verifiedLicense,
                            style: const TextStyle(
                              color: Brand.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(value: '${d.experienceYears}', label: l.experienceLabel),
              const SizedBox(width: 10),
              _Stat(value: d.rating.toStringAsFixed(1), label: l.rating),
              const SizedBox(width: 10),
              _Stat(value: '${d.reviewCount}', label: l.reviews),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l.about,
            icon: Icons.info_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.bio.isNotEmpty) Text(d.bio),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.local_hospital_outlined, text: d.clinic),
                _InfoRow(icon: Icons.location_on_outlined, text: d.city),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  text: l.consultationPrice(context.fmt.money(d.priceUzs)),
                ),
              ],
            ),
          ),
          // ---- Sharhlar ----
          if (_reviews != null && _reviews!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: l.patientReviews,
              icon: Icons.reviews_outlined,
              child: Column(
                children: [
                  for (final (i, r) in _reviews!.take(3).indexed) ...[
                    if (i > 0) const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.authorName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        RatingStars(rating: r.rating.toDouble(), size: 14),
                      ],
                    ),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(r.comment),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
          // ---- Bron ----
          const SizedBox(height: 20),
          Text(
            l.chooseDay,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final day = _days[i];
                final sel = day == _day;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() => _day = day);
                    _loadSlots();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 60,
                    decoration: BoxDecoration(
                      color: sel
                          ? context.colors.primary
                          : context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel
                            ? context.colors.primary
                            : context.colors.outlineVariant,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          i == 0 ? l.today : context.fmt.weekdayShort(day),
                          style: TextStyle(
                            fontSize: 12,
                            color: sel
                                ? context.colors.onPrimary
                                : context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: sel
                                ? context.colors.onPrimary
                                : context.colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.chooseTime,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (deviceOutsideClinicZone)
            Text(
              l.tashkentTime,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 10),
          _buildSlots(context),
          const SizedBox(height: 20),
          TextField(
            controller: _reason,
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.visitReason,
              helperText: l.visitReasonHint,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgressButton(
                label: _selected == null
                    ? l.chooseTime
                    : l.bookFor(
                        context.fmt.dateTime(_selected!),
                        context.fmt.money(d.priceUzs),
                      ),
                busy: _busy,
                onPressed: _selected == null ? null : _book,
              ),
              const SizedBox(height: 6),
              Text(
                l.holdNotice,
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlots(BuildContext context) {
    final l = context.l10n;
    if (_slotsError != null) {
      return Row(
        children: [
          Expanded(child: Text(errorText(context, _slotsError!))),
          TextButton(onPressed: _loadSlots, child: Text(l.retry)),
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
    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l.noSlots,
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
      );
    }
    final morning = slots.where((s) => clinicWall(s).hour < 13).toList();
    final afternoon = slots.where((s) => clinicWall(s).hour >= 13).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (title, list) in [
          (l.morning, morning),
          (l.afternoon, afternoon),
        ])
          if (list.isNotEmpty) ...[
            Text(title, style: context.text.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in list)
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
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.colors.primary,
              ),
            ),
            Text(
              label,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
