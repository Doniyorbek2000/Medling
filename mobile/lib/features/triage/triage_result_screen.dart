import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';
import '../doctors/doctors_screen.dart';
import '../doctors/specialty.dart';

({String title, String subtitle, Color color, IconData icon}) urgencyInfo(
  AppLocalizations l,
  Urgency u,
) {
  return switch (u) {
    Urgency.emergency => (
      title: l.urgencyEmergency,
      subtitle: l.urgencyEmergencyBody(AppConfig.emergencyPhone),
      color: Brand.danger,
      icon: Icons.emergency_rounded,
    ),
    Urgency.urgent => (
      title: l.urgencyUrgent,
      subtitle: l.urgencyUrgentBody,
      color: Brand.warning,
      icon: Icons.priority_high_rounded,
    ),
    Urgency.routine => (
      title: l.urgencyRoutine,
      subtitle: l.urgencyRoutineBody,
      color: Brand.blue,
      icon: Icons.event_available_rounded,
    ),
    Urgency.selfCare => (
      title: l.urgencySelfCare,
      subtitle: l.urgencySelfCareBody,
      color: Brand.success,
      icon: Icons.home_rounded,
    ),
  };
}

class TriageResultScreen extends StatelessWidget {
  const TriageResultScreen({super.key, required this.result});
  final TriageResult result;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final u = urgencyInfo(l, result.urgency);
    final likelihood = {
      'high': (l.likelihoodHigh, Brand.danger),
      'medium': (l.likelihoodMedium, Brand.warning),
      'low': (l.likelihoodLow, Brand.blue),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.resultTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: u.color.withValues(alpha: context.isDark ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: u.color.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(u.icon, color: u.color, size: 40),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.title,
                          style: TextStyle(
                            color: u.color,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(u.subtitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (result.urgency == Urgency.emergency) ...[
            const SizedBox(height: 12),
            EmergencyBanner(text: l.callEmergency(AppConfig.emergencyPhone)),
          ],
          if (result.redFlags.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: l.redFlags,
              icon: Icons.warning_amber_rounded,
              child: Column(
                children: [
                  for (final f in result.redFlags)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Brand.danger,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(f)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (result.conditions.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: l.possibleCauses,
              icon: Icons.biotech_outlined,
              child: Column(
                children: [
                  for (final (i, c) in result.conditions.indexed) ...[
                    if (i > 0) const Divider(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (c.rationale.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  c.rationale,
                                  style: context.text.bodySmall?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(
                          label: likelihood[c.likelihood]?.$1 ?? c.likelihood,
                          color: likelihood[c.likelihood]?.$2 ?? Brand.blue,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (result.advice.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: l.advice,
              icon: Icons.tips_and_updates_outlined,
              child: Text(result.advice),
            ),
          ],
          const SizedBox(height: 12),
          SectionCard(
            title: l.whichDoctor,
            icon: Icons.medical_services_outlined,
            child: Column(
              children: [
                for (final s in result.specialties)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      icon: Icon(specialtyIcon(s)),
                      label: Text(l.findSpecialist(specialtyName(l, s))),
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
            result.disclaimer.isEmpty ? l.disclaimer : result.disclaimer,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
