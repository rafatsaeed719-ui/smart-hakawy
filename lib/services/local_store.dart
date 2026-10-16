import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../phrases_data.dart';

/// حاجات بتتحفظ على الموبايل: الجمل المحفوظة، الترحيب، سرعة الصوت.
class LocalStore {
  static const _savedKey = 'saved_phrases_v1';

  static Future<List<Phrase>> savedPhrases() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_savedKey) ?? [];
    final out = <Phrase>[];
    for (final s in list) {
      try {
        final j = jsonDecode(s) as Map;
        out.add(Phrase('${j['en']}', '${j['ar'] ?? ''}'));
      } catch (_) {}
    }
    return out;
  }

  static Future<Set<String>> savedSet() async =>
      (await savedPhrases()).map((e) => e.en.trim().toLowerCase()).toSet();

  /// بيرجع true لو اتحفظت، false لو كانت محفوظة واتشالت.
  static Future<bool> toggle(Phrase ph) async {
    final p = await SharedPreferences.getInstance();
    final list = await savedPhrases();
    final key = ph.en.trim().toLowerCase();
    final i = list.indexWhere((e) => e.en.trim().toLowerCase() == key);
    bool saved;
    if (i >= 0) {
      list.removeAt(i);
      saved = false;
    } else {
      list.insert(0, ph);
      saved = true;
    }
    await p.setStringList(
        _savedKey, list.map((e) => jsonEncode({'en': e.en, 'ar': e.ar})).toList());
    return saved;
  }

  static Future<bool> save(Phrase ph) async {
    final set = await savedSet();
    if (set.contains(ph.en.trim().toLowerCase())) return false;
    return toggle(ph);
  }

  static Future<bool> welcomed() async =>
      (await SharedPreferences.getInstance()).getBool('welcomed_v1') ?? false;

  static Future<void> setWelcomed() async =>
      (await SharedPreferences.getInstance()).setBool('welcomed_v1', true);

  static Future<double?> speechRate() async =>
      (await SharedPreferences.getInstance()).getDouble('speech_rate');

  static Future<void> setSpeechRate(double v) async =>
      (await SharedPreferences.getInstance()).setDouble('speech_rate', v);
}
