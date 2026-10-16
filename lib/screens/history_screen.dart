import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/data.dart';
import '../theme.dart';
import 'evaluation_screen.dart';

class HistoryScreen extends StatelessWidget {
  final String? uid;
  final String? title;
  final bool embedded;
  const HistoryScreen({super.key, this.uid, this.title, this.embedded = false});

  static String _date(DateTime? d) {
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(title ?? 'تقييماتي')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: Data.watchSessions(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('حصلت مشكلة: ${snap.error}'));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text('لسه مفيش تقييمات.\nاعمل أول مكالمة واطلب التقييم في الآخر ⭐',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.7)),
              ),
            );
          }
          final scores = docs
              .map((d) => (d.data()['eval']?['overall'] as num?)?.toInt() ?? 0)
              .toList()
              .reversed
              .toList();
          final avg = scores.reduce((a, b) => a + b) / scores.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      _Stat('${docs.length}', 'مكالمة'),
                      _Stat(avg.toStringAsFixed(0), 'متوسط الدرجة'),
                      _Stat('${docs.first.data()['eval']?['level'] ?? '-'}', 'آخر مستوى'),
                    ]),
                    if (scores.length > 1) ...[
                      const SizedBox(height: 16),
                      SizedBox(height: 70, child: CustomPaint(painter: _Spark(scores))),
                      const SizedBox(height: 6),
                      const Text('تطور درجاتك', textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              for (final d in docs) _tile(context, d),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data();
    final ev = Evaluation.fromJson(Map<String, dynamic>.from((j['eval'] ?? {}) as Map));
    final ts = j['createdAt'];
    final date = ts is Timestamp ? ts.toDate() : null;
    final color = ev.overall >= 80
        ? AppColors.mint
        : ev.overall >= 60
            ? AppColors.accent
            : AppColors.danger;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.18),
          child: Text('${ev.overall}', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ),
        title: Text('${j['topic'] ?? ''} · ${ev.level}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('مع ${j['persona'] ?? ''} · ${_date(date)} · ${j['minutes'] ?? 1} د',
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text('${j['topic'] ?? 'التقييم'}')),
              body: EvaluationView(eval: ev),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.accent)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ]),
      );
}

class _Spark extends CustomPainter {
  final List<int> v;
  _Spark(this.v);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (int i = 0; i < v.length; i++) {
      final x = size.width * i / (v.length - 1);
      final y = size.height * (1 - v[i] / 100);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.mint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round);
    for (int i = 0; i < v.length; i++) {
      canvas.drawCircle(Offset(size.width * i / (v.length - 1), size.height * (1 - v[i] / 100)), 3.5,
          Paint()..color = AppColors.mint);
    }
  }

  @override
  bool shouldRepaint(covariant _Spark old) => old.v != v;
}
