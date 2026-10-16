import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);
  @override
  String toString() => message;
}

/// اتصال مباشر بـ Gemini API (بمفتاح الأدمن المحفوظ في الإعدادات).
class Gemini {
  final String apiKey;
  final String model;
  Gemini(this.apiKey, this.model);

  Future<Map<String, dynamic>> _generate({
    required String system,
    required List<Map<String, dynamic>> contents,
    double temperature = 0.8,
    bool noThinking = true,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw GeminiException('مفتاح الذكاء الاصطناعي مش متسجل. الأدمن لازم يحطه من الإعدادات.');
    }
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${model.trim()}:generateContent');
    final body = <String, dynamic>{
      'systemInstruction': {
        'parts': [
          {'text': system}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'responseMimeType': 'application/json',
        if (noThinking) 'thinkingConfig': {'thinkingBudget': 0},
      },
    };

    http.Response res;
    try {
      res = await http
          .post(uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey.trim(),
              },
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw GeminiException('مفيش اتصال بالإنترنت أو الشبكة ضعيفة. جرّب تاني.');
    }

    if (res.statusCode == 400 && noThinking) {
      // بعض الموديلات مش بتقبل إعداد التفكير — نجرب من غيره
      final txt = utf8.decode(res.bodyBytes);
      if (txt.contains('thinking')) {
        return _generate(
            system: system, contents: contents, temperature: temperature, noThinking: false);
      }
    }
    if (res.statusCode == 429) {
      throw GeminiException('وصلنا للحد المجاني المؤقت للذكاء الاصطناعي. استنى دقيقة وجرّب تاني.');
    }
    if (res.statusCode == 400 || res.statusCode == 403) {
      final txt = utf8.decode(res.bodyBytes);
      if (txt.contains('API key') || txt.contains('API_KEY') || res.statusCode == 403) {
        throw GeminiException('مفتاح الذكاء الاصطناعي غلط أو متوقف. راجع الإعدادات.');
      }
    }
    if (res.statusCode == 404) {
      throw GeminiException('اسم الموديل "$model" مش موجود. غيّره من إعدادات الأدمن.');
    }
    if (res.statusCode != 200) {
      throw GeminiException('حصلت مشكلة في الذكاء الاصطناعي (${res.statusCode}). جرّب تاني.');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw GeminiException('الذكاء الاصطناعي مردّش. جرّب تاني.');
    }
    final parts = (candidates.first['content']?['parts'] as List?) ?? const [];
    final text = parts
        .where((p) => p is Map && p['thought'] != true)
        .map((p) => '${p['text'] ?? ''}')
        .join();
    return _parseJson(text);
  }

  static Map<String, dynamic> _parseJson(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```(json)?'), '').trim();
      if (t.endsWith('```')) t = t.substring(0, t.length - 3).trim();
    }
    try {
      final v = jsonDecode(t);
      if (v is Map<String, dynamic>) return v;
      if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
        return v.first as Map<String, dynamic>;
      }
    } catch (_) {
      final s = t.indexOf('{');
      final e = t.lastIndexOf('}');
      if (s >= 0 && e > s) {
        try {
          return jsonDecode(t.substring(s, e + 1)) as Map<String, dynamic>;
        } catch (_) {}
      }
    }
    return {'reply': t};
  }

  /// يرد على المستخدم في المحادثة.
  Future<Map<String, dynamic>> chat({
    required Persona persona,
    required String topic,
    required String level,
    required List<Map<String, dynamic>> history,
  }) {
    final system = '''
You are ${persona.personality}. Your name is ${persona.name}.
You are having a live SPOKEN English conversation (like a video call) with an Egyptian Arabic-speaking learner.
Learner level: $level. Conversation topic: $topic.

Rules:
- Speak like a real person on a call: natural, warm, short. 1 to 3 sentences, maximum about 40 words.
- Match the learner level: beginner = very simple words and short sentences; intermediate = everyday English; advanced = rich natural English and idioms.
- Always keep the conversation going with ONE follow-up question related to the topic.
- Stay in character. Never use Arabic inside "reply". No emojis, no markdown, no lists (the reply is read aloud).
- If the learner writes in Arabic or mixes, gently help them say it in English.
- If the learner's last message has a real grammar/vocabulary mistake, put the corrected natural sentence in "correction" and a very short Arabic explanation in "correction_ar". If it's fine, leave both empty.

Return ONLY a JSON object:
{"reply": "...", "reply_ar": "Arabic translation of reply (simple Egyptian-friendly Arabic)", "user_ar": "Arabic translation of the learner's last message, empty at the start", "correction": "", "correction_ar": ""}
''';
    return _generate(system: system, contents: history);
  }

  /// تقييم لغة المستخدم في آخر المحادثة.
  Future<Evaluation> evaluate({
    required String topic,
    required String level,
    required List<ChatMsg> messages,
  }) async {
    final transcript = messages
        .map((m) => '${m.fromUser ? 'LEARNER' : 'PARTNER'}: ${m.text}')
        .join('\n');
    final system = '''
You are an expert, encouraging English examiner for Arabic speakers.
Evaluate ONLY the LEARNER's English in this spoken conversation transcript (their speech was captured by speech recognition, so ignore missing punctuation/capitals).
Topic: $topic. Learner's chosen level: $level.

Score each skill from 0 to 100, be fair and realistic. Estimate CEFR level (A1, A2, B1, B2, C1, C2).
Write all explanations in simple, friendly Arabic (Egyptian-friendly).

Return ONLY JSON:
{
 "overall": 0, "grammar": 0, "vocabulary": 0, "fluency": 0, "comprehension": 0,
 "level": "B1",
 "summary_ar": "2-3 sentences overall feedback in Arabic",
 "strengths_ar": ["..."],
 "mistakes": [{"wrong": "learner's sentence/phrase", "right": "corrected English", "why_ar": "short Arabic explanation"}],
 "tips_ar": ["practical tip in Arabic"],
 "new_words": ["useful English word or phrase - Arabic meaning"]
}
Give up to 6 mistakes (the most important), 2-4 strengths, 3 tips, and 5 new words related to the topic.
''';
    final j = await _generate(
      system: system,
      temperature: 0.3,
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': 'TRANSCRIPT:\n$transcript'}
          ]
        }
      ],
    );
    return Evaluation.fromJson(j);
  }

  /// اختبار سريع للمفتاح من لوحة الأدمن.
  Future<void> test() async {
    await _generate(
      system: 'Return JSON {"ok": true}',
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': 'ping'}
          ]
        }
      ],
    );
  }
}
