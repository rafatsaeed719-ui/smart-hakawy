import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models.dart';

/// النطق (الشخصية بتتكلم) والاستماع (المستخدم بيتكلم).
class Voice {
  Voice._();
  static final Voice I = Voice._();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;
  bool _ttsReady = false;

  /// بيتنده مع كل كلمة بتتنطق (لحركة البق).
  VoidCallback? onWord;
  final ValueNotifier<bool> speaking = ValueNotifier(false);
  final ValueNotifier<bool> listening = ValueNotifier(false);
  double rate = 0.5;

  Future<void> _initTts() async {
    if (_ttsReady) return;
    _ttsReady = true;
    await _tts.awaitSpeakCompletion(true);
    _tts.setStartHandler(() => speaking.value = true);
    _tts.setCompletionHandler(() => speaking.value = false);
    _tts.setCancelHandler(() => speaking.value = false);
    _tts.setErrorHandler((_) => speaking.value = false);
    _tts.setProgressHandler((text, start, end, word) => onWord?.call());
  }

  /// قائمة الأصوات الإنجليزي المتاحة على الموبايل.
  Future<List<Map<String, String>>> englishVoices() async {
    await _initTts();
    try {
      final v = await _tts.getVoices;
      if (v is! List) return [];
      final out = <Map<String, String>>[];
      for (final e in v) {
        if (e is Map) {
          final name = '${e['name'] ?? ''}';
          final locale = '${e['locale'] ?? ''}';
          if (locale.toLowerCase().startsWith('en') && name.isNotEmpty) {
            out.add({'name': name, 'locale': locale});
          }
        }
      }
      out.sort((a, b) => a['locale']!.compareTo(b['locale']!) != 0
          ? a['locale']!.compareTo(b['locale']!)
          : a['name']!.compareTo(b['name']!));
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> configure(Persona p) async {
    await _initTts();
    await _tts.setLanguage(p.accent);
    if (p.voiceName != null && p.voiceName!.isNotEmpty) {
      final voices = await englishVoices();
      final match = voices.where((v) => v['name'] == p.voiceName);
      if (match.isNotEmpty) {
        await _tts.setVoice({'name': match.first['name']!, 'locale': match.first['locale']!});
      }
    }
    await _tts.setPitch(p.pitch);
    await _tts.setSpeechRate(rate);
    await _tts.setVolume(1.0);
  }

  Future<void> speak(String text) async {
    await _initTts();
    if (text.trim().isEmpty) return;
    speaking.value = true;
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
    speaking.value = false;
  }

  /// نطق بسرعة معيّنة (للنطق البطيء في تدريب النطق).
  Future<void> speakAt(String text, double r) async {
    await _initTts();
    if (text.trim().isEmpty) return;
    speaking.value = true;
    await _tts.setSpeechRate(r);
    await _tts.speak(text);
    await _tts.setSpeechRate(rate);
    speaking.value = false;
  }

  /// صوت افتراضي (للعبارات والاختبارات).
  Future<void> useDefaultVoice({String accent = 'en-US'}) async {
    await _initTts();
    await _tts.setLanguage(accent);
    await _tts.setPitch(1.0);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    speaking.value = false;
  }

  Future<bool> _initStt() async {
    if (_sttReady) return true;
    _sttReady = await _stt.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') listening.value = false;
      },
      onError: (_) => listening.value = false,
    );
    return _sttReady;
  }

  /// يبدأ يسمع المستخدم بالإنجليزي.
  Future<bool> listen({
    required void Function(String text, bool isFinal) onText,
    String locale = 'en_US',
  }) async {
    if (!await _initStt()) return false;
    await stopSpeaking();
    listening.value = true;
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) => onText(r.recognizedWords, r.finalResult),
      localeId: locale,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(milliseconds: 1800),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
    return true;
  }

  Future<void> stopListening() async {
    await _stt.stop();
    listening.value = false;
  }

  Future<void> cancelAll() async {
    try {
      await _stt.cancel();
    } catch (_) {}
    listening.value = false;
    await stopSpeaking();
  }
}
