import 'package:flutter/material.dart';

import '../../core/l10n.dart';

String specialtyName(AppLocalizations l, String code) => switch (code) {
  'therapist' => l.specTherapist,
  'pediatrician' => l.specPediatrician,
  'cardiologist' => l.specCardiologist,
  'neurologist' => l.specNeurologist,
  'gastroenterologist' => l.specGastroenterologist,
  'pulmonologist' => l.specPulmonologist,
  'endocrinologist' => l.specEndocrinologist,
  'dermatologist' => l.specDermatologist,
  'ent' => l.specEnt,
  'ophthalmologist' => l.specOphthalmologist,
  'gynecologist' => l.specGynecologist,
  'urologist' => l.specUrologist,
  'traumatologist' => l.specTraumatologist,
  'psychiatrist' => l.specPsychiatrist,
  _ => code,
};

IconData specialtyIcon(String code) => switch (code) {
  'therapist' => Icons.healing_rounded,
  'pediatrician' => Icons.child_care_rounded,
  'cardiologist' => Icons.favorite_rounded,
  'neurologist' => Icons.psychology_rounded,
  'gastroenterologist' => Icons.lunch_dining_rounded,
  'pulmonologist' => Icons.air_rounded,
  'endocrinologist' => Icons.bloodtype_rounded,
  'dermatologist' => Icons.face_retouching_natural_rounded,
  'ent' => Icons.hearing_rounded,
  'ophthalmologist' => Icons.visibility_rounded,
  'gynecologist' => Icons.pregnant_woman_rounded,
  'urologist' => Icons.water_drop_rounded,
  'traumatologist' => Icons.accessibility_new_rounded,
  'psychiatrist' => Icons.self_improvement_rounded,
  _ => Icons.medical_services_rounded,
};
