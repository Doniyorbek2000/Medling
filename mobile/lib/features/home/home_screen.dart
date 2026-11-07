import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/brand.dart';
import '../doctors/doctors_screen.dart';
import '../triage/triage_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenDoctors});
  final VoidCallback onOpenDoctors;

  static const _quick = [
    ('therapist', 'Terapevt', Icons.healing),
    ('pediatrician', 'Pediatr', Icons.child_care),
    ('cardiologist', 'Kardiolog', Icons.favorite_outline),
    ('neurologist', 'Nevrolog', Icons.psychology_outlined),
    ('dermatologist', 'Dermatolog', Icons.face_retouching_natural),
    ('gynecologist', 'Ginekolog', Icons.pregnant_woman),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/brand/medlink_icon.png', height: 32),
            const SizedBox(width: 8),
            const BrandName(),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AiCard(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const TriageScreen())),
          ),
          const SizedBox(height: 16),
          const EmergencyBanner(),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Mutaxassislar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenDoctors,
                child: const Text('Barchasi'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final (code, name, icon) in _quick)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DoctorsScreen(
                          initialSpecialty: code,
                          standalone: true,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: Brand.blue, size: 30),
                        const SizedBox(height: 8),
                        Text(name, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: Brand.gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alomatlarni tahlil qilish',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Nima bezovta qilayotganini yozing — AI qaysi '
                        'shifokorga borishni va qanchalik shoshilinchligini '
                        'aytadi.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
