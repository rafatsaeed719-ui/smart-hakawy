import 'dart:convert';

/// شخصية بتكلم المستخدم (جاهزة أو من صورة على الموبايل).
class Persona {
  final String id;
  String name;
  String? asset; // صورة جاهزة داخل البرنامج
  String? photoPath; // صورة من الموبايل
  String accent; // en-US / en-GB
  String? voiceName; // اسم الصوت في محرك النطق
  double pitch;
  String gender; // male / female
  String personality; // وصف شخصية المتكلم بالإنجليزي
  // مكان البق والعينين نسبةً لعرض/طول الصورة (0..1)
  double mouthX, mouthY, mouthW;
  double eyeLX, eyeLY, eyeRX, eyeRY, eyeR;
  double faceBottom;
  bool faceFound;

  Persona({
    required this.id,
    required this.name,
    this.asset,
    this.photoPath,
    this.accent = 'en-US',
    this.voiceName,
    this.pitch = 1.0,
    this.gender = 'female',
    this.personality = 'a warm, patient English teacher',
    this.mouthX = 0.5,
    this.mouthY = 0.62,
    this.mouthW = 0.16,
    this.eyeLX = 0.42,
    this.eyeLY = 0.45,
    this.eyeRX = 0.58,
    this.eyeRY = 0.45,
    this.eyeR = 0.035,
    this.faceBottom = 0.75,
    this.faceFound = true,
  });

  bool get isBuiltIn => asset != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'asset': asset,
        'photoPath': photoPath,
        'accent': accent,
        'voiceName': voiceName,
        'pitch': pitch,
        'gender': gender,
        'personality': personality,
        'mouthX': mouthX,
        'mouthY': mouthY,
        'mouthW': mouthW,
        'eyeLX': eyeLX,
        'eyeLY': eyeLY,
        'eyeRX': eyeRX,
        'eyeRY': eyeRY,
        'eyeR': eyeR,
        'faceBottom': faceBottom,
        'faceFound': faceFound,
      };

  static double _d(dynamic v, double def) => v is num ? v.toDouble() : def;

  factory Persona.fromJson(Map<String, dynamic> j) => Persona(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        asset: j['asset'] as String?,
        photoPath: j['photoPath'] as String?,
        accent: (j['accent'] ?? 'en-US') as String,
        voiceName: j['voiceName'] as String?,
        pitch: _d(j['pitch'], 1.0),
        gender: (j['gender'] ?? 'female') as String,
        personality: (j['personality'] ?? 'a warm, patient English teacher') as String,
        mouthX: _d(j['mouthX'], 0.5),
        mouthY: _d(j['mouthY'], 0.62),
        mouthW: _d(j['mouthW'], 0.16),
        eyeLX: _d(j['eyeLX'], 0.42),
        eyeLY: _d(j['eyeLY'], 0.45),
        eyeRX: _d(j['eyeRX'], 0.58),
        eyeRY: _d(j['eyeRY'], 0.45),
        eyeR: _d(j['eyeR'], 0.035),
        faceBottom: _d(j['faceBottom'], 0.75),
        faceFound: (j['faceFound'] ?? true) as bool,
      );

  String encode() => jsonEncode(toJson());
}

/// الشخصيات الجاهزة (رسومات مرفقة مع البرنامج، إحداثياتها معروفة).
List<Persona> builtInPersonas() => [
      Persona(
        id: 'emma',
        name: 'Emma',
        asset: 'assets/avatars/emma.png',
        accent: 'en-US',
        gender: 'female',
        pitch: 1.1,
        personality: 'Emma, a warm and patient American English teacher who loves encouraging learners',
        mouthX: 0.5, mouthY: 0.578, mouthW: 0.13,
        eyeLX: 0.425, eyeLY: 0.44, eyeRX: 0.575, eyeRY: 0.44, eyeR: 0.03,
        faceBottom: 0.66,
      ),
      Persona(
        id: 'james',
        name: 'James',
        asset: 'assets/avatars/james.png',
        accent: 'en-GB',
        gender: 'male',
        pitch: 0.9,
        personality: 'James, a friendly British guy from London who enjoys chatting about travel, football and food',
        mouthX: 0.5, mouthY: 0.578, mouthW: 0.13,
        eyeLX: 0.425, eyeLY: 0.44, eyeRX: 0.575, eyeRY: 0.44, eyeR: 0.03,
        faceBottom: 0.66,
      ),
      Persona(
        id: 'sara',
        name: 'Sara',
        asset: 'assets/avatars/sara.png',
        accent: 'en-US',
        gender: 'female',
        pitch: 1.2,
        personality: 'Sara, a cheerful young American university student, casual and fun',
        mouthX: 0.5, mouthY: 0.578, mouthW: 0.13,
        eyeLX: 0.425, eyeLY: 0.44, eyeRX: 0.575, eyeRY: 0.44, eyeR: 0.03,
        faceBottom: 0.66,
      ),
      Persona(
        id: 'david',
        name: 'Mr. David',
        asset: 'assets/avatars/david.png',
        accent: 'en-US',
        gender: 'male',
        pitch: 0.85,
        personality: 'Mr. David, a professional HR manager who runs realistic job interviews and business conversations',
        mouthX: 0.5, mouthY: 0.578, mouthW: 0.13,
        eyeLX: 0.425, eyeLY: 0.44, eyeRX: 0.575, eyeRY: 0.44, eyeR: 0.03,
        faceBottom: 0.66,
      ),
    ];

