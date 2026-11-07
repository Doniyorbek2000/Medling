import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../doctors/specialties.dart';
import '../security/field_encryption.dart';
import 'medical_model.dart';

enum Urgency { emergency, urgent, routine, selfCare }

class TriageInput {
  TriageInput({
    required this.symptoms,
    required this.ageYears,
    required this.sex,
    this.durationDays,
    this.chronicConditions = const [],
  });

  final String symptoms;
  final int ageYears;
  final String sex; // 'male' | 'female'
  final int? durationDays;
  final List<String> chronicConditions;

  static TriageInput fromJson(Map<String, dynamic> j) {
    final symptoms = (j['symptoms'] as String? ?? '').trim();
    final age = j['ageYears'];
    final sex = j['sex'];
    if (symptoms.length < 5 || symptoms.length > 2000) {
      throw const FormatException('symptoms');
    }
    if (age is! int || age < 0 || age > 120) {
      throw const FormatException('ageYears');
    }
    if (sex != 'male' && sex != 'female') throw const FormatException('sex');
    return TriageInput(
      symptoms: symptoms,
      ageYears: age,
      sex: sex as String,
      durationDays: j['durationDays'] as int?,
      chronicConditions: (j['chronicConditions'] as List? ?? const [])
          .cast<String>(),
    );
  }
}

class PossibleCondition {
  PossibleCondition(this.name, this.likelihood, this.rationale);
  final String name;
  final String likelihood; // high | medium | low
  final String rationale;
  Map<String, dynamic> toJson() => {
    'name': name,
    'likelihood': likelihood,
    'rationale': rationale,
  };
}

class TriageResult {
  TriageResult({
    required this.id,
    required this.urgency,
    required this.conditions,
    required this.specialties,
    required this.redFlags,
    required this.advice,
    required this.model,
  });

  final String id;
  final Urgency urgency;
  final List<PossibleCondition> conditions;
  final List<String> specialties;
  final List<String> redFlags;
  final String advice;
  final String model;

  static const disclaimer =
      'Bu tahlil tashxis emas va shifokor ko\'rigining o\'rnini bosmaydi. '
      'Ahvolingiz og\'irlashsa, darhol 103 raqamiga qo\'ng\'iroq qiling.';

  Map<String, dynamic> toJson() => {
    'id': id,
    'urgency': urgency.name,
    'conditions': conditions.map((c) => c.toJson()).toList(),
    'recommendedSpecialties': specialties,
    'redFlags': redFlags,
    'advice': advice,
    'model': model,
    'disclaimer': disclaimer,
  };
}

/// Alomatlar tahlili. Xavfsizlik qatlamlari:
/// 1. Lokal "qizil bayroq" qoidalari — AI'ga bog'liq bo'lmagan holda shoshilinch
///    holatlarni darhol aniqlaydi.
/// 2. De-identifikatsiya — modelga ism/telefon/e-mail yuborilmaydi, faqat
///    alomatlar, yosh va jins.
/// 3. Javob validatsiyasi — tuzilmaviy JSON, mutaxassisliklar oq ro'yxatdan.
/// 4. Natija shifrlangan holda saqlanadi.
class TriageService {
  TriageService({required this.model, required this.encryption});

  final MedicalModel model;
  final FieldEncryption encryption;

  /// userId -> shifrlangan natijalar (ishlab chiqish uchun xotirada).
  final _store = <String, List<({String id, String enc, DateTime at})>>{};

  /// Qizil bayroq qoidalari [normalizeForRules] dan o'tgan matnga qo'llanadi:
  /// kichik harf, apostroflar olib tashlangan (o', o‘, oʻ, o` va apostrofsiz
  /// yozilganlar bir xil bo'ladi), o'zbek kirill harflari lotinga o'girilgan.
  static final _redFlags = <RegExp, String>{
    RegExp(
      r'kokra[kg].{0,25}(ogri|siqil|bosil|achish)|yurak.{0,15}(ogri|siqil)'
      r'|chest pain|боль в груди|давит в груди',
    ): "Ko'krak qafasidagi og'riq",
    RegExp(
      r'nafas.{0,15}(qis|ololmay|yetishmay|bogil)|bogilyap|задыха'
      r'|не могу дышать|cant breathe|shortness of breath',
    ): 'Nafas olish qiyinlashgan',
    RegExp(
      r'hush.{0,10}(yoqot|ket)|hushsiz|без сознания|потерял сознание'
      r'|unconscious|fainted',
    ): "Hushni yo'qotish",
    RegExp(
      r'(yuz|qol|oyoq).{0,20}(qiyshay|uvush|falaj|sezmay)'
      r'|nutq.{0,10}buzil|gapira olmay|перекосило|онемел',
    ): 'Insult belgilari',
    RegExp(
      r'ozini? (joniga qasd|oldir)|ozimni oldir|yashashni xohlamay'
      r'|суицид|покончить с собой|suicid|kill myself',
    ): "O'z joniga qasd qilish fikrlari",
    RegExp(
      r'kuchli qon ket|qon qus|qon ketyapti|кровотечение|рвота кровью'
      r'|vomiting blood',
    ): 'Kuchli qon ketish',
    RegExp(r'tutqanoq|talvasa|судорог|seizure'): 'Tutqanoq / talvasa',
    RegExp(r'anafilak|tomoq shish|lab.{0,10}shish|отек квинке|отёк'):
        'Kuchli allergik reaksiya',
  };

  /// Faqat o'zbekka xos kirill harflari (rus so'zlariga ta'sir qilmaydi).
  static const _cyrUz = {'ў': 'o', 'ғ': 'g', 'қ': 'q', 'ҳ': 'h'};

