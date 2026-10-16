import 'package:flutter/material.dart';

import '../config.dart';
import '../services/data.dart';
import '../services/gemini.dart';
import '../theme.dart';
import 'history_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الإدارة'),
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            tabs: [
              Tab(icon: Icon(Icons.group_rounded), text: 'المشتركين'),
              Tab(icon: Icon(Icons.key_rounded), text: 'الذكاء الاصطناعي'),
            ],
          ),
        ),
        body: const TabBarView(children: [_UsersTab(), _SettingsTab()]),
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _filter = 'pending';
  String _q = '';

  static const _labels = {
    'pending': 'منتظرين',
    'approved': 'مفعّلين',
    'blocked': 'موقوفين',
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: Data.watchUsers(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('مشكلة: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final all = snap.data!.where((u) => !u.isAdmin).toList();
        int count(String s) => all.where((u) => u.status == s).length;
        final list = all
            .where((u) => u.status == _filter)
            .where((u) =>
                _q.isEmpty ||
                u.name.toLowerCase().contains(_q) ||
                u.email.toLowerCase().contains(_q))
            .toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final e in _labels.entries)
                  ButtonSegment(value: e.key, label: Text('${e.value} (${count(e.key)})')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: TextField(
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'دوّر بالاسم أو الإيميل',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      _filter == 'pending' ? 'مفيش طلبات جديدة 👌' : 'مفيش حد هنا',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _UserCard(user: list[i]),
                  ),
          ),
        ]);
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  const _UserCard({required this.user});

  Future<void> _set(BuildContext context, String status) async {
    try {
      await Data.setStatus(user.uid, status);
      if (context.mounted) {
        toast(context, status == 'approved' ? 'تم تفعيل ${user.name} ✅' : 'تم إيقاف ${user.name}');
      }
    } catch (e) {
      if (context.mounted) toast(context, '$e', error: true);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('حذف المشترك؟'),
        content: Text('هيتمسح ملف ${user.name} من القائمة. لو حاول يدخل تاني هيرجع "منتظر موافقة".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('احذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await Data.deleteUserDoc(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final d = user.createdAt;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: AppColors.surface,
              child: Text(user.name.isEmpty ? '?' : user.name.characters.first,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(user.email,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ]),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'hist') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HistoryScreen(uid: user.uid, title: 'تقييمات ${user.name}')),
                  );
                } else if (v == 'del') {
                  _delete(context);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'hist', child: Text('تقييماته')),
                PopupMenuItem(value: 'del', child: Text('حذف')),
              ],
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            [
              if (d != null) 'سجّل ${d.day}/${d.month}/${d.year}',
              '${user.sessions} مكالمة',
              if (user.lastScore >= 0) 'آخر درجة ${user.lastScore}',
            ].join(' · '),
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Row(children: [
            if (user.status != 'approved')
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _set(context, 'approved'),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('تفعيل'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                ),
              ),
            if (user.status != 'approved' && user.status != 'blocked') const SizedBox(width: 10),
            if (user.status != 'blocked')
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _set(context, 'blocked'),
                  icon: const Icon(Icons.block_rounded, color: AppColors.danger),
                  label: Text(user.status == 'pending' ? 'رفض' : 'إيقاف'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _key = TextEditingController();
  final _model = TextEditingController();
  bool _loading = true, _busy = false, _hide = true;

  @override
  void initState() {
    super.initState();
    Data.loadSettings().then((s) {
      if (!mounted) return;
      setState(() {
        _key.text = s.geminiKey;
        _model.text = s.model;
        _loading = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _saveAndTest() async {
    setState(() => _busy = true);
    try {
      final key = _key.text.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '');
      final ai = Gemini(key, _model.text.trim().isEmpty ? kDefaultModel : _model.text.trim());
      await ai.test();
      await Data.saveSettings(key, ai.model);
      if (mounted) {
        setState(() {
          _key.text = key;
          _model.text = ai.model;
        });
        toast(context, 'المفتاح شغال واتحفظ ✅ (${ai.model})');
      }
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('مفتاح Gemini',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          'هات مفتاح مجاني من aistudio.google.com/apikey والصقه هنا. '
          'المفتاح ده هو اللي بيشغّل كلام الشخصيات والتقييم لكل المشتركين.',
          style: TextStyle(color: AppColors.muted, height: 1.6),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _key,
          obscureText: _hide,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: 'API Key',
            prefixIcon: const Icon(Icons.key_rounded),
            suffixIcon: IconButton(
              icon: Icon(_hide ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              onPressed: () => setState(() => _hide = !_hide),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _model,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'الموديل',
            helperText: 'سيبه زي ما هو، غيّره بس لو جوجل وقفت الموديل ده',
            prefixIcon: Icon(Icons.memory_rounded),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: _busy ? null : _saveAndTest,
          icon: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_rounded),
          label: const Text('اختبار وحفظ'),
        ),
      ],
    );
  }
}
