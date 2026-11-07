import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';

/// Shifokor: ish kunlari, soatlari va konsultatsiya turlari (narxlar bilan).
class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  DoctorSettings? _s;
  Object? _error;
  bool _busy = false;
  final _price = TextEditingController();
  final _onlinePrice = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _price.dispose();
    _onlinePrice.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final s = await context.read<MedLinkRepository>().doctorSettings();
      if (!mounted) return;
      _price.text = '${s.priceUzs}';
      _onlinePrice.text = s.onlinePriceUzs == 0 ? '' : '${s.onlinePriceUzs}';
      setState(() => _s = s);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    final s = _s!;
    final l = context.l10n;
    s
      ..priceUzs = int.tryParse(_price.text) ?? 0
      ..onlinePriceUzs = int.tryParse(_onlinePrice.text) ?? 0;
    if (!s.clinicEnabled && !s.onlineEnabled) {
      showMessage(context, l.chooseConsultationType);
      return;
    }
    if (s.onlineEnabled && s.onlinePriceUzs <= 0) {
      showMessage(context, l.onlinePriceRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<MedLinkRepository>().saveDoctorSettings(s);
      if (mounted) {
        showMessage(context, l.saved);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = _s;
    final locale = Localizations.localeOf(context).languageCode;
    // 2024-01-01 — dushanba: hafta kunlari nomlari lokalga mos.
    String dayName(int d) => DateFormat.E(locale).format(DateTime(2024, 1, d));
    return Scaffold(
      appBar: AppBar(title: Text(l.scheduleAndPrices)),
      body: _error != null
          ? ErrorView(error: _error!, onRetry: _load)
          : s == null
          ? const SkeletonList(count: 3, height: 120)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  title: l.workDays,
                  icon: Icons.calendar_month_outlined,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        FilterChip(
                          label: Text(dayName(d)),
                          selected: s.workDays.contains(d),
                          onSelected: (v) => setState(() {
                            if (v) {
                              s.workDays.add(d);
                            } else if (s.workDays.length > 1) {
                              s.workDays.remove(d);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: l.workHours,
                  icon: Icons.schedule_outlined,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _hourPicker(
                              l.from,
                              s.startHour,
                              List.generate(23, (i) => i),
                              (v) => setState(() {
                                s.startHour = v;
                                if (s.endHour <= v) s.endHour = v + 1;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _hourPicker(l.to, s.endHour, [
                              for (var h = s.startHour + 1; h <= 24; h++) h,
                            ], (v) => setState(() => s.endHour = v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.slotsPerDay((s.endHour - s.startHour) * 2),
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: l.consultationTypes,
                  icon: Icons.medical_services_outlined,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.local_hospital_outlined),
                        title: Text(l.inClinic),
                        value: s.clinicEnabled,
                        onChanged: (v) => setState(() => s.clinicEnabled = v),
                      ),
                      if (s.clinicEnabled) _priceField(_price, l.clinicPrice),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.videocam_outlined),
                        title: Text(l.online),
                        subtitle: Text(l.onlineSubtitle),
                        value: s.onlineEnabled,
                        onChanged: (v) => setState(() => s.onlineEnabled = v),
                      ),
                      if (s.onlineEnabled)
                        _priceField(_onlinePrice, l.onlinePrice),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l.scheduleNote,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: s == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ProgressButton(
                  label: l.save,
                  busy: _busy,
                  onPressed: _save,
                ),
              ),
            ),
    );
  }

  Widget _hourPicker(
    String label,
    int value,
    List<int> options,
    ValueChanged<int> onChanged,
  ) => DropdownButtonFormField<int>(
    initialValue: options.contains(value) ? value : options.first,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final h in options)
        DropdownMenuItem(
          value: h,
          child: Text('${h.toString().padLeft(2, '0')}:00'),
        ),
    ],
    onChanged: (v) => onChanged(v!),
  );

  Widget _priceField(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      decoration: InputDecoration(labelText: label, suffixText: 'UZS'),
    ),
  );
}
