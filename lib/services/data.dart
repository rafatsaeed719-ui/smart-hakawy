import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config.dart';
import '../models.dart';

class AppUser {
  final String uid, name, email, status;
  final int sessions;
  final int lastScore;
  final DateTime? createdAt;
  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.status,
    required this.sessions,
    required this.lastScore,
    this.createdAt,
  });

  bool get isAdmin => email.toLowerCase() == kAdminEmail.toLowerCase();

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data() ?? {};
    final ts = j['createdAt'];
    return AppUser(
      uid: d.id,
      name: '${j['name'] ?? ''}',
      email: '${j['email'] ?? ''}',
      status: '${j['status'] ?? 'pending'}',
      sessions: (j['sessions'] is num) ? (j['sessions'] as num).toInt() : 0,
      lastScore: (j['lastScore'] is num) ? (j['lastScore'] as num).toInt() : -1,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class AppSettings {
  final String geminiKey;
  final String model;
  AppSettings(this.geminiKey, this.model);
}

class Data {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static bool get isAdmin =>
      (_auth.currentUser?.email ?? '').toLowerCase() == kAdminEmail.toLowerCase();

  static DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  static Stream<User?> authChanges() => _auth.authStateChanges();

  static Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  static Future<void> register(String name, String email, String password) async {
    final cred =
        await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    await cred.user?.updateDisplayName(name.trim());
    await ensureUserDoc(cred.user!, name: name.trim());
  }

  static Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  static Future<void> signOut() => _auth.signOut();

  /// يتأكد إن للمستخدم ملف في قاعدة البيانات (جديد = منتظر موافقة).
  static Future<void> ensureUserDoc(User user, {String? name}) async {
    final ref = _userRef(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    final admin = (user.email ?? '').toLowerCase() == kAdminEmail.toLowerCase();
    await ref.set({
      'name': name ?? user.displayName ?? (user.email ?? '').split('@').first,
      'email': user.email ?? '',
      'status': admin ? 'approved' : 'pending',
      'sessions': 0,
      'lastScore': -1,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<AppUser?> watchMe() {
    final u = _auth.currentUser;
    if (u == null) return Stream.value(null);
    return _userRef(u.uid).snapshots().map((d) => d.exists ? AppUser.fromDoc(d) : null);
  }

  // ---------------- إعدادات الذكاء الاصطناعي ----------------
  static DocumentReference<Map<String, dynamic>> get _configRef =>
      _db.collection('config').doc('app');

  static Future<AppSettings> loadSettings() async {
    final d = await _configRef.get();
    final j = d.data() ?? {};
    final model = '${j['model'] ?? ''}'.trim();
    return AppSettings('${j['geminiKey'] ?? ''}', model.isEmpty ? kDefaultModel : model);
  }

  static Future<void> saveSettings(String key, String model) => _configRef.set({
        'geminiKey': key.trim(),
        'model': model.trim().isEmpty ? kDefaultModel : model.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // ---------------- الجلسات والتقييمات ----------------
  static Future<void> saveSession({
    required String personaName,
    required String topic,
    required String level,
    required int userMessages,
    required int minutes,
    required Evaluation eval,
  }) async {
    final u = _auth.currentUser;
    if (u == null) return;
    final ref = _userRef(u.uid);
    await ref.collection('sessions').add({
      'persona': personaName,
      'topic': topic,
      'level': level,
      'userMessages': userMessages,
      'minutes': minutes,
      'eval': eval.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ref.set({
      'sessions': FieldValue.increment(1),
      'lastScore': eval.overall,
      'lastLevel': eval.level,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchSessions([String? uid]) =>
      _userRef(uid ?? _auth.currentUser!.uid)
          .collection('sessions')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots();

  // ---------------- لوحة الأدمن ----------------
  static Stream<List<AppUser>> watchUsers() => _db
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map(AppUser.fromDoc).toList());

  static Future<void> setStatus(String uid, String status) =>
      _userRef(uid).set({'status': status}, SetOptions(merge: true));

  static Future<void> deleteUserDoc(String uid) => _userRef(uid).delete();

  static String authError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'الإيميل مكتوب غلط';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'الإيميل أو الباسورد غلط';
        case 'email-already-in-use':
          return 'الإيميل ده متسجل قبل كده، جرّب تسجّل دخول';
        case 'weak-password':
          return 'الباسورد ضعيف، خليه 6 حروف أو أكتر';
        case 'network-request-failed':
          return 'مفيش إنترنت';
        case 'too-many-requests':
          return 'محاولات كتير، استنى شوية وجرّب تاني';
      }
      return e.message ?? e.code;
    }
    return '$e';
  }
}
