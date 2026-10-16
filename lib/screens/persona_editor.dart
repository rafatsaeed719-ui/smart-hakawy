import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../services/personas.dart';
import '../services/voice.dart';
import '../theme.dart';
import '../widgets/talking_avatar.dart';

const _styles = <String, String>{
  'مدرس صبور': 'a warm, patient English teacher who encourages the learner and explains gently',
  'صاحب رِوِش': 'a fun, casual friend who chats naturally using everyday slang',
  'مدير انترفيو': 'a professional HR manager who conducts realistic job interviews',
  'سائح أجنبي': 'a curious foreign tourist visiting Egypt who asks lots of questions',
  'رجل أعمال': 'a busy business person who talks about work, meetings and deals',
};

class PersonaEditor extends StatefulWidget {
  final Persona? persona;
  const PersonaEditor({super.key, this.persona});
  @override
  State<PersonaEditor> createState() => _PersonaEditorState();
}

class _PersonaEditorState extends State<PersonaEditor> {
  late Persona _p;
  late final TextEditingController _name;
  late final TextEditingController _custom;
  String _style = 'مدرس صبور';
  bool _busy = false;
  bool _hasPhoto = false;
  List<Map<String, String>> _voices = [];
  final _driver = AvatarDriver();

  @override
  void initState() {
    super.initState();
    final src = widget.persona;
    _p = src != null ? Persona.fromJson(src.toJson()) : Persona(id: PersonaStore.newId(), name: '');
    _hasPhoto = _p.photoPath != null;
    _name = TextEditingController(text: _p.name);
    final match = _styles.entries.where((e) => _p.personality.endsWith(e.value));
    _style = match.isNotEmpty ? match.first.key : (src == null ? 'مدرس صبور' : 'مخصص');
    _custom = TextEditingController(text: _style == 'مخصص' ? _p.personality : '');
    Voice.I.speaking.addListener(_onSpeaking);
    Voice.I.onWord = _driver.word;
    _loadVoices();
  }

  List<Map<String, String>> get _accentVoices => _voices
      .where((v) => v['locale']!.replaceAll('_', '-').toLowerCase() == _p.accent.toLowerCase())
      .toList();

  void _onSpeaking() => _driver.setTalking(Voice.I.speaking.value);

  Future<void> _loadVoices() async {
    final v = await Voice.I.englishVoices();
    if (mounted) setState(() => _voices = v);
  }

