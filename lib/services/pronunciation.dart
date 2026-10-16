/// تقييم النطق: بنقارن الكلام اللي اتسمع بالجملة المطلوبة كلمة كلمة.
class PronResult {
  final List<String> words; // كلمات الجملة الأصلية (للعرض)
  final List<bool> ok; // كل كلمة اتنطقت صح ولا لأ
  final int score;
  PronResult(this.words, this.ok, this.score);
}

List<String> _tokens(String s) => s
    .toLowerCase()
    .replaceAll('’', "'")
    .replaceAll(RegExp(r"[^a-z0-9' ]"), ' ')
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty && w != "'")
    .toList();

int _lev(String a, String b) {
  final m = List.generate(a.length + 1, (i) => List<int>.filled(b.length + 1, 0));
  for (int i = 0; i <= a.length; i++) {
    m[i][0] = i;
  }
  for (int j = 0; j <= b.length; j++) {
    m[0][j] = j;
  }
  for (int i = 1; i <= a.length; i++) {
    for (int j = 1; j <= b.length; j++) {
      final c = a[i - 1] == b[j - 1] ? 0 : 1;
      m[i][j] = [m[i - 1][j] + 1, m[i][j - 1] + 1, m[i - 1][j - 1] + c].reduce((x, y) => x < y ? x : y);
    }
  }
  return m[a.length][b.length];
}

bool _same(String a, String b) {
  if (a == b) return true;
  final na = a.replaceAll("'", ''), nb = b.replaceAll("'", '');
  if (na == nb) return true;
  if (na.length >= 5 && _lev(na, nb) <= 1) return true;
  return false;
}

PronResult scorePronunciation(String target, String heard) {
  final display = target.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
  final t = display.map((w) => _tokens(w).join()).toList();
  final h = _tokens(heard);
  // أطول تطابق متسلسل (LCS) بين الكلمات
  final n = t.length, m = h.length;
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (int i = n - 1; i >= 0; i--) {
    for (int j = m - 1; j >= 0; j--) {
      dp[i][j] = (t[i].isNotEmpty && _same(t[i], h[j]))
          ? dp[i + 1][j + 1] + 1
          : (dp[i + 1][j] > dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
    }
  }
  final ok = List<bool>.filled(n, false);
  int i = 0, j = 0;
  while (i < n && j < m) {
    if (t[i].isNotEmpty && _same(t[i], h[j])) {
      ok[i] = true;
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  // الكلمات اللي مفيهاش حروف (زي "...") متتحسبش
  int total = 0, good = 0;
  for (int k = 0; k < n; k++) {
    if (t[k].isEmpty) {
      ok[k] = true;
      continue;
    }
    total++;
    if (ok[k]) good++;
  }
  // كلام زيادة كتير بيقلل الدرجة شوية
  final extra = (m - good).clamp(0, 100);
  var score = total == 0 ? 0 : (good * 100 / total).round();
  score = (score - extra * 3).clamp(0, 100);
  return PronResult(display, ok, score);
}
