import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import 'doctor_detail_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({
    super.key,
    this.initialSpecialty,
    this.triageId,
    this.standalone = false,
  });

  final String? initialSpecialty;
  final String? triageId;
  final bool standalone;

  static const _labels = {
    'therapist': 'Terapevt',
    'pediatrician': 'Pediatr',
    'cardiologist': 'Kardiolog',
    'neurologist': 'Nevrolog',
    'gastroenterologist': 'Gastroenterolog',
    'pulmonologist': 'Pulmonolog',
    'endocrinologist': 'Endokrinolog',
    'dermatologist': 'Dermatolog',
    'ent': 'LOR',
    'ophthalmologist': 'Oftalmolog',
    'gynecologist': 'Ginekolog',
    'urologist': 'Urolog',
    'traumatologist': 'Travmatolog',
    'psychiatrist': 'Psixiatr',
  };

  static String specialtyLabel(String code) => _labels[code] ?? code;

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  String? _specialty;
  String _query = '';
  Timer? _debounce;
  List<Doctor>? _doctors;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _specialty = widget.initialSpecialty;
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final res = await context.read<Session>().api.get('/v1/doctors', {
        'specialty': ?_specialty,
        if (_query.isNotEmpty) 'q': _query,
      });
      if (!mounted) return;
      setState(
        () => _doctors = [
          for (final d in res['items'] as List)
            Doctor.fromJson(d as Map<String, dynamic>),
        ],
      );
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctors = _doctors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shifokorlar'),
        automaticallyImplyLeading: widget.standalone,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Ism yoki klinika',
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  _query = v.trim();
                  _load();
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
                _chip(null, 'Barchasi'),
                for (final e in DoctorsScreen._labels.entries)
                  _chip(e.key, e.value),
              ],
            ),
          ),
          Expanded(
            child: _error != null
                ? Center(
                    child: TextButton(
                      onPressed: _load,
                      child: const Text('Qayta urinish'),
                    ),
                  )
                : doctors == null
                ? const Center(child: CircularProgressIndicator())
                : doctors.isEmpty
                ? const Center(
                    child: Text('Tasdiqlangan shifokorlar topilmadi'),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: doctors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => DoctorCard(
                        doctor: doctors[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DoctorDetailScreen(
                              doctor: doctors[i],
                              triageId: widget.triageId,
                            ),
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
      onSelected: (_) {
        setState(() {
          _specialty = code;
          _doctors = null;
        });
        _load();
      },
    ),
  );
}

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, this.onTap});
  final Doctor doctor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Brand.blue.withValues(alpha: 0.1),
                child: Text(
                  doctor.initials,
                  style: const TextStyle(
                    color: Brand.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            doctor.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (doctor.verified) ...[
                          const SizedBox(width: 4),
                          const Tooltip(
                            message: 'Litsenziya tekshirilgan',
                            child: Icon(
                              Icons.verified,
                              color: Brand.teal,
                              size: 18,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doctor.specialtyName} · ${doctor.experienceYears} yil tajriba',
                    ),
                    Text(
                      doctor.clinic,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(doctor.rating.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatUzs(doctor.priceUzs),
                    style: const TextStyle(
                      color: Brand.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bo'sh holatlar uchun.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: Brand.teal),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
        const SizedBox(height: 60),
        const MedLinkLogo(size: 40, showName: false),
      ],
    ),
  );
}
