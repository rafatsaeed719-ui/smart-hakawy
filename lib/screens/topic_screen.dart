import 'package:flutter/material.dart';

import '../models.dart';
import '../services/local_store.dart';
import '../services/voice.dart';
import '../widgets/icon3d.dart';
import '../theme.dart';
import '../widgets/persona_photo.dart';
import 'chat_screen.dart';

const kLevels = {
  'Beginner': 'مبتدئ',
  'Intermediate': 'متوسط',
  'Advanced': 'متقدم',
};

class TopicScreen extends StatefulWidget {
  final Persona persona;
  const TopicScreen({super.key, required this.persona});
  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  int _topic = 0;
  final _custom = TextEditingController();
  String _level = 'Beginner';
  late double _rate = Voice.I.rate;
  bool _showAr = true;

  void _start() {
    final custom = _custom.text.trim();
    final Topic topic = custom.isNotEmpty ? Topic('✍️', custom, custom) : kTopics[_topic];
    Voice.I.rate = _rate;
    LocalStore.setSpeechRate(_rate);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          persona: widget.persona,
          topic: topic,
          level: _level,
          showArabic: _showAr,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('هتتكلموا في إيه؟')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          Row(children: [
            ClipOval(child: PersonaPhoto(persona: widget.persona, width: 56, height: 56)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${widget.persona.name} مستنيك… اختار الموضوع',
                  style: const TextStyle(fontSize: 16, color: AppColors.muted)),
            ),
          ]),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: kTopics.length,
            itemBuilder: (_, i) {
              final t = kTopics[i];
              final sel = i == _topic && _custom.text.trim().isEmpty;
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() {
                  _topic = i;
                  _custom.clear();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.accent.withValues(alpha: 0.16) : AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: sel ? AppColors.accent : AppColors.line, width: sel ? 2 : 1),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon3D(t.icon, size: 40),
                      const SizedBox(height: 6),
                      Text(t.ar,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _custom,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'أو اكتب موضوعك انت',
              hintText: 'مثلاً: رحلتي لإسكندرية، شغلي، كتاب بحبه…',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 22),
          const Text('مستواك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: [
              for (final e in kLevels.entries) ButtonSegment(value: e.key, label: Text(e.value)),
            ],
            selected: {_level},
            onSelectionChanged: (s) => setState(() => _level = s.first),
          ),
          const SizedBox(height: 20),
          const Text('سرعة الكلام', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Row(children: [
            const Text('🐢'),
            Expanded(
              child: Slider(
                value: _rate,
                min: 0.3,
                max: 0.75,
                divisions: 9,
                onChanged: (v) => setState(() => _rate = v),
              ),
            ),
            const Text('🐇'),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _showAr,
            onChanged: (v) => setState(() => _showAr = v),
            title: const Text('اظهر الترجمة العربي'),
            subtitle: const Text('تقدر تخفيها وتظهرها في أي وقت أثناء الكلام',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.videocam_rounded),
            label: const Text('يلا نبدأ المكالمة'),
          ),
        ],
      ),
    );
  }
}
