import 'package:flutter/material.dart';

import '../progress.dart';
import '../services/data.dart';
import '../services/gemini.dart';
import '../services/voice.dart';
import '../theme.dart';
import '../widgets/icon3d.dart';

class _Lvl {
  final String key, ar, icon, desc;
  const _Lvl(this.key, this.ar, this.icon, this.desc);
}

const _levels = [
  _Lvl('Beginner (A1-A2)', 'مبتدئ', 'seedling', 'كلمات وجمل بسيطة'),
  _Lvl('Intermediate (B1-B2)', 'متوسط', 'rocket', 'قواعد ومواقف يومية'),
  _Lvl('Advanced (C1)', 'متقدم', 'crown', 'تعبيرات وأسلوب طبيعي'),
];

const _themes = <String, String>{
  'عام': 'general everyday English',
  'السفر': 'travel',
  'الشغل': 'work and jobs',
  'المطعم والتسوق': 'restaurants and shopping',
  'المشاعر': 'feelings and emotions',
  'الأفعال': 'common verbs and tenses',
};

/// تبويب الاختبارات.
class TestsTab extends StatefulWidget {
  final AppUser me;
  const TestsTab({super.key, required this.me});
  @override
  State<TestsTab> createState() => _TestsTabState();
}

class _TestsTabState extends State<TestsTab> {
  int _lvl = 0;
  String _theme = 'عام';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(children: [
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('الاختبارات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text('10 أسئلة جديدة كل مرة: كلمات، قواعد، ترجمة، واستماع',
                  style: TextStyle(color: AppColors.muted)),
            ]),
          ),
          const Icon3D('brain', size: 64),
        ]),
        if (widget.me.quizzes > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('خلّصت ${widget.me.quizzes} اختبار لحد دلوقتي 👏',
                style: const TextStyle(color: AppColors.accent)),
          ),
        const SizedBox(height: 20),
        const Text('اختار المستوى', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (int i = 0; i < _levels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _lvl = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: i == _lvl ? AppColors.accent.withValues(alpha: 0.14) : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: i == _lvl ? AppColors.accent : AppColors.line, width: i == _lvl ? 2 : 1),
                ),
                child: Row(children: [
                  Icon3D(_levels[i].icon, size: 46),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_levels[i].ar,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(_levels[i].desc, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    ]),
                  ),
                  if (i == _lvl) const Icon(Icons.check_circle_rounded, color: AppColors.accent),
                ]),
              ),
            ),
          ),
        const SizedBox(height: 10),
        const Text('الموضوع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _themes.keys)
              ChoiceChip(
                label: Text(t),
                selected: _theme == t,
                onSelected: (_) => setState(() => _theme = t),
              ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(
                level: _levels[_lvl].key,
                levelAr: _levels[_lvl].ar,
                topic: _themes[_theme]!,
              ),
            ),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('ابدأ الاختبار'),
        ),
        const SizedBox(height: 10),
        const Text('كل إجابة صح = 5 نقط ✨',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 13)),
      ],
    );
  }
}

