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
  String model;
  bool _discovered = false;
  Gemini(this.apiKey, this.model);

  static const List<Map<String, dynamic>?> _thinkOptions = [
    {'thinkingLevel': 'minimal'},
    {'thinkingBudget': 0},
    {'thinkingLevel': 'low'},
    null,
  ];
  static final Map<String, int> _thinkMemo = {};
  static int _defaultThinkIdx(String m) {
    final v = RegExp(r'gemini-(\d+)').firstMatch(m);
    final major = v == null ? 3 : int.parse(v.group(1)!);
    return major >= 3 ? 0 : 1;
  }

  /// المفتاح بعد شيل أي مسافات أو حروف اتكتبت بالغلط (زي حرف عربي من الكيبورد).
  String get _key => apiKey.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '');

  /// لو الموديل اتوقف من جوجل: نجيب قائمة الموديلات المتاحة ونختار أحدث Flash.
  Future<String?> _discoverModel() async {
    _discovered = true;
    try {
      final res = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?pageSize=300'),
        headers: {'x-goog-api-key': _key},
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final models = (data['models'] as List? ?? const []).whereType<Map>();
      const bad = ['image', 'tts', 'audio', 'live', 'embed', 'exp', 'native', 'robotics', 'computer'];
      String? best;
      double bestScore = -1;
      for (final m in models) {
        final name = '${m['name'] ?? ''}'.replaceFirst('models/', '');
        final methods = (m['supportedGenerationMethods'] as List? ?? const []).map((e) => '$e');
        if (!methods.contains('generateContent')) continue;
        if (!name.startsWith('gemini') || !name.contains('flash')) continue;
        if (bad.any(name.contains)) continue;
        double score;
        if (name == 'gemini-flash-latest') {
          score = 10000;
        } else {
          final v = RegExp(r'gemini-(\d+(?:\.\d+)?)').firstMatch(name);
          if (v == null) continue;
          score = double.parse(v.group(1)!) * 10;
          if (name.contains('preview')) score -= 4;
          if (name.contains('lite')) score -= 1;
          if (RegExp(r'-\d{3}$').hasMatch(name)) score -= 0.5;
        }
        if (score > bestScore) {
          bestScore = score;
          best = name;
        }
      }
      return best;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _generate({
    required String system,
    required List<Map<String, dynamic>> contents,
    double temperature = 0.8,
    int? thinkIdx,
  }) async {
    if (_key.isEmpty) {
      throw GeminiException('مفتاح الذكاء الاصطناعي مش متسجل. الأدمن لازم يحطه من الإعدادات.');
    }
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${model.trim()}:generateContent');
    // أسرع رد: نقفل "التفكير" الزيادة بالطريقة اللي الموديل بيقبلها، ونفتكرها
    final idx = thinkIdx ?? (_thinkMemo[model] ?? _defaultThinkIdx(model));
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
        if (_thinkOptions[idx] != null) 'thinkingConfig': _thinkOptions[idx],
      },
    };

    http.Response res;
    try {
      res = await http
          .post(uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': _key,
              },
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw GeminiException('مفيش اتصال بالإنترنت أو الشبكة ضعيفة. جرّب تاني.');
    }

    if (res.statusCode == 400 && idx < _thinkOptions.length - 1) {
      final txt = utf8.decode(res.bodyBytes).toLowerCase();
      if (txt.contains('thinking')) {
        return _generate(
            system: system, contents: contents, temperature: temperature, thinkIdx: idx + 1);
      }
    }
    if (res.statusCode == 200) _thinkMemo[model] = idx;
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
      if (!_discovered) {
        final m = await _discoverModel();
        if (m != null && m != model) {
          model = m;
          return _generate(system: system, contents: contents, temperature: temperature);
        }
      }
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

  /// يعمل اختبار اختيار من متعدد (10 أسئلة).
  Future<List<QuizQ>> quiz({required String level, required String topic}) async {
    final seed = DateTime.now().millisecondsSinceEpoch % 100000;
    final system = '''
You create short English quizzes for Egyptian Arabic-speaking learners. Level: $level. Theme: $topic.
Make exactly 10 multiple-choice questions, mixing these types:
- 3 "vocab": ask the meaning of an English word or phrase (put it in "text"); options in Arabic.
- 3 "grammar": an English sentence with a blank "___" in "text"; options are English words/phrases.
- 2 "translate": "question_ar" contains an Arabic sentence; options are 4 English sentences, one correct.
- 2 "listen": "text" is a short English sentence that will be READ ALOUD (hidden from the learner); options are 4 similar English sentences, one exactly matching.
Rules: exactly 4 options, only one correct, plausible distractors, difficulty matching the level, no repeated questions, vary vocabulary (variation seed $seed).
"question_ar" is the instruction/question in simple Egyptian-friendly Arabic. "explain_ar" is a one-sentence Arabic explanation of the correct answer.
Return ONLY JSON: {"questions":[{"type":"vocab","question_ar":"...","text":"...","options":["a","b","c","d"],"answer":0,"explain_ar":"..."}]}
''';
    final j = await _generate(
      system: system,
      temperature: 0.9,
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': 'Create the quiz now.'}
          ]
        }
      ],
    );
    final list = (j['questions'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => QuizQ.fromJson(Map<String, dynamic>.from(m)))
        .where((q) => q.options.length >= 2 && q.answer >= 0 && q.answer < q.options.length)
        .toList();
    if (list.isEmpty) throw GeminiException('مقدرناش نجهز الاختبار، جرّب تاني.');
    return list;
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

class QuizQ {
  final String type, questionAr, text, explainAr;
  final List<String> options;
  final int answer;
  QuizQ(this.type, this.questionAr, this.text, this.options, this.answer, this.explainAr);

  factory QuizQ.fromJson(Map<String, dynamic> j) {
    final opts = (j['options'] as List? ?? const []).map((e) => '$e').toList();
    final a = j['answer'];
    return QuizQ(
      '${j['type'] ?? 'vocab'}',
      '${j['question_ar'] ?? ''}',
      '${j['text'] ?? ''}',
      opts,
      a is num ? a.toInt() : int.tryParse('$a') ?? 0,
      '${j['explain_ar'] ?? ''}',
    );
  }
}
