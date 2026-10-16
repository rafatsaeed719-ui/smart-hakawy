import 'package:flutter/material.dart';

import '../models.dart';
import '../services/data.dart';
import '../phrases_data.dart';
import '../services/gemini.dart';
import '../services/local_store.dart';
import '../widgets/icon3d.dart';
import 'pronunciation_screen.dart';
import '../services/voice.dart';
import '../theme.dart';
import '../widgets/talking_avatar.dart';
import 'evaluation_screen.dart';
import 'topic_screen.dart';

class ChatScreen extends StatefulWidget {
  final Persona persona;
  final Topic topic;
  final String level;
  final bool showArabic;
  const ChatScreen({
    super.key,
    required this.persona,
    required this.topic,
    required this.level,
    required this.showArabic,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

enum _Phase { connecting, thinking, speaking, listening, idle }

class _ChatScreenState extends State<ChatScreen> {
  final _driver = AvatarDriver();
  final _msgs = <ChatMsg>[];
  final _history = <Map<String, dynamic>>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Gemini? _ai;
  _Phase _phase = _Phase.connecting;
  late bool _showAr = widget.showArabic;
  String _partial = '';
  bool _sent = false;
  String? _failedText;
  bool _typing = false;
  final _started = DateTime.now();

  @override
  void initState() {
    super.initState();
    Voice.I.speaking.addListener(_onSpeaking);
    Voice.I.listening.addListener(_onListening);
    Voice.I.onWord = _driver.word;
    _boot();
  }

  @override
  void dispose() {
    Voice.I.speaking.removeListener(_onSpeaking);
    Voice.I.listening.removeListener(_onListening);
    Voice.I.onWord = null;
    Voice.I.cancelAll();
    _driver.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onSpeaking() {
    final s = Voice.I.speaking.value;
    _driver.setTalking(s);
    if (!mounted) return;
    if (s) {
      setState(() => _phase = _Phase.speaking);
    } else if (_phase == _Phase.speaking) {
      setState(() => _phase = _Phase.idle);
    }
  }

  void _onListening() {
    if (!mounted) return;
    if (Voice.I.listening.value) {
      setState(() => _phase = _Phase.listening);
    } else if (_phase == _Phase.listening) {
      // اتوقف السمع — لو فيه كلام لسه متبعتش نبعته
      if (!_sent && _partial.trim().isNotEmpty) {
        _sendUser(_partial);
      } else {
        setState(() => _phase = _Phase.idle);
      }
    }
  }

  String get _topicEn => widget.topic.en;

  Future<void> _boot() async {
    try {
      final s = await Data.loadSettings();
      _ai = Gemini(s.geminiKey, s.model);
      await Voice.I.configure(widget.persona);
      _history.add({
        'role': 'user',
        'parts': [
          {
            'text': '[The video call just started. Say hi, introduce yourself in one short sentence, '
                'and ask your first simple question about the topic: $_topicEn]'
          }
        ]
      });
      await _aiTurn();
    } catch (e) {
      if (mounted) {
        setState(() => _phase = _Phase.idle);
        toast(context, '$e', error: true);
      }
    }
  }

  Future<void> _aiTurn() async {
    final ai = _ai;
    if (ai == null) return;
    setState(() => _phase = _Phase.thinking);
    try {
      final j = await ai.chat(
        persona: widget.persona,
        topic: _topicEn,
        level: widget.level,
        history: _history,
      );
      final reply = '${j['reply'] ?? ''}'.trim();
      if (reply.isEmpty) throw GeminiException('الرد جه فاضي، جرّب تاني.');
      _history.add({
        'role': 'model',
        'parts': [
          {'text': reply}
        ]
      });
      // نحدّث رسالة المستخدم الأخيرة بالترجمة والتصحيح
      final lastUser = _msgs.lastWhere((m) => m.fromUser, orElse: () => ChatMsg(fromUser: false, text: ''));
      if (lastUser.fromUser) {
        lastUser.ar = '${j['user_ar'] ?? ''}'.trim();
        lastUser.correction = '${j['correction'] ?? ''}'.trim();
        lastUser.correctionAr = '${j['correction_ar'] ?? ''}'.trim();
      }
      _failedText = null;
      setState(() {
        _msgs.add(ChatMsg(fromUser: false, text: reply, ar: '${j['reply_ar'] ?? ''}'.trim()));
        _phase = _Phase.speaking;
      });
      _scrollDown();
      await Voice.I.speak(reply);
    } catch (e) {
      // نشيل آخر رسالة مستخدم من التاريخ عشان نقدر نعيد المحاولة
      if (_history.isNotEmpty && _history.last['role'] == 'user') {
        final last = _history.removeLast();
        _failedText = '${(last['parts'] as List).first['text']}';
      }
      if (mounted) {
        setState(() => _phase = _Phase.idle);
        toast(context, '$e', error: true);
      }
    } finally {
      if (mounted && _phase == _Phase.thinking) setState(() => _phase = _Phase.idle);
    }
  }

  Future<void> _retry() async {
    final t = _failedText;
    if (t == null) return;
    _history.add({
      'role': 'user',
      'parts': [
        {'text': t}
      ]
    });
    await _aiTurn();
  }

  Future<void> _sendUser(String text) async {
    final t = text.trim();
    _sent = true;
    _partial = '';
    if (t.isEmpty || _phase == _Phase.thinking) return;
    await Voice.I.stopSpeaking();
    setState(() => _msgs.add(ChatMsg(fromUser: true, text: t)));
    _history.add({
      'role': 'user',
      'parts': [
        {'text': t}
      ]
    });
    _scrollDown();
    await _aiTurn();
  }

  Future<void> _mic() async {
    if (_phase == _Phase.listening) {
      await Voice.I.stopListening();
      return;
    }
    if (_phase == _Phase.thinking || _phase == _Phase.connecting) return;
    _sent = false;
    _partial = '';
    final ok = await Voice.I.listen(
      locale: widget.persona.accent == 'en-GB' ? 'en_GB' : 'en_US',
      onText: (text, isFinal) {
        if (!mounted) return;
        setState(() => _partial = text);
        if (isFinal && !_sent) _sendUser(text);
      },
    );
    if (!ok && mounted) {
      toast(context, 'لازم تسمح للبرنامج يستخدم المايك، ويكون عندك "Google" للتعرف على الصوت.',
          error: true);
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _finish() async {
    final userCount = _msgs.where((m) => m.fromUser).length;
    if (userCount < 2) {
      toast(context, 'اتكلم شوية كمان (رسالتين على الأقل) عشان نقدر نقيّمك', error: true);
      return;
    }
    await Voice.I.cancelAll();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationScreen(
          ai: _ai!,
          persona: widget.persona,
          topic: widget.topic,
          level: widget.level,
          messages: List.of(_msgs),
          minutes: DateTime.now().difference(_started).inMinutes.clamp(1, 600),
        ),
      ),
    );
  }

  Future<void> _savePhrase(Phrase p) async {
    final ok = await LocalStore.save(p);
    if (mounted) toast(context, ok ? 'اتحفظت في جملك ⭐' : 'الجملة دي محفوظة قبل كده');
  }

  void _msgActions(ChatMsg m) {
    final target = m.fromUser && m.correction.isNotEmpty ? m.correction : m.text;
    final ar = m.fromUser && m.correction.isNotEmpty ? m.correctionAr : m.ar;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(target,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon3D('bookmark', size: 30),
            title: const Text('احفظ الجملة في ركن العبارات'),
            onTap: () {
              Navigator.pop(context);
              _savePhrase(Phrase(target, ar));
            },
          ),
          ListTile(
            leading: const Icon3D('turtle', size: 30),
            title: const Text('اسمعها ببطء'),
            onTap: () {
              Navigator.pop(context);
              Voice.I.speakAt(target, 0.3);
            },
          ),
          ListTile(
            leading: const Icon3D('microphone', size: 30),
            title: const Text('درّب نطقها'),
            onTap: () async {
              Navigator.pop(context);
              await Voice.I.cancelAll();
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PronunciationScreen(phrases: [Phrase(target, ar)])),
              );
              await Voice.I.configure(widget.persona);
            },
          ),
        ]),
      ),
    );
  }

  void _cycleSpeed() {
    const speeds = [0.4, 0.5, 0.6, 0.7];
    final i = speeds.indexWhere((v) => v >= Voice.I.rate - 0.01);
    final next = speeds[(i + 1) % speeds.length];
    setState(() => Voice.I.rate = next);
    LocalStore.setSpeechRate(next);
    toast(context, 'سرعة الكلام: ${_speedLabel(next)}');
  }

  String _speedLabel(double r) => r <= 0.41
      ? 'بطيء 🐢'
      : r <= 0.51
          ? 'عادي'
          : r <= 0.61
              ? 'سريع'
              : 'سريع جدًا 🐇';

  Future<bool> _confirmLeave() async {
    final r = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('تنهي المكالمة؟'),
        content: const Text('تقدر تاخد تقييم للغتك قبل ما تخرج.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'stay'), child: const Text('كمّل')),
          TextButton(onPressed: () => Navigator.pop(context, 'leave'), child: const Text('خروج بدون تقييم')),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'eval'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('قيّمني'),
          ),
        ],
      ),
    );
    if (r == 'eval') {
      await _finish();
      return false;
    }
    return r == 'leave';
  }

  String get _statusText {
    switch (_phase) {
      case _Phase.connecting:
        return 'بيتصل…';
      case _Phase.thinking:
        return 'بيفكّر…';
      case _Phase.speaking:
        return 'بيتكلم';
      case _Phase.listening:
        return 'بيسمعك… اتكلم بالإنجليزي';
      case _Phase.idle:
        return 'دورك — دوس على المايك واتكلم';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastAi = _msgs.lastWhere((m) => !m.fromUser, orElse: () => ChatMsg(fromUser: false, text: ''));
    final listening = _phase == _Phase.listening;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (leave && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // ---------------- الفيديو ----------------
              Expanded(
                flex: 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: listening ? AppColors.mint : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: ColoredBox(
                          color: AppColors.surface,
                          child: TalkingAvatar(persona: widget.persona, driver: _driver),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          _Pill(
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: listening ? AppColors.mint : AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(widget.persona.name,
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                            ]),
                          ),
                          const Spacer(),
                          _Pill(
                            onTap: () async {
                              final leave = await _confirmLeave();
                              if (leave && context.mounted) Navigator.pop(context);
                            },
                            color: AppColors.danger,
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.call_end_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('إنهاء', style: TextStyle(fontWeight: FontWeight.w800)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    // ترجمة على الفيديو زي السبتايتل
                    if (lastAi.text.isNotEmpty && _phase == _Phase.speaking)
                      Positioned(
                        left: 22,
                        right: 22,
                        bottom: 16,
                        child: _Subtitle(msg: lastAi, showAr: _showAr),
                      ),
                    if (_phase == _Phase.thinking || _phase == _Phase.connecting)
                      const Positioned(
                        bottom: 22,
                        left: 0,
                        right: 0,
                        child: Center(child: _Pill(child: _Dots())),
                      ),
                  ],
                ),
              ),
              // ---------------- الكلام ----------------
              Expanded(
                flex: 9,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.topic.emoji} ${widget.topic.ar} · ${kLevels[widget.level]}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.muted, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              tooltip: 'سرعة الكلام',
                              onPressed: _cycleSpeed,
                              icon: Icon3D(Voice.I.rate < 0.5 ? 'turtle' : 'rabbit', size: 26),
                            ),
                            TextButton.icon(
                              onPressed: () => setState(() => _showAr = !_showAr),
                              icon: Icon(_showAr ? Icons.translate_rounded : Icons.g_translate_outlined,
                                  size: 18),
                              label: Text(_showAr ? 'إخفاء العربي' : 'إظهار العربي'),
                            ),
                            TextButton(
                              onPressed: _finish,
                              child: const Text('قيّمني ⭐',
                                  style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          itemCount: _msgs.length + (listening && _partial.isNotEmpty ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _msgs.length) {
                              return _Bubble(
                                msg: ChatMsg(fromUser: true, text: _partial),
                                showAr: false,
                                live: true,
                              );
                            }
                            final m = _msgs[i];
                            return GestureDetector(
                              onLongPress: () => _msgActions(m),
                              child: _Bubble(
                                msg: m,
                                showAr: _showAr,
                                onReplay: m.fromUser ? null : () => Voice.I.speak(m.text),
                                onSaveCorrection: m.correction.isEmpty
                                    ? null
                                    : () => _savePhrase(Phrase(m.correction, m.correctionAr)),
                                onHearCorrection: m.correction.isEmpty
                                    ? null
                                    : () => Voice.I.speakAt(m.correction, 0.4),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_failedText != null && _phase == _Phase.idle)
                        TextButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      _bottomBar(listening),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(bool listening) {
    final disabled = _phase == _Phase.thinking || _phase == _Phase.connecting;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.send,
              onChanged: (v) => setState(() => _typing = v.trim().isNotEmpty),
              onSubmitted: (v) {
                _input.clear();
                setState(() => _typing = false);
                _sendUser(v);
              },
              decoration: const InputDecoration(
                hintText: 'Type in English…',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (_typing)
            IconButton.filled(
              onPressed: disabled
                  ? null
                  : () {
                      final v = _input.text;
                      _input.clear();
                      setState(() => _typing = false);
                      _sendUser(v);
                    },
              icon: const Icon(Icons.send_rounded),
              iconSize: 26,
              style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
            )
          else
            GestureDetector(
              onTap: disabled ? null : _mic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: listening ? 72 : 62,
                height: listening ? 72 : 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: disabled
                      ? AppColors.card
                      : listening
                          ? AppColors.mint
                          : AppColors.accent,
                  boxShadow: [
                    if (!disabled)
                      BoxShadow(
                        color: (listening ? AppColors.mint : AppColors.accent).withValues(alpha: 0.45),
                        blurRadius: listening ? 26 : 14,
                      ),
                  ],
                ),
                child: Icon(
                  listening ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 32,
                  color: disabled ? AppColors.muted : const Color(0xFF1A1030),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  const _Pill({required this.child, this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: (color ?? Colors.black).withValues(alpha: color == null ? 0.45 : 0.9),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final v = ((_c.value * 3 - i) % 3);
          final on = v >= 0 && v < 1;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: on ? AppColors.accent : Colors.white38,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  final ChatMsg msg;
  final bool showAr;
  const _Subtitle({required this.msg, required this.showAr});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(msg.text,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.35)),
          if (showAr && msg.ar.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(msg.ar,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, color: AppColors.accent, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMsg msg;
  final bool showAr;
  final bool live;
  final VoidCallback? onReplay, onSaveCorrection, onHearCorrection;
  const _Bubble({
    required this.msg,
    required this.showAr,
    this.live = false,
    this.onReplay,
    this.onSaveCorrection,
    this.onHearCorrection,
  });

  @override
  Widget build(BuildContext context) {
    final me = msg.fromUser;
    // في الواجهة العربي: رسائلي على اليمين، رسائل الشخصية على الشمال
    return Align(
      alignment: me ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: me ? AppColors.mint.withValues(alpha: live ? 0.08 : 0.14) : AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: me ? AppColors.mint.withValues(alpha: 0.35) : AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      msg.text,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.4,
                        fontStyle: live ? FontStyle.italic : FontStyle.normal,
                        color: live ? AppColors.muted : AppColors.text,
                      ),
                    ),
                  ),
                  if (onReplay != null)
                    InkWell(
                      onTap: onReplay,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 6, left: 2),
                        child: Icon(Icons.volume_up_rounded, size: 20, color: AppColors.accent),
                      ),
                    ),
                ],
              ),
              if (showAr && msg.ar.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(msg.ar,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.5)),
              ],
              if (msg.correction.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        const Icon3D('light_bulb', size: 20),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text('الأصح تقول:',
                              style: TextStyle(
                                  fontSize: 12.5, color: AppColors.accent, fontWeight: FontWeight.w700)),
                        ),
                        if (onHearCorrection != null)
                          InkWell(
                            onTap: onHearCorrection,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.volume_up_rounded, size: 20, color: AppColors.accent),
                            ),
                          ),
                        if (onSaveCorrection != null)
                          InkWell(
                            onTap: onSaveCorrection,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.star_border_rounded, size: 20, color: AppColors.accent),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 4),
                      Text(msg.correction,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (msg.correctionAr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(msg.correctionAr,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
