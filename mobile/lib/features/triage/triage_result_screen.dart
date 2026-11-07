import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../doctors/doctors_screen.dart';

class TriageResultScreen extends StatelessWidget {
  const TriageResultScreen({super.key, required this.result});
  final TriageResult result;

  static const _urgency = {
    Urgency.emergency: (
      'Shoshilinch yordam kerak',
      'Darhol 103 ga qo\'ng\'iroq qiling yoki eng yaqin shifoxonaga boring.',
      Brand.danger,
      Icons.emergency,
    ),
    Urgency.urgent: (
      'Tez orada shifokorga ko\'rining',
      'Bugun yoki ertaga shifokor qabuliga yoziling.',
      Brand.warning,
      Icons.priority_high,
    ),
    Urgency.routine: (
      'Rejali qabul',
      'Yaqin kunlarda shifokor ko\'rigidan o\'ting.',
      Brand.blue,
      Icons.event_available,
    ),
    Urgency.selfCare: (
      'Uy sharoitida kuzatish',
      'Holat yomonlashsa, shifokorga murojaat qiling.',
      Brand.success,
      Icons.home_outlined,
    ),
  };

  static const _likelihood = {
    'high': 'Yuqori ehtimol',
    'medium': 'O\'rtacha ehtimol',
    'low': 'Past ehtimol',
  };

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, color, icon) = _urgency[result.urgency]!;
    return Scaffold(
      appBar: AppBar(title: const Text('Tahlil natijasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (result.urgency == Urgency.emergency) ...[
            const SizedBox(height: 12),
            const EmergencyBanner(text: '103 ga qo\'ng\'iroq qilish'),
          ],
          if (result.redFlags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Xavfli belgilar',
              child: Column(
                children: [
                  for (final f in result.redFlags)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.warning_amber,
                        color: Brand.danger,
                      ),
                      title: Text(f),
                    ),
                ],
              ),
            ),
          ],
          if (result.conditions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Ehtimoliy sabablar',
              child: Column(
                children: [
                  for (final c in result.conditions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(c.rationale),
                      trailing: Chip(
                        label: Text(
                          _likelihood[c.likelihood] ?? c.likelihood,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (result.advice.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(title: 'Tavsiya', child: Text(result.advice)),
          ],
          const SizedBox(height: 16),
          _Section(
            title: 'Qaysi shifokorga borish kerak',
            child: Column(
              children: [
                for (final s in result.specialties)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.search),
                      label: Text(DoctorsScreen.specialtyLabel(s)),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DoctorsScreen(
                            initialSpecialty: s,
                            triageId: result.id,
                            standalone: true,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            result.disclaimer,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    ),
  );
}
