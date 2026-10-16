import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../models.dart';

/// بيتحكم في حركة الشخصية: بتتكلم ولا ساكتة، ونبضة مع كل كلمة.
class AvatarDriver extends ChangeNotifier {
  bool talking = false;
  double _wordPulse = 0;
  void setTalking(bool v) {
    if (talking == v) return;
    talking = v;
    notifyListeners();
  }

  void word() => _wordPulse = 1.0;
}

/// صورة بتتكلم: البق بيتفتح ويتقفل، الراس بتتحرك، والعينين بترمش.
class TalkingAvatar extends StatefulWidget {
  final Persona persona;
  final AvatarDriver driver;
  const TalkingAvatar({super.key, required this.persona, required this.driver});

  @override
  State<TalkingAvatar> createState() => _TalkingAvatarState();
}

class _TalkingAvatarState extends State<TalkingAvatar> with SingleTickerProviderStateMixin {
  ui.Image? _image;
  late final Ticker _ticker;
  final _clock = _AvatarClock();
  final _rnd = Random();
  Duration _last = Duration.zero;
  double _nextBlink = 2.5;
  double _blinkStart = -10;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didUpdateWidget(covariant TalkingAvatar old) {
    super.didUpdateWidget(old);
    if (old.persona.id != widget.persona.id ||
        old.persona.photoPath != widget.persona.photoPath ||
        old.persona.asset != widget.persona.asset) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      Uint8List bytes;
      final p = widget.persona;
      if (p.asset != null) {
        bytes = (await rootBundle.load(p.asset!)).buffer.asUint8List();
      } else {
        bytes = await File(p.photoPath!).readAsBytes();
      }
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 900);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _image = frame.image);
    } catch (_) {}
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = elapsed;
    final t = elapsed.inMicroseconds / 1e6;
    final d = widget.driver;

    // البق
    d._wordPulse *= exp(-dt / 0.16);
    double target = 0;
    if (d.talking) {
      final osc = 0.5 + 0.5 * sin(t * 13.0 + sin(t * 4.7) * 2.2);
      final osc2 = 0.5 + 0.5 * sin(t * 7.3 + 1.3);
      target = (0.12 + 0.45 * d._wordPulse + 0.32 * osc * (0.55 + 0.45 * osc2)).clamp(0.0, 1.0);
    }
    final k = target > _clock.mouth ? 28.0 : 18.0;
    _clock.mouth += (target - _clock.mouth) * (1 - exp(-k * dt));

    // الرمش
    if (t > _nextBlink) {
      _blinkStart = t;
      _nextBlink = t + 2.2 + _rnd.nextDouble() * 3.5;
    }
    final bt = (t - _blinkStart) / 0.17;
    _clock.blink = (bt >= 0 && bt <= 1) ? sin(bt * pi) : 0;

    // حركة الراس
    _clock.time = t;
    _clock.talkMix += ((d.talking ? 1.0 : 0.0) - _clock.talkMix) * (1 - exp(-3 * dt));
    _clock.notify();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _image?.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (img == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return CustomPaint(
      painter: _AvatarPainter(img, widget.persona, _clock),
      size: Size.infinite,
    );
  }
}

class _AvatarClock extends ChangeNotifier {
  double mouth = 0, blink = 0, time = 0, talkMix = 0;
  void notify() => notifyListeners();
}

class _AvatarPainter extends CustomPainter {
  final ui.Image image;
  final Persona p;
  final _AvatarClock c;
  _AvatarPainter(this.image, this.p, this.c) : super(repaint: c);

  static const int _cols = 56;
  static const int _rowsAbove = 44;
  static const int _rowsBelow = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();

    // نملأ المساحة ونخلي الوش في النص
    final scale = max(size.width / iw, size.height / ih) * 1.04;
    final faceCx = (p.eyeLX + p.eyeRX + p.mouthX * 2) / 4 * iw;
    final faceCy = ((p.eyeLY + p.eyeRY) / 2 * 0.5 + p.mouthY * 0.5) * ih;
    double ox = size.width / 2 - faceCx * scale;
    double oy = size.height * 0.46 - faceCy * scale;
    // هامش صغير عشان حركة الراس متكشفش أطراف
    final mX = size.width * 0.015, mY = size.height * 0.015;
    ox = ox.clamp(size.width - iw * scale + mX, -mX);
    oy = oy.clamp(size.height - ih * scale + mY, -mY);

    final mx = p.mouthX * iw, my = p.mouthY * ih, mw = max(p.mouthW * iw, iw * 0.04);
    final faceBottom = max(p.faceBottom * ih, my + mw * 0.6);
    final jaw = c.mouth * mw * 0.30;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // حركة الراس (تنفس + هزة خفيفة وهو بيتكلم)
    final t = c.time;
    final pivot = Offset(ox + mx * scale, oy + faceBottom * scale);
    final angle = sin(t * 0.8) * 0.006 + c.talkMix * (sin(t * 1.9) * 0.012 + sin(t * 3.1) * 0.005);
    final breath = 1 + sin(t * 1.5) * 0.004;
    final nod = c.talkMix * sin(t * 2.6) * size.height * 0.003;
    canvas.translate(pivot.dx, pivot.dy + nod);
    canvas.rotate(angle);
    canvas.scale(breath, breath);
    canvas.translate(-pivot.dx, -pivot.dy);

