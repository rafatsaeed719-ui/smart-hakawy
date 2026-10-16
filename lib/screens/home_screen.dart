import 'package:flutter/material.dart';

import '../models.dart';
import '../services/data.dart';
import '../services/personas.dart';
import '../theme.dart';
import '../widgets/persona_photo.dart';
import 'admin_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            const AppLogo(size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Text('أهلاً ${widget.me.name.split(' ').first} 👋',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        actions: [
          if (widget.me.isAdmin)
            IconButton(
              tooltip: 'لوحة الإدارة',
              icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.accent),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
            ),
          IconButton(
            tooltip: 'تقييماتي',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                    sliver: SliverToBoxAdapter(
                      child: Text('مين هيكلمك النهارده؟',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                    sliver: SliverToBoxAdapter(
                      child: Text('اختار شخصية جاهزة، أو اعمل شخصية من أي صورة على موبايلك',
                          style: TextStyle(color: AppColors.muted)),
                    ),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
        ),
      ),
    );
  }
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
