import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/data.dart';
import '../services/gemini.dart';
import '../theme.dart';
import '../widgets/persona_photo.dart';
import 'topic_screen.dart';

class EvaluationScreen extends StatefulWidget {
  final Gemini ai;
  final Persona persona;
  final Topic topic;
  final String level;
  final List<ChatMsg> messages;
  final int minutes;
  const EvaluationScreen({
    super.key,
    required this.ai,
    required this.persona,
    required this.topic,
    required this.level,
    required this.messages,
    required this.minutes,
  });

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  Evaluation? _eval;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _error = null;
      _eval = null;
    });
    try {
      final e = await widget.ai.evaluate(
        topic: widget.topic.en,
        level: widget.level,
        messages: widget.messages,
      );
      if (!mounted) return;
      setState(() => _eval = e);
      try {
        await Data.saveSession(
          personaName: widget.persona.name,
          topic: widget.topic.ar,
          level: widget.level,
          userMessages: widget.messages.where((m) => m.fromUser).length,
          minutes: widget.minutes,
          eval: e,
        );
      } catch (_) {}
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقييم لغتك')),
      body: _eval != null
          ? EvaluationView(
              eval: _eval!,
              header: Row(children: [
                ClipOval(child: PersonaPhoto(persona: widget.persona, width: 44, height: 44)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'مكالمتك مع ${widget.persona.name} · ${widget.topic.ar} · ${widget.minutes} دقيقة',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ]),
              footer: Column(children: [
                FilledButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => TopicScreen(persona: widget.persona)),
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('مكالمة جديدة'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('الرئيسية'),
                ),
              ]),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: _error == null
                    ? const Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 18),
                        Text('بنراجع كلامك ونطلعلك التقييم…', style: TextStyle(fontSize: 16)),
                      ])
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 18),
                        FilledButton(onPressed: _run, child: const Text('جرّب تاني')),
                      ]),
              ),
            ),
    );
  }
}

/// عرض التقييم (بيستخدم في آخر المكالمة وفي السجل).
class EvaluationView extends StatelessWidget {
  final Evaluation eval;
  final Widget? header, footer;
  const EvaluationView({super.key, required this.eval, this.header, this.footer});

  Color _scoreColor(int s) => s >= 80
      ? AppColors.mint
      : s >= 60
          ? AppColors.accent
          : AppColors.danger;

  @override
  Widget build(BuildContext context) {
    final e = eval;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
      children: [
        if (header != null) ...[header!, const SizedBox(height: 18)],
        Center(
          child: SizedBox(
            width: 170,
            height: 170,
            child: CustomPaint(
              painter: _Ring(e.overall / 100, _scoreColor(e.overall)),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${e.overall}',
                      style: TextStyle(
                          fontSize: 50, fontWeight: FontWeight.w900, color: _scoreColor(e.overall))),
                  const Text('من 100', style: TextStyle(color: AppColors.muted)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('مستواك التقريبي: ${e.level}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent)),
          ),
        ),
        if (e.summaryAr.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(e.summaryAr,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 15.5, height: 1.7)),
        ],
        const SizedBox(height: 20),
        _Card(children: [
          _Bar('القواعد (Grammar)', e.grammar, _scoreColor(e.grammar)),
          _Bar('الكلمات (Vocabulary)', e.vocabulary, _scoreColor(e.vocabulary)),
          _Bar('الطلاقة (Fluency)', e.fluency, _scoreColor(e.fluency)),
          _Bar('الفهم والرد (Comprehension)', e.comprehension, _scoreColor(e.comprehension)),
        ]),
        if (e.strengths.isNotEmpty)
          _Section('👏 نقاط قوتك', [
            for (final s in e.strengths) _Bullet(s),
          ]),
        if (e.mistakes.isNotEmpty)
          _Section('✏️ أخطاء نصلّحها', [
            for (final m in e.mistakes)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('✗ ${m.wrong}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                          color: AppColors.danger, decoration: TextDecoration.lineThrough)),
                  const SizedBox(height: 4),
                  Text('✓ ${m.right}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: AppColors.mint, fontWeight: FontWeight.w700)),
                  if (m.why.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(m.why, style: const TextStyle(color: AppColors.muted, height: 1.5)),
                  ],
                ]),
              ),
          ]),
        if (e.tips.isNotEmpty)
          _Section('🎯 نصايح للمرة الجاية', [
            for (final s in e.tips) _Bullet(s),
          ]),
        if (e.newWords.isNotEmpty)
          _Section('📚 كلمات جديدة تتعلمها', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final w in e.newWords)
                  Chip(
                    label: Text(w),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.line),
                  ),
              ],
            ),
          ]),
        if (footer != null) ...[const SizedBox(height: 24), footer!],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(children: children),
        ),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...children,
        ]),
      );
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: CircleAvatar(radius: 3, backgroundColor: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.6))),
        ]),
      );
}

class _Bar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Bar(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(label)),
            Text('$value', style: TextStyle(fontWeight: FontWeight.w800, color: color)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 9,
              color: color,
              backgroundColor: AppColors.surface,
            ),
          ),
        ]),
      );
}

class _Ring extends CustomPainter {
  final double v;
  final Color color;
  _Ring(this.v, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawArc(
        r,
        0,
        2 * pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = AppColors.surface);
    canvas.drawArc(
        r,
        -pi / 2,
        2 * pi * v.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant _Ring old) => old.v != v || old.color != color;
}
