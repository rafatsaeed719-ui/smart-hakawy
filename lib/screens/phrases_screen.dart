import 'package:flutter/material.dart';

import '../phrases_data.dart';
import '../services/local_store.dart';
import '../services/voice.dart';
import '../theme.dart';
import '../widgets/icon3d.dart';
import 'pronunciation_screen.dart';

/// ركن العبارات (تبويب في الرئيسية).
class PhrasesTab extends StatefulWidget {
  const PhrasesTab({super.key});
  @override
  State<PhrasesTab> createState() => _PhrasesTabState();
}

class _PhrasesTabState extends State<PhrasesTab> {
  int _saved = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final s = await LocalStore.savedPhrases();
    if (mounted) setState(() => _saved = s.length);
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('ركن العبارات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('جمل بيستخدمها الأجانب كل يوم. اسمعها، قولها، واحفظ اللي يعجبك.',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _open(const PhraseListScreen(savedOnly: true)),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF3B2A86), Color(0xFF26195E)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(children: [
              const Icon3D('bookmark', size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('جملي المحفوظة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    _saved == 0
                        ? 'احفظ أي جملة من هنا أو من المكالمة (اضغط عليها مطولاً)'
                        : '$_saved جملة محفوظة — راجعها ودرّب نطقها',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ]),
              ),
              const Icon(Icons.chevron_left_rounded),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: kPhraseCategories.length,
          itemBuilder: (_, i) {
            final c = kPhraseCategories[i];
            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _open(PhraseListScreen(category: c)),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.line),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon3D(c.icon, size: 52),
                    const SizedBox(height: 10),
                    Text(c.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${c.phrases.length} جمل',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class PhraseListScreen extends StatefulWidget {
  final PhraseCategory? category;
  final bool savedOnly;
  const PhraseListScreen({super.key, this.category, this.savedOnly = false});
  @override
  State<PhraseListScreen> createState() => _PhraseListScreenState();
}

class _PhraseListScreenState extends State<PhraseListScreen> {
  List<Phrase> _list = [];
  Set<String> _saved = {};

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
    final saved = await LocalStore.savedPhrases();
    if (!mounted) return;
    setState(() {
      _saved = saved.map((e) => e.en.trim().toLowerCase()).toSet();
      _list = widget.savedOnly ? saved : widget.category!.phrases;
    });
  }

  Future<void> _toggle(Phrase p) async {
    final now = await LocalStore.toggle(p);
    if (!mounted) return;
    toast(context, now ? 'اتحفظت في جملك ⭐' : 'اتشالت من المحفوظة');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.savedOnly ? 'جملي المحفوظة' : widget.category!.title;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: _list.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PronunciationScreen(phrases: _list, title: 'نطق: $title')),
              ),
              icon: const Icon(Icons.mic_rounded),
              label: const Text('درّب نطقها كلها'),
            ),
      body: _list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon3D('bookmark', size: 80),
                  SizedBox(height: 16),
                  Text('لسه مفيش جمل محفوظة.\nاحفظ من الأقسام بالنجمة ⭐ أو اضغط مطولاً على أي جملة في المكالمة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.7)),
                ]),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 100),
              itemCount: _list.length,
              itemBuilder: (_, i) {
                final p = _list[i];
                final saved = _saved.contains(p.en.trim().toLowerCase());
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(p.en,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      if (p.ar.isNotEmpty)
                        Text(p.ar, style: const TextStyle(color: AppColors.muted)),
                      Row(children: [
                        IconButton(
                          tooltip: 'اسمع',
                          icon: const Icon3D('speaker', size: 28),
                          onPressed: () => Voice.I.speakAt(p.en, 0.45),
                        ),
                        IconButton(
                          tooltip: 'اسمع ببطء',
                          icon: const Icon3D('turtle', size: 28),
                          onPressed: () => Voice.I.speakAt(p.en, 0.25),
                        ),
                        IconButton(
                          tooltip: 'درّب النطق',
                          icon: const Icon3D('microphone', size: 28),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PronunciationScreen(phrases: _list, start: i)),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: saved ? 'شيلها من المحفوظة' : 'احفظها',
                          icon: Icon(saved ? Icons.star_rounded : Icons.star_border_rounded,
                              color: AppColors.accent, size: 30),
                          onPressed: () => _toggle(p),
                        ),
                      ]),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
