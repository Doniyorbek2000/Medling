import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';
import 'doctor_detail_screen.dart';
import 'specialty.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({
    super.key,
    this.initialSpecialty,
    this.triageId,
    this.standalone = false,
  });

  final String? initialSpecialty;
  final String? triageId;

  /// true — alohida sahifa (orqaga tugmasi bilan), false — tab.
  final bool standalone;

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  String? _specialty;

  /// Faqat onlayn qabul qiladiganlar.
  bool _onlineOnly = false;
  String _query = '';
  Timer? _debounce;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _specialty = widget.initialSpecialty;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.standalone && _specialty != null
              ? specialtyName(l, _specialty!)
              : l.tabDoctors,
        ),
        automaticallyImplyLeading: widget.standalone,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: l.searchDoctors,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l.clear,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  if (mounted) setState(() => _query = v.trim());
                });
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: const Icon(Icons.videocam_outlined, size: 18),
                    label: Text(l.online),
                    selected: _onlineOnly,
                    showCheckmark: false,
                    onSelected: (v) => setState(() => _onlineOnly = v),
                  ),
                ),
                _chip(null, l.all),
                for (final code in specialtyCodes)
                  _chip(code, specialtyName(l, code)),
              ],
            ),
          ),
          Expanded(
            child: AsyncList<Doctor>(
              key: ValueKey('$_specialty|$_query|$_onlineOnly'),
              load: () async {
                final list = await repo.doctors(
                  specialty: _specialty,
                  query: _query,
                );
                return _onlineOnly
                    ? list.where((d) => d.onlineEnabled).toList()
                    : list;
              },
              empty: EmptyView(
                icon: Icons.person_search_rounded,
                title: l.noDoctorsFound,
                subtitle: l.noDoctorsFoundHint,
              ),
              itemBuilder: (context, d, _) => DoctorCard(
                doctor: d,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DoctorDetailScreen(
                      doctor: d,
                      triageId: widget.triageId,
                      initialType: _onlineOnly ? 'online' : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String? code, String label) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _specialty == code,
      onSelected: (_) => setState(() => _specialty = code),
    ),
  );
}

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, this.onTap});
  final Doctor doctor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(initials: doctor.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Belgi ism oxiriga yopishgan holda o'raladi (ism ikki
                    // qatorga o'tsa ham o'ng chetga qochmaydi).
                    Text.rich(
                      TextSpan(
                        text: doctor.fullName,
                        children: [
                          if (doctor.verified)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Tooltip(
                                  message: l.verifiedLicense,
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    color: Brand.teal,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialtyName(l, doctor.specialty),
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (doctor.onlineEnabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.videocam_rounded,
                              size: 15,
                              color: context.ink(Brand.teal),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l.onlineAvailable,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.ink(Brand.teal),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      '${l.yearsExperience(doctor.experienceYears)} · ${doctor.clinic}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB300),
                          size: 18,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          ' (${doctor.reviewCount})',
                          style: context.text.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.fmt.money(doctor.priceUzs),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
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
