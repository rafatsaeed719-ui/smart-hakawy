import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// حفظ الشخصيات اللي المستخدم عملها من صوره (على الموبايل نفسه).
class PersonaStore {
  static const _key = 'custom_personas_v1';

  static Future<List<Persona>> loadCustom() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key) ?? [];
    final out = <Persona>[];
    for (final s in list) {
      try {
        final per = Persona.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
        if (per.photoPath == null || File(per.photoPath!).existsSync()) out.add(per);
      } catch (_) {}
    }
    return out;
  }

  static Future<List<Persona>> loadAll() async => [...builtInPersonas(), ...await loadCustom()];

  static Future<void> save(Persona persona) async {
    final p = await SharedPreferences.getInstance();
    final all = await loadCustom();
    final i = all.indexWhere((e) => e.id == persona.id);
    if (i >= 0) {
      all[i] = persona;
    } else {
      all.add(persona);
    }
    await p.setStringList(_key, all.map((e) => e.encode()).toList());
  }

  static Future<void> delete(Persona persona) async {
    final p = await SharedPreferences.getInstance();
    final all = await loadCustom();
    all.removeWhere((e) => e.id == persona.id);
    await p.setStringList(_key, all.map((e) => e.encode()).toList());
    if (persona.photoPath != null) {
      try {
        await File(persona.photoPath!).delete();
      } catch (_) {}
    }
  }

  /// ينسخ الصورة المختارة جوه ملفات البرنامج عشان متضيعش.
  static Future<String> keepPhoto(String srcPath, String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/personas');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final ext = srcPath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final dst = '${folder.path}/$id.$ext';
    await File(srcPath).copy(dst);
    return dst;
  }

  static String newId() =>
      'p${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999)}';
}

/// نتيجة كشف الوش في الصورة.
class FaceInfo {
  final bool found;
  final double mouthX, mouthY, mouthW;
  final double eyeLX, eyeLY, eyeRX, eyeRY, eyeR;
  final double faceBottom;
  FaceInfo({
    required this.found,
    required this.mouthX,
    required this.mouthY,
    required this.mouthW,
    required this.eyeLX,
    required this.eyeLY,
    required this.eyeRX,
    required this.eyeRY,
    required this.eyeR,
    required this.faceBottom,
  });

  void applyTo(Persona p) {
    p
      ..faceFound = found
      ..mouthX = mouthX
      ..mouthY = mouthY
      ..mouthW = mouthW
      ..eyeLX = eyeLX
      ..eyeLY = eyeLY
      ..eyeRX = eyeRX
      ..eyeRY = eyeRY
      ..eyeR = eyeR
      ..faceBottom = faceBottom;
  }
}

class FaceLocator {
  /// يدوّر على الوش ومكان البق والعينين في الصورة.
  static Future<FaceInfo> locate(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final w = frame.image.width.toDouble();
    final h = frame.image.height.toDouble();
    frame.image.dispose();

    final detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    try {
      final faces = await detector.processImage(InputImage.fromFilePath(path));
      if (faces.isEmpty) return _fallback();
      faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
          .compareTo(a.boundingBox.width * a.boundingBox.height));
      final f = faces.first;
      final box = f.boundingBox;

      List<Point<int>> pts(FaceContourType t) => f.contours[t]?.points ?? const [];
      double avgX(List<Point<int>> p) => p.map((e) => e.x).reduce((a, b) => a + b) / p.length;
      double avgY(List<Point<int>> p) => p.map((e) => e.y).reduce((a, b) => a + b) / p.length;

      // البق
      double mx, my, mw;
      final upperBottom = pts(FaceContourType.upperLipBottom);
      final lowerTop = pts(FaceContourType.lowerLipTop);
      final upperTop = pts(FaceContourType.upperLipTop);
      if (upperBottom.isNotEmpty && lowerTop.isNotEmpty) {
        mx = (avgX(upperBottom) + avgX(lowerTop)) / 2;
        my = (avgY(upperBottom) + avgY(lowerTop)) / 2;
        final xs = (upperTop.isNotEmpty ? upperTop : upperBottom).map((e) => e.x.toDouble());
        mw = xs.reduce(max) - xs.reduce(min);
      } else {
        final bm = f.landmarks[FaceLandmarkType.bottomMouth]?.position;
        final lm = f.landmarks[FaceLandmarkType.leftMouth]?.position;
        final rm = f.landmarks[FaceLandmarkType.rightMouth]?.position;
        if (lm != null && rm != null) {
          mx = (lm.x + rm.x) / 2;
          my = (lm.y + rm.y) / 2;
          mw = (lm.x - rm.x).abs().toDouble();
          if (bm != null) my = (my * 2 + bm.y) / 3;
        } else {
          mx = box.center.dx;
          my = box.top + box.height * 0.78;
          mw = box.width * 0.36;
        }
      }
      if (mw < box.width * 0.2) mw = box.width * 0.33;

      // العينين
      Offset2 eye(FaceContourType c, FaceLandmarkType l, double fx) {
        final p = pts(c);
        if (p.isNotEmpty) {
          final xs = p.map((e) => e.x.toDouble());
          return Offset2(avgX(p), avgY(p), (xs.reduce(max) - xs.reduce(min)) / 2);
        }
        final lp = f.landmarks[l]?.position;
        if (lp != null) return Offset2(lp.x.toDouble(), lp.y.toDouble(), box.width * 0.09);
        return Offset2(box.left + box.width * fx, box.top + box.height * 0.4, box.width * 0.09);
      }

      final e1 = eye(FaceContourType.leftEye, FaceLandmarkType.leftEye, 0.68);
      final e2 = eye(FaceContourType.rightEye, FaceLandmarkType.rightEye, 0.32);

      final facePts = pts(FaceContourType.face);
      final bottom = facePts.isNotEmpty
          ? facePts.map((e) => e.y.toDouble()).reduce(max)
          : box.bottom.toDouble();

      return FaceInfo(
        found: true,
        mouthX: mx / w,
        mouthY: my / h,
        mouthW: mw / w,
        eyeLX: e1.x / w,
        eyeLY: e1.y / h,
        eyeRX: e2.x / w,
        eyeRY: e2.y / h,
        eyeR: ((e1.r + e2.r) / 2) / w,
        faceBottom: bottom / h,
      );
    } catch (_) {
      return _fallback();
    } finally {
      await detector.close();
    }
  }

  static FaceInfo _fallback() => FaceInfo(
        found: false,
        mouthX: 0.5,
        mouthY: 0.62,
        mouthW: 0.16,
        eyeLX: 0.42,
        eyeLY: 0.45,
        eyeRX: 0.58,
        eyeRY: 0.45,
        eyeR: 0.035,
        faceBottom: 0.75,
      );
}

class Offset2 {
  final double x, y, r;
  Offset2(this.x, this.y, this.r);
}
