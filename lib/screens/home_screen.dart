import 'package:flutter/material.dart';

import '../models.dart';
import '../services/data.dart';
import '../services/personas.dart';
import '../theme.dart';
import '../widgets/persona_photo.dart';
import '../config.dart';
import '../phrases_data.dart';
import '../progress.dart';
import '../services/local_store.dart';
import '../widgets/icon3d.dart';
import 'admin_screen.dart';
import 'phrases_screen.dart';
import 'pronunciation_screen.dart';
import 'quiz_screen.dart';
import 'history_screen.dart';
import 'persona_editor.dart';
import 'topic_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser me;
  const HomeScreen({super.key, required this.me});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _welcome());
  }

  Future<void> _welcome() async {
    if (await LocalStore.welcomed()) return;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon3D('party', size: 96),
            const SizedBox(height: 12),
            Text('أهلاً بيك يا ${widget.me.name.split(' ').first} في $kAppName!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text(
              'هنا هتتكلم إنجليزي بجد مع شخصيات بتردّ عليك بصوتها، وتتعلم من غير خوف من الغلط.\n\n'
              '🎤 اتكلم في أي موضوع\n🧠 اختبر نفسك\n🗣️ درّب نطقك\n🏆 اجمع نقاط واطلع مستويات\n\n'
              'عشر دقايق كل يوم كفاية تغيّر مستواك. يلا بينا!',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.7, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('يلا نبدأ 🚀'),
            ),
          ]),
        ),
      ),
    );
    await LocalStore.setWelcomed();
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    final pages = [
      _HomeTab(me: me),
      TestsTab(me: me),
      const PhrasesTab(),
      const HistoryScreen(embedded: true),
    ];
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            const AppLogo(size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Text(kAppName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        actions: [
          if (me.isAdmin)
            IconButton(
              tooltip: 'لوحة الإدارة',
              icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.accent),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'out') Data.signOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'out', child: Text('تسجيل خروج')),
            ],
          ),
        ],
      ),
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        destinations: const [
          NavigationDestination(icon: Icon3D('house', size: 28), label: 'الرئيسية'),
          NavigationDestination(icon: Icon3D('brain', size: 28), label: 'اختبارات'),
          NavigationDestination(icon: Icon3D('books', size: 28), label: 'العبارات'),
          NavigationDestination(icon: Icon3D('chart', size: 28), label: 'تقدّمي'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final AppUser me;
  const _HomeTab({required this.me});
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<Persona> _personas = [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload({String? select}) async {
    final all = await PersonaStore.loadAll();
    if (!mounted) return;
    setState(() {
      _personas = all;
      _selectedId = select ?? _selectedId ?? (all.isNotEmpty ? all.first.id : null);
      if (!_personas.any((p) => p.id == _selectedId)) {
        _selectedId = all.isNotEmpty ? all.first.id : null;
      }
    });
  }

  Persona? get _selected {
    for (final p in _personas) {
      if (p.id == _selectedId) return p;
    }
    return null;
  }

  Future<void> _openEditor([Persona? p]) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => PersonaEditor(persona: p)),
    );
    await _reload(select: result);
  }

  void _personaMenu(Persona p) {
    if (p.isBuiltIn) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('تعديل الشخصية'),
              onTap: () {
                Navigator.pop(context);
                _openEditor(p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: const Text('حذف الشخصية', style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(context);
                await PersonaStore.delete(p);
                await _reload();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _practicePronunciation() {
    final all = [for (final c in kPhraseCategories) ...c.phrases]..shuffle();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PronunciationScreen(phrases: all.take(8).toList(), title: 'تمرين نطق سريع'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    final me = widget.me;
    final info = rankFor(me.xp);
    final streak = me.liveStreak;
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                sliver: SliverList.list(children: [
                  // رسالة الترحيب والتشجيع
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB547), Color(0xFFFF7E5F)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('أهلاً يا ${me.name.split(' ').first} 👋',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2A1A00))),
                          const SizedBox(height: 6),
                          Text(motivationOfDay(),
                              style: const TextStyle(color: Color(0xFF3D2600), height: 1.55)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      const Icon3D('star_struck', size: 70),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // المستوى والنقاط
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(children: [
                      Row(children: [
                        Icon3D(info.rank.icon, size: 58),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('المستوى ${info.index + 1}: ${info.rank.name}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                              info.next == null
                                  ? 'وصلت لأعلى مستوى! انت أسطورة 👑'
                                  : 'فاضلك ${info.toNext} نقطة وتبقى "${info.next!.name}"',
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                          ]),
                        ),
                        Column(children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon3D('fire', size: 30),
                            Text(' $streak',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          ]),
                          const Text('يوم ورا بعض',
                              style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        ]),
                      ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: info.progress,
                          minHeight: 10,
                          backgroundColor: AppColors.surface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text('${me.xp} نقطة',
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (info.next != null)
                          Text('${info.next!.minXp}', style: const TextStyle(color: AppColors.muted)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _QuickAction(
                        icon: 'microphone',
                        title: 'تمرين نطق',
                        subtitle: '8 جمل بسرعة',
                        onTap: _practicePronunciation,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: 'bullseye',
                        title: 'اختبار سريع',
                        subtitle: '10 أسئلة',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QuizScreen(
                              level: 'Beginner to Intermediate (A2-B1)',
                              levelAr: 'سريع',
                              topic: 'general everyday English',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  const Row(children: [
                    Icon3D('video', size: 34),
                    SizedBox(width: 8),
                    Text('مين هيكلمك النهارده؟',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('اختار شخصية جاهزة، أو اعمل شخصية من أي صورة على موبايلك',
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 12),
                ]),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i == _personas.length) return _AddCard(onTap: () => _openEditor());
                      final p = _personas[i];
                      return _PersonaCard(
                        persona: p,
                        selected: p.id == _selectedId,
                        onTap: () => setState(() => _selectedId = p.id),
                        onLongPress: () => _personaMenu(p),
                      );
                    },
                    childCount: _personas.length + 1,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: FilledButton.icon(
            onPressed: sel == null
                ? null
                : () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => TopicScreen(persona: sel))),
            icon: const Icon(Icons.videocam_rounded),
            label: Text(sel == null ? 'اختار شخصية' : 'ابدأ الكلام مع ${sel.name}'),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String icon, title, subtitle;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(children: [
            Icon3D(icon, size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      );
}

class _PersonaCard extends StatelessWidget {
  final Persona persona;
  final bool selected;
  final VoidCallback onTap, onLongPress;
  const _PersonaCard(
      {required this.persona, required this.selected, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.line,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 18)]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PersonaPhoto(persona: persona),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDD0B0820)],
                    stops: [0.55, 1],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(persona.name,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(
                      persona.isBuiltIn
                          ? (persona.accent == 'en-GB' ? '🇬🇧 لكنة بريطاني' : '🇺🇸 لكنة أمريكي')
                          : '📷 من صورك — اضغط مطولاً للتعديل',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.check_rounded, size: 18, color: Color(0xFF2A1A00)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCard({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.card,
              child: Icon(Icons.add_a_photo_rounded, color: AppColors.accent, size: 28),
            ),
            SizedBox(height: 12),
            Text('شخصية من صورة', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('اختار صورة من الموبايل', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