  @override
  void dispose() {
    Voice.I.speaking.removeListener(_onSpeaking);
    Voice.I.onWord = null;
    Voice.I.stopSpeaking();
    _driver.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1440,
      imageQuality: 92,
      preferredCameraDevice: CameraDevice.front,
    );
    if (x == null) return;
    setState(() => _busy = true);
    try {
      final kept = await PersonaStore.keepPhoto(x.path, '${_p.id}_${DateTime.now().millisecondsSinceEpoch}');
      final info = await FaceLocator.locate(kept);
      info.applyTo(_p);
      setState(() {
        _p.photoPath = kept;
        _p.asset = null;
        _hasPhoto = true;
      });
      if (!info.found && mounted) {
        toast(context, 'مقدرناش نلاقي وش واضح في الصورة. جرّب صورة الوش فيها من قدام وواضح.',
            error: true);
      }
    } catch (e) {
      if (mounted) toast(context, 'مشكلة في الصورة: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _choosePhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('من المعرض'),
            onTap: () {
              Navigator.pop(context);
              _pick(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: const Text('صوّر دلوقتي'),
            onTap: () {
              Navigator.pop(context);
              _pick(ImageSource.camera);
            },
          ),
        ]),
      ),
    );
  }

  void _applyFields() {
    _p.name = _name.text.trim();
    _p.personality = _style == 'مخصص'
        ? (_custom.text.trim().isEmpty ? _styles['مدرس صبور']! : _custom.text.trim())
        : '${_p.name.isEmpty ? 'A person' : _p.name}, ${_styles[_style]!}';
  }

  Future<void> _preview() async {
    _applyFields();
    await Voice.I.configure(_p);
    final n = _p.name.isEmpty ? 'your new friend' : _p.name;
    await Voice.I.speak("Hi there! I'm $n. Let's practice English together. How are you today?");
  }

  Future<void> _save() async {
    if (!_hasPhoto) {
      toast(context, 'اختار صورة الأول', error: true);
      return;
    }
    if (_name.text.trim().isEmpty) {
      toast(context, 'اكتب اسم للشخصية', error: true);
      return;
    }
    _applyFields();
    await PersonaStore.save(_p);
    if (mounted) Navigator.pop(context, _p.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.persona == null ? 'شخصية جديدة' : 'تعديل الشخصية')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        children: [
          AspectRatio(
            aspectRatio: 0.9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: AppColors.surface,
                child: _busy
                    ? const Center(child: CircularProgressIndicator())
                    : !_hasPhoto
                        ? InkWell(
                            onTap: _choosePhoto,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 56, color: AppColors.accent),
                                SizedBox(height: 12),
                                Text('اختار صورة شخص',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                SizedBox(height: 6),
                                Text('أحسن حاجة صورة الوش فيها واضح ومن قدام',
                                    style: TextStyle(color: AppColors.muted)),
                              ],
                            ),
                          )
                        : Stack(fit: StackFit.expand, children: [
                            TalkingAvatar(persona: _p, driver: _driver),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: FilledButton.tonalIcon(
                                onPressed: _choosePhoto,
                                icon: const Icon(Icons.swap_horiz_rounded),
                                label: const Text('غيّر الصورة'),
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                              ),
                            ),
                          ]),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'اسم الشخصية (بالإنجليزي)',
              hintText: 'Ahmed, Lina, Mr. John...',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
          ),
          const SizedBox(height: 22),
          const _Label('الصوت'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'female', label: Text('ست'), icon: Icon(Icons.woman_rounded)),
              ButtonSegment(value: 'male', label: Text('راجل'), icon: Icon(Icons.man_rounded)),
            ],
            selected: {_p.gender},
            onSelectionChanged: (s) => setState(() {
              _p.gender = s.first;
              _p.pitch = s.first == 'male' ? 0.85 : 1.1;
            }),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en-US', label: Text('🇺🇸 أمريكي')),
              ButtonSegment(value: 'en-GB', label: Text('🇬🇧 بريطاني')),
            ],
            selected: {_p.accent},
            onSelectionChanged: (s) => setState(() {
              _p.accent = s.first;
              _p.voiceName = null;
            }),
          ),
          const SizedBox(height: 12),
          if (_accentVoices.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey(_p.accent),
              initialValue: _accentVoices.any((v) => v['name'] == _p.voiceName) ? _p.voiceName : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'نبرة الصوت (اختياري)'),
              items: [
                for (final v in _accentVoices)
                  DropdownMenuItem(
                    value: v['name'],
                    child: Text(v['name']!, textDirection: TextDirection.ltr, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _p.voiceName = v),
            ),
          const SizedBox(height: 6),
          Row(children: [
            const Text('حدة الصوت'),
            Expanded(
              child: Slider(
                value: _p.pitch.clamp(0.6, 1.5),
                min: 0.6,
                max: 1.5,
                onChanged: (v) => setState(() => _p.pitch = v),
              ),
            ),
          ]),
          OutlinedButton.icon(
            onPressed: _preview,
            icon: const Icon(Icons.record_voice_over_rounded),
            label: const Text('اسمع الصوت'),
          ),
          const SizedBox(height: 22),
          const _Label('شخصيته عاملة إزاي؟'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in [..._styles.keys, 'مخصص'])
                ChoiceChip(
                  label: Text(k),
                  selected: _style == k,
                  onSelected: (_) => setState(() => _style = k),
                ),
            ],
          ),
          if (_style == 'مخصص') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _custom,
              maxLines: 3,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                hintText: 'Describe the character in English, e.g. "my funny uncle who lives in New York"',
              ),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('حفظ الشخصية'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      );
}