class QuizScreen extends StatefulWidget {
  final String level, levelAr, topic;
  const QuizScreen({super.key, required this.level, required this.levelAr, required this.topic});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQ>? _qs;
  String? _error;
  int _i = 0;
  int? _picked;
  int _correct = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Voice.I.useDefaultVoice();
    _load();
  }

  @override
  void dispose() {
    Voice.I.stopSpeaking();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _qs = null;
      _error = null;
      _i = 0;
      _picked = null;
      _correct = 0;
      _done = false;
    });
    try {
      final s = await Data.loadSettings();
      final qs = await Gemini(s.geminiKey, s.model).quiz(level: widget.level, topic: widget.topic);
      if (!mounted) return;
      setState(() => _qs = qs);
      _autoListen();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  void _autoListen() {
    final q = _qs![_i];
    if (q.type == 'listen' && q.text.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () => Voice.I.speakAt(q.text, 0.45));
    }
  }

  void _pick(int k) {
    if (_picked != null) return;
    setState(() {
      _picked = k;
      if (k == _qs![_i].answer) _correct++;
    });
  }

  void _next() {
    if (_i < _qs!.length - 1) {
      setState(() {
        _i++;
        _picked = null;
      });
      _autoListen();
    } else {
      setState(() => _done = true);
      Data.addXp(_correct * Xp.perQuizCorrect, quiz: true);
    }
  }

  String _typeAr(String t) => switch (t) {
        'vocab' => 'كلمات',
        'grammar' => 'قواعد',
        'translate' => 'ترجمة',
        'listen' => 'استماع',
        _ => 'سؤال',
      };

  String _typeIcon(String t) => switch (t) {
        'vocab' => 'books',
        'grammar' => 'pencil',
        'translate' => 'globe',
        'listen' => 'headphone',
        _ => 'thinking',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('اختبار · ${widget.levelAr}')),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon3D('sad', size: 72),
                  const SizedBox(height: 14),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  FilledButton(onPressed: _load, child: const Text('جرّب تاني')),
                ]),
              ),
            )
          : _qs == null
              ? const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon3D('brain', size: 80),
                    SizedBox(height: 16),
                    CircularProgressIndicator(),
                    SizedBox(height: 14),
                    Text('بنجهزلك أسئلة جديدة…'),
                  ]),
                )
              : _done
                  ? _result()
                  : _question(),
    );
  }

  Widget _question() {
    final q = _qs![_i];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
      children: [
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_i + 1) / _qs!.length,
                minHeight: 8,
                backgroundColor: AppColors.surface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${_i + 1}/${_qs!.length}', style: const TextStyle(color: AppColors.muted)),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Icon3D(_typeIcon(q.type), size: 40),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_typeAr(q.type), style: const TextStyle(color: AppColors.accent)),
          ),
        ]),
        const SizedBox(height: 14),
        Text(q.questionAr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.5)),
        const SizedBox(height: 12),
        if (q.type == 'listen')
          Center(
            child: FilledButton.tonalIcon(
              onPressed: () => Voice.I.speakAt(q.text, 0.45),
              icon: const Icon3D('speaker', size: 28),
              label: const Text('اسمع تاني'),
              style: FilledButton.styleFrom(minimumSize: const Size(180, 52)),
            ),
          )
        else if (q.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(q.text,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 18),
        for (int k = 0; k < q.options.length; k++) _option(q, k),
        if (_picked != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_picked == q.answer ? AppColors.mint : AppColors.danger).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Icon3D(_picked == q.answer ? 'check' : 'light_bulb', size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (_picked == q.answer ? 'صح! ' : 'الإجابة الصح: ${q.options[q.answer]}\n') + q.explainAr,
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ]),
          ),
          if (q.type == 'listen')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('الجملة كانت: ${q.text}',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _next,
            child: Text(_i < _qs!.length - 1 ? 'السؤال اللي بعده' : 'شوف النتيجة'),
          ),
        ],
      ],
    );
  }

  Widget _option(QuizQ q, int k) {
    final picked = _picked != null;
    final isAnswer = k == q.answer;
    final isPicked = k == _picked;
    Color border = AppColors.line;
    Color bg = AppColors.card;
    if (picked && isAnswer) {
      border = AppColors.mint;
      bg = AppColors.mint.withValues(alpha: 0.14);
    } else if (picked && isPicked) {
      border = AppColors.danger;
      bg = AppColors.danger.withValues(alpha: 0.14);
    }
    final isEnglish = RegExp(r'[A-Za-z]').hasMatch(q.options[k]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _pick(k),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: picked && (isAnswer || isPicked) ? 2 : 1),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surface,
              child: Text('${k + 1}', style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(q.options[k],
                  textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
                  textAlign: TextAlign.start,
                  style: const TextStyle(fontSize: 16)),
            ),
            if (picked && isAnswer) const Icon(Icons.check_circle_rounded, color: AppColors.mint),
            if (picked && isPicked && !isAnswer) const Icon(Icons.cancel_rounded, color: AppColors.danger),
          ]),
        ),
      ),
    );
  }

  Widget _result() {
    final total = _qs!.length;
    final pct = (_correct * 100 / total).round();
    final icon = pct >= 90 ? 'trophy' : pct >= 70 ? 'party' : pct >= 50 ? 'thumbs_up' : 'muscle';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        Center(child: Icon3D(icon, size: 120)),
        const SizedBox(height: 16),
        Text('$_correct من $total',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.accent)),
        const SizedBox(height: 8),
        Text(encouragementFor(pct),
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.7)),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('+${_correct * Xp.perQuizCorrect} نقطة ✨',
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 30),
        FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('اختبار جديد'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('رجوع')),
      ],
    );
  }
}