    // خلفية بنفس الصورة (للأطراف)
    final shader = ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
      filterQuality: FilterQuality.medium,
    );

    // جوه البق (بيبان لما الفك ينزل)
    if (jaw > 0.4) {
      final cy = oy + (my + jaw * 0.35) * scale;
      final rect = Rect.fromCenter(
        center: Offset(ox + mx * scale, cy),
        width: mw * 0.92 * scale,
        height: (jaw * 1.35 + 2) * scale,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            rect.topCenter,
            rect.bottomCenter,
            const [Color(0xFF3A0F12), Color(0xFF16060A), Color(0xFF5A1E22)],
            const [0.0, 0.6, 1.0],
          ),
      );
      // سنان خفيفة فوق
      final teeth = Rect.fromLTWH(
          rect.left + rect.width * 0.18, rect.top, rect.width * 0.64, rect.height * 0.22);
      canvas.drawRRect(
        RRect.fromRectAndRadius(teeth, Radius.circular(teeth.height * 0.4)),
        Paint()..color = const Color(0xFFEDE6DE).withValues(alpha: (c.mouth * 1.4).clamp(0.0, 0.85)),
      );
    }

    // شبكة مثلثات بتتمد عشان تحرك الفك والشفايف والجفون
    final ys = <double>[];
    for (int r = 0; r <= _rowsAbove; r++) {
      ys.add(my * r / _rowsAbove);
    }
    for (int r = 1; r <= _rowsBelow; r++) {
      ys.add(my + (ih - my) * r / _rowsBelow);
    }
    final rows = ys.length; // صف البق رقمه _rowsAbove
    final cols = _cols + 1;
    final vCount = rows * cols + cols; // صف إضافي لنسخة الشفة السفلى
    final pos = Float32List(vCount * 2);
    final tex = Float32List(vCount * 2);

    final lipSigma = mw * 0.42;
    final eyes = [
      [p.eyeLX * iw, p.eyeLY * ih],
      [p.eyeRX * iw, p.eyeRY * ih],
    ];
    final er = max(p.eyeR * iw, iw * 0.012);

    void put(int idx, double x, double y, bool lowerLip) {
      double dy = 0;
      if (jaw > 0) {
        if (y > my || (y == my && lowerLip)) {
          // الفك بينزل، وكل ما نبعد عن البق التأثير يقل
          final depth = ((y - my) / max(faceBottom - my, 1)).clamp(0.0, 1.6);
          final sx = mw * (0.42 + 0.9 * min(depth, 1.0));
          final gx = exp(-pow((x - mx) / sx, 2).toDouble());
          final fade = depth <= 1 ? 1.0 : max(0.0, 1 - (depth - 1) / 0.6);
          dy = jaw * gx * fade;
        } else {
          // الشفة العليا بتطلع لفوق شوية
          final gx = exp(-pow((x - mx) / lipSigma, 2).toDouble());
          final gy = max(0.0, 1 - (my - y) / (mw * 0.45));
          dy = -jaw * 0.28 * gx * gy;
        }
      }
      // الرمش: نسحب جلد الجفن لتحت فوق العين
      double ty = y;
      if (c.blink > 0) {
        for (final e in eyes) {
          final nx = (x - e[0]) / (er * 1.7);
          final ny = (y - e[1]) / (er * 1.25);
          final d2 = nx * nx + ny * ny;
          if (d2 < 1) ty -= c.blink * er * 1.25 * (1 - d2);
        }
      }
      pos[idx * 2] = ox + x * scale;
      pos[idx * 2 + 1] = oy + (y + dy) * scale;
      tex[idx * 2] = x;
      tex[idx * 2 + 1] = ty;
    }

    for (int r = 0; r < rows; r++) {
      for (int col = 0; col < cols; col++) {
        put(r * cols + col, iw * col / _cols, ys[r], false);
      }
    }
    final lowerBase = rows * cols;
    for (int col = 0; col < cols; col++) {
      put(lowerBase + col, iw * col / _cols, my, true);
    }

    int vi(int r, int col, bool below) {
      if (r == _rowsAbove && below) return lowerBase + col;
      return r * cols + col;
    }

    final idx = Uint16List((rows - 1) * _cols * 6);
    int n = 0;
    for (int r = 0; r < rows - 1; r++) {
      final belowMouth = r >= _rowsAbove; // الصف ده تحت خط البق
      for (int col = 0; col < _cols; col++) {
        final a = vi(r, col, belowMouth);
        final b = vi(r, col + 1, belowMouth);
        final cc = vi(r + 1, col, false);
        final d = vi(r + 1, col + 1, false);
        idx[n++] = a;
        idx[n++] = b;
        idx[n++] = cc;
        idx[n++] = b;
        idx[n++] = d;
        idx[n++] = cc;
      }
    }

    final verts = ui.Vertices.raw(
      ui.VertexMode.triangles,
      pos,
      textureCoordinates: tex,
      indices: idx,
    );
    canvas.drawVertices(verts, BlendMode.srcOver, Paint()..shader = shader);
    verts.dispose();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) => old.image != image || old.p != p;
}
