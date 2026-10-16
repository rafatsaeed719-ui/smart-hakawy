import 'package:flutter/material.dart';

import '../phrases_data.dart';
import '../progress.dart';
import '../services/data.dart';
import '../services/pronunciation.dart';
import '../services/voice.dart';
import '../theme.dart';
import '../widgets/icon3d.dart';

/// تدريب النطق: اسمع الجملة، قولها، وشوف الكلمات اللي محتاجة تتظبط.
class PronunciationScreen extends StatefulWidget {
  final List<Phrase> phrases;
  final int start;
  final String title;
  const PronunciationScreen({
    super.key,
    required this.phrases,
    this.start = 0,
    this.title = 'تدريب النطق',
  });

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> {
  late int _i = widget.start.clamp(0, widget.phrases.length - 1);
  PronResult? _result;
  String _heard = '';
  bool _listening = false;
  final _rewarded = <int>{};
  int _sessionXp = 0;

  Phrase get _p => widget.phrases[_i];

  @override
  void initState() {
    super.initState();
    Voice.I.useDefaultVoice();
    Voice.I.listening.addListener(_onListen);
  }

  @override
  void dispose() {
    Voice.I.listening.removeListener(_onListen);
    Voice.I.cancelAll();
    if (_sessionXp > 0) Data.addXp(_sessionXp);
    super.dispose();
  }

  void _onListen() {
    if (!mounted) return;
    final l = Voice.I.listening.value;
    if (!l && _listening) {
      setState(() => _listening = false);
      if (_result == null && _heard.trim().isNotEmpty) _evaluate(_heard);
    }
  }

  Future<void> _mic() async {
    if (_listening) {
      await Voice.I.stopListening();
      return;
    }
    setState(() {
      _result = null;
      _heard = '';
      _listening = true;
    });
    final ok = await Voice.I.listen(onText: (t, isFinal) {
      if (!mounted) return;
      setState(() => _heard = t);
      if (isFinal) _evaluate(t);
    });
    if (!ok && mounted) {
      setState(() => _listening = false);
      toast(context, 'لازم تسمح للبرنامج يستخدم المايك', error: true);
    }
  }

  void _evaluate(String heard) {
    if (_result != null) return;
    final r = scorePronunciation(_p.en, heard);
    setState(() => _result = r);
    if (r.score >= 80 && !_rewarded.contains(_i)) {
      _rewarded.add(_i);
      _sessionXp += Xp.perGoodPronunciation;
    }
  }

  void _go(int d) {
    final n = (_i + d).clamp(0, widget.phrases.length - 1);
    setState(() {
      _i = n;
      _result = null;
      _heard = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: Text('${_i + 1} / ${widget.phrases.length}',
                  style: const TextStyle(color: AppColors.muted)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_i + 1) / widget.phrases.length,
              minHeight: 6,
              backgroundColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(children: [
              const Icon3D('ear', size: 54),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (int k = 0; k < (r?.words.length ?? 0); k++)
                      Text(r!.words[k],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: r.ok[k] ? AppColors.mint : AppColors.danger,
                            decoration: r.ok[k] ? null : TextDecoration.underline,
                            decorationColor: AppColors.danger,
                          )),
                    if (r == null)
                      Text(_p.en,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(_p.ar,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 16)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundBtn(icon: 'speaker', label: 'اسمع', onTap: () => Voice.I.speakAt(_p.en, 0.45)),
                  const SizedBox(width: 18),
                  _RoundBtn(icon: 'turtle', label: 'ببطء', onTap: () => Voice.I.speakAt(_p.en, 0.25)),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 26),
          Center(
            child: GestureDetector(
              onTap: _mic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _listening ? 96 : 86,
                height: _listening ? 96 : 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening ? AppColors.mint : AppColors.accent,
                  boxShadow: [
                    BoxShadow(
                      color: (_listening ? AppColors.mint : AppColors.accent).withValues(alpha: 0.5),
                      blurRadius: _listening ? 30 : 16,
                    )
                  ],
                ),
                child: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 42, color: const Color(0xFF1A1030)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _listening
                ? (_heard.isEmpty ? 'بسمعك… قول الجملة' : _heard)
                : (r == null ? 'دوس على المايك وقول الجملة بالإنجليزي' : 'انت قلت: "$_heard"'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          if (r != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (r.score >= 80 ? AppColors.mint : r.score >= 50 ? AppColors.accent : AppColors.danger)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Icon3D(r.score >= 90 ? 'hundred' : r.score >= 70 ? 'clap' : 'muscle', size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r.score}%',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    Text(
                      r.score >= 90
                          ? 'نطق ممتاز! زي الأجانب بالظبط 🤩'
                          : r.score >= 70
                              ? 'حلو جدًا! ركّز على الكلمات الحمرا وجرّب تاني'
                              : r.score >= 40
                                  ? 'قربت! اسمعها ببطء وقولها كلمة كلمة'
                                  : 'ولا يهمك، اسمعها الأول ببطء وكررها معاها',
                      style: const TextStyle(height: 1.5),
                    ),
                  ]),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _i > 0 ? () => _go(-1) : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('السابقة'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _i < widget.phrases.length - 1 ? () => _go(1) : () => Navigator.pop(context),
                icon: Icon(_i < widget.phrases.length - 1 ? Icons.arrow_back_rounded : Icons.check_rounded),
                label: Text(_i < widget.phrases.length - 1 ? 'اللي بعدها' : 'خلصت'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
              ),
            ),
          ]),
          if (_sessionXp > 0)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text('+$_sessionXp نقطة في التدريب ده ✨',
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.accent)),
            ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon3D(icon, size: 28),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
