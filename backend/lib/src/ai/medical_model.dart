import 'dart:convert';

import 'package:http/http.dart' as http;

/// Tibbiy til modeli uchun abstraksiya. Asosiy implementatsiya — Google'ning
/// Med-PaLM 2 modeli (Vertex AI'da "MedLM" nomi bilan taqdim etiladi).
/// Model mavjud bo'lmasa, xuddi shu interfeys orqali boshqa Vertex AI modeliga
/// (masalan MedGemma) o'tish mumkin — ilova kodi o'zgarmaydi.
abstract class MedicalModel {
  String get name;
  Future<String> complete(String prompt);
}

/// Google Cloud OAuth tokenini olish. Cloud Run / GKE'da metadata serveridan,
/// lokal ishlab chiqishda `GCP_ACCESS_TOKEN` (gcloud auth print-access-token).
class GcpTokenProvider {
  GcpTokenProvider(this._client, {this.staticToken});
  final http.Client _client;
  final String? staticToken;

  String? _cached;
  DateTime _expires = DateTime.fromMillisecondsSinceEpoch(0);

  Future<String> token() async {
    if (staticToken != null && staticToken!.isNotEmpty) return staticToken!;
    if (_cached != null && DateTime.now().isBefore(_expires)) return _cached!;
    final res = await _client.get(
      Uri.parse(
        'http://metadata.google.internal/computeMetadata/v1/'
        'instance/service-accounts/default/token',
      ),
      headers: {'Metadata-Flavor': 'Google'},
    );
    if (res.statusCode != 200) {
      throw StateError('GCP token olinmadi: ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    _cached = j['access_token'] as String;
    _expires = DateTime.now().add(
      Duration(seconds: (j['expires_in'] as int) - 60),
    );
    return _cached!;
  }
}

/// Med-PaLM 2 (Vertex AI MedLM: `medlm-medium` / `medlm-large`) — `:predict`.
class VertexMedLmModel implements MedicalModel {
  VertexMedLmModel({
    required this.client,
    required this.tokens,
    required this.project,
    required this.location,
    this.model = 'medlm-large',
  });

  final http.Client client;
  final GcpTokenProvider tokens;
  final String project;
  final String location;
  final String model;

  @override
  String get name => 'vertex:$model';

  Uri get _endpoint => Uri.parse(
    'https://$location-aiplatform.googleapis.com/v1/projects/$project/'
    'locations/$location/publishers/google/models/$model:predict',
  );

  @override
  Future<String> complete(String prompt) async {
    final res = await client
        .post(
          _endpoint,
          headers: {
            'authorization': 'Bearer ${await tokens.token()}',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'instances': [
              {'content': prompt},
            ],
            'parameters': {
              'temperature': 0.1,
              'maxOutputTokens': 1024,
              'topK': 40,
              'topP': 0.8,
            },
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) {
      // Javob tanasini log qilmaymiz — unda so'rov matni qaytishi mumkin.
      throw StateError('Vertex AI xatosi: ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final preds = j['predictions'] as List;
    return (preds.first as Map<String, dynamic>)['content'] as String;
  }
}

/// Zaxira: Vertex AI `generateContent` API'si orqali ishlaydigan modellar
/// (masalan Model Garden'dan joylashtirilgan MedGemma yoki Gemini).
class VertexGenerateContentModel implements MedicalModel {
  VertexGenerateContentModel({
    required this.client,
    required this.tokens,
    required this.project,
    required this.location,
    required this.model,
  });

  final http.Client client;
  final GcpTokenProvider tokens;
  final String project;
  final String location;
  final String model;

  @override
  String get name => 'vertex:$model';

  @override
  Future<String> complete(String prompt) async {
    final res = await client
        .post(
          Uri.parse(
            'https://$location-aiplatform.googleapis.com/v1/projects/'
            '$project/locations/$location/publishers/google/models/'
            '$model:generateContent',
          ),
          headers: {
            'authorization': 'Bearer ${await tokens.token()}',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.1,
              'maxOutputTokens': 1024,
              'responseMimeType': 'application/json',
            },
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) {
      throw StateError('Vertex AI xatosi: ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final parts =
        (((j['candidates'] as List).first as Map<String, dynamic>)['content']
                as Map<String, dynamic>)['parts']
            as List;
    return parts.map((p) => (p as Map<String, dynamic>)['text']).join();
  }
}