class Topic {
  final String emoji;
  final String ar;
  final String en;
  final String icon; // اسم أيقونة 3D
  const Topic(this.emoji, this.ar, this.en, [this.icon = 'speech']);
}

const List<Topic> kTopics = [
  Topic('👋', 'التعارف', 'Getting to know each other', 'waving'),
  Topic('☀️', 'يومي وروتيني', 'My daily routine', 'sun'),
  Topic('✈️', 'السفر والمطار', 'Travel and the airport', 'airplane'),
  Topic('🍽️', 'في المطعم', 'Ordering food at a restaurant', 'fork_knife'),
  Topic('🛍️', 'التسوق', 'Shopping', 'shopping'),
  Topic('💼', 'انترفيو شغل', 'A job interview', 'briefcase'),
  Topic('🏥', 'عند الدكتور', 'At the doctor', 'hospital'),
  Topic('🎬', 'أفلام ومسلسلات', 'Movies and series', 'clapper'),
  Topic('⚽', 'الرياضة', 'Sports', 'soccer'),
  Topic('👨‍👩‍👧', 'العيلة والأصحاب', 'Family and friends', 'family'),
  Topic('🎯', 'أحلامي وأهدافي', 'My dreams and goals', 'bullseye'),
  Topic('💬', 'كلام حر', 'Free conversation about anything', 'speech'),
];

class ChatMsg {
  final bool fromUser;
  final String text;
  String ar;
  String correction;
  String correctionAr;
  ChatMsg({
    required this.fromUser,
    required this.text,
    this.ar = '',
    this.correction = '',
    this.correctionAr = '',
  });
}

class Mistake {
  final String wrong, right, why;
  Mistake(this.wrong, this.right, this.why);
}

class Evaluation {
  final int overall, grammar, vocabulary, fluency, comprehension;
  final String level, summaryAr;
  final List<String> strengths, tips, newWords;
  final List<Mistake> mistakes;
  Evaluation({
    required this.overall,
    required this.grammar,
    required this.vocabulary,
    required this.fluency,
    required this.comprehension,
    required this.level,
    required this.summaryAr,
    required this.strengths,
    required this.tips,
    required this.newWords,
    required this.mistakes,
  });

  static int _i(dynamic v) {
    if (v is num) return v.round().clamp(0, 100);
    return int.tryParse('$v')?.clamp(0, 100) ?? 0;
  }

  static List<String> _ls(dynamic v) =>
      v is List ? v.map((e) => '$e').where((e) => e.trim().isNotEmpty).toList() : <String>[];

  factory Evaluation.fromJson(Map<String, dynamic> j) => Evaluation(
        overall: _i(j['overall']),
        grammar: _i(j['grammar']),
        vocabulary: _i(j['vocabulary']),
        fluency: _i(j['fluency']),
        comprehension: _i(j['comprehension']),
        level: '${j['level'] ?? '-'}',
        summaryAr: '${j['summary_ar'] ?? ''}',
        strengths: _ls(j['strengths_ar']),
        tips: _ls(j['tips_ar']),
        newWords: _ls(j['new_words']),
        mistakes: (j['mistakes'] is List ? j['mistakes'] as List : const [])
            .whereType<Map>()
            .map((m) => Mistake('${m['wrong'] ?? ''}', '${m['right'] ?? ''}', '${m['why_ar'] ?? ''}'))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'grammar': grammar,
        'vocabulary': vocabulary,
        'fluency': fluency,
        'comprehension': comprehension,
        'level': level,
        'summary_ar': summaryAr,
        'strengths_ar': strengths,
        'tips_ar': tips,
        'new_words': newWords,
        'mistakes': mistakes.map((m) => {'wrong': m.wrong, 'right': m.right, 'why_ar': m.why}).toList(),
      };
}