  /// Qoidalar uchun matnni normallashtiradi.
  static String normalizeForRules(String text) {
    var t = text.toLowerCase().replaceAll(RegExp("['‘’ʻʼ`´]"), '');
    _cyrUz.forEach((k, v) => t = t.replaceAll(k, v));
    return t;
  }

  static final _piiPatterns = [
    RegExp(r'\+?\d[\d\s\-()]{8,}\d'), // telefon raqamlari
    RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+'), // e-mail
    RegExp(r'\b[A-Z]{2}\d{7}\b'), // pasport seriyasi (AA1234567)
    RegExp(r'\b\d{14}\b'), // JShShIR (PINFL)
  ];

  static String deidentify(String text) {
    var out = text;
    for (final p in _piiPatterns) {
      out = out.replaceAll(p, '[yashirildi]');
    }
    return out;
  }

  static List<String> detectRedFlags(String text) {
    final t = normalizeForRules(text);
    return [
      for (final e in _redFlags.entries)
        if (e.key.hasMatch(t)) e.value,
    ];
  }

  String buildPrompt(TriageInput i) =>
      '''
You are a clinical triage assistant supporting licensed physicians in Uzbekistan.
You do NOT give a final diagnosis. Analyse the patient's symptoms and respond
ONLY with a single JSON object, no prose, in this exact schema:
{
  "urgency": "emergency" | "urgent" | "routine" | "selfCare",
  "conditions": [{"name": string, "likelihood": "high"|"medium"|"low", "rationale": string}],
  "specialties": [one or more of: ${specialties.keys.join(', ')}],
  "redFlags": [string],
  "advice": string
}
Write "name", "rationale", "redFlags" and "advice" in Uzbek (Latin script).
List at most 4 conditions. Prefer a higher urgency when uncertain.

Patient: ${i.ageYears} years old, ${i.sex}.
Duration: ${i.durationDays == null ? 'unknown' : '${i.durationDays} days'}.
Chronic conditions: ${i.chronicConditions.isEmpty ? 'none reported' : i.chronicConditions.map(deidentify).join('; ')}.
Symptoms (patient's words): """${deidentify(i.symptoms)}"""
''';

  static Map<String, dynamic> extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('Model JSON qaytarmadi');
    }
    return jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
  }

  TriageResult parse(String raw, List<String> localFlags) {
    final j = extractJson(raw);
    var urgency = Urgency.values.firstWhere(
      (u) => u.name == j['urgency'],
      orElse: () => Urgency.urgent, // noaniq bo'lsa — ehtiyotkor tomonga
    );
    if (localFlags.isNotEmpty) urgency = Urgency.emergency;

    final specs = ((j['specialties'] as List?) ?? const [])
        .whereType<String>()
        .where(specialties.containsKey)
        .toSet()
        .toList();
    if (specs.isEmpty) specs.add('therapist');

    return TriageResult(
      id: const Uuid().v4(),
      urgency: urgency,
      conditions: ((j['conditions'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .take(4)
          .map(
            (c) => PossibleCondition(
              '${c['name'] ?? ''}',
              const {'high', 'medium', 'low'}.contains(c['likelihood'])
                  ? c['likelihood'] as String
                  : 'low',
              '${c['rationale'] ?? ''}',
            ),
          )
          .toList(),
      specialties: specs,
      redFlags: {
        ...localFlags,
        ...((j['redFlags'] as List?) ?? const []).whereType<String>(),
      }.toList(),
      advice: '${j['advice'] ?? ''}',
      model: model.name,
    );
  }

  Future<TriageResult> analyze(String userId, TriageInput input) async {
    final flags = detectRedFlags(input.symptoms);
    TriageResult result;
    try {
      result = parse(await model.complete(buildPrompt(input)), flags);
    } catch (_) {
      // Model ishlamasa ham bemor javobsiz qolmaydi.
      result = TriageResult(
        id: const Uuid().v4(),
        urgency: flags.isNotEmpty ? Urgency.emergency : Urgency.urgent,
        conditions: const [],
        specialties: const ['therapist'],
        redFlags: flags,
        advice:
            'Hozircha avtomatik tahlil imkoni yo\'q. '
            'Terapevt qabuliga yoziling.',
        model: 'fallback',
      );
    }
    final payload = jsonEncode({'input': input.symptoms, ...result.toJson()});
    (_store[userId] ??= []).add((
      id: result.id,
      enc: await encryption.encrypt(
        payload,
        aad: 'triage:$userId:${result.id}',
      ),
      at: DateTime.now().toUtc(),
    ));
    return result;
  }

  Future<List<Map<String, dynamic>>> history(String userId) async => [
    for (final r in _store[userId] ?? const [])
      {
        ...jsonDecode(
          await encryption.decrypt(r.enc, aad: 'triage:$userId:${r.id}'),
        ) as Map<String, dynamic>,
        'at': r.at.toIso8601String(),
      },
  ];

  /// Bitta tahlil (masalan, shifokor qabul oldidan ko'rishi uchun).
  Future<Map<String, dynamic>?> byId(String userId, String id) async {
    final r = (_store[userId] ?? const []).where((r) => r.id == id).firstOrNull;
    if (r == null) return null;
    return {
      ...jsonDecode(
        await encryption.decrypt(r.enc, aad: 'triage:$userId:${r.id}'),
      ) as Map<String, dynamic>,
      'at': r.at.toIso8601String(),
    };
  }

  /// "Unutilish huquqi": foydalanuvchi so'rovi bilan barcha tahlillar o'chiriladi.
  void deleteAll(String userId) => _store.remove(userId);
}
