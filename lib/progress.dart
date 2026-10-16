/// المستويات (بالنقاط) ورسايل التشجيع.
class Rank {
  final String name, icon;
  final int minXp;
  const Rank(this.name, this.icon, this.minXp);
}

const List<Rank> kRanks = [
  Rank('بذرة', 'seedling', 0),
  Rank('مستكشف', 'compass', 100),
  Rank('متكلّم', 'speech', 250),
  Rank('واثق', 'muscle', 450),
  Rank('منطلق', 'rocket', 700),
  Rank('طليق', 'star', 1000),
  Rank('محترف', 'medal', 1400),
  Rank('نجم', 'glowing_star', 1900),
  Rank('بطل', 'trophy', 2500),
  Rank('أسطورة', 'crown', 3200),
];

class RankInfo {
  final int index;
  final Rank rank;
  final Rank? next;
  final double progress; // للوصول للمستوى الجاي
  final int toNext;
  RankInfo(this.index, this.rank, this.next, this.progress, this.toNext);
}

RankInfo rankFor(int xp) {
  int i = 0;
  for (int k = 0; k < kRanks.length; k++) {
    if (xp >= kRanks[k].minXp) i = k;
  }
  final r = kRanks[i];
  final next = i + 1 < kRanks.length ? kRanks[i + 1] : null;
  if (next == null) return RankInfo(i, r, null, 1, 0);
  final span = next.minXp - r.minXp;
  return RankInfo(i, r, next, ((xp - r.minXp) / span).clamp(0.0, 1.0), next.minXp - xp);
}

/// نقاط كل نشاط
class Xp {
  static int forCall(int score, int userMessages) =>
      15 + (score / 4).round() + (userMessages * 2).clamp(0, 30);
  static const perQuizCorrect = 5;
  static const perGoodPronunciation = 4;
}

const List<String> kMotivation = [
  'كل كلمة بتقولها النهارده بتقرّبك خطوة من الطلاقة. يلا نكمّل!',
  'مش لازم تكون مثالي، المهم تتكلم. الغلط هو أسرع طريق للتعلم 💪',
  'عشر دقايق كل يوم أحسن من ساعتين مرة في الأسبوع. خليك مستمر!',
  'انت أشطر مما تتخيل. كل مكالمة بتعملها بتبني ثقتك.',
  'الإنجليزي مهارة زي العجلة، بالتمرين بتبقى سهلة جدًا.',
  'افتكر ليه بدأت… وكمّل عشان الحلم ده.',
  'النهارده فرصة جديدة تقول جملة ماكنتش تعرف تقولها امبارح.',
  'متقارنش نفسك بحد، قارن نفسك بنفسك من أسبوع فات.',
  'كل محترف كان في يوم مبتدئ. انت ماشي صح.',
  'صوتك بالإنجليزي يستاهل يتسمع. اتكلم ومتخافش.',
  'الاستمرارية هي السر. حافظ على عدّاد أيامك 🔥',
  'جملة واحدة صح النهارده = خطوة كبيرة بكرة.',
  'التعلم مش سباق. خد وقتك واستمتع بالرحلة.',
  'كل ما تتكلم أكتر، دماغك بيفكر بالإنجليزي أسرع.',
];

String motivationOfDay() {
  final d = DateTime.now();
  final dayOfYear = d.difference(DateTime(d.year)).inDays;
  return kMotivation[dayOfYear % kMotivation.length];
}

String encouragementFor(int score) {
  if (score >= 90) return 'إيه الحلاوة دي! مستواك ممتاز، كمّل كده وهتبقى طليق خالص 🤩';
  if (score >= 75) return 'شغل جامد! انت ماشي بسرعة حلوة، شوية تركيز على الأخطاء وهتطير 🚀';
  if (score >= 60) return 'كويس جدًا! كل مكالمة بتفرق، راجع التصحيحات وجرّب تاني 💪';
  if (score >= 40) return 'بداية حلوة! متقلقش من الأخطاء، هي اللي بتعلّمك. كمّل كل يوم 🌱';
  return 'أهم حاجة إنك بدأت واتكلمت! خد الموضوع واحدة واحدة وهتشوف الفرق بسرعة ❤️';
}
