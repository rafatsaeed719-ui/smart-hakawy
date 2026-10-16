/// ركن العبارات: جمل تعبيرية جاهزة لكل موقف.
class Phrase {
  final String en, ar;
  const Phrase(this.en, this.ar);
}

class PhraseCategory {
  final String title, icon;
  final List<Phrase> phrases;
  const PhraseCategory(this.title, this.icon, this.phrases);
}

const List<PhraseCategory> kPhraseCategories = [
  PhraseCategory('التحيات والتعارف', 'waving', [
    Phrase('Nice to meet you.', 'اتشرفت بمعرفتك.'),
    Phrase("How's it going?", 'إيه الأخبار؟'),
    Phrase("Long time no see!", 'بقالنا كتير ماشفناش بعض!'),
    Phrase('Let me introduce myself.', 'اسمحلي أعرّفك بنفسي.'),
    Phrase('What do you do for a living?', 'بتشتغل إيه؟'),
    Phrase("I'm from Egypt, and you?", 'أنا من مصر، وانت؟'),
    Phrase('It was great talking to you.', 'كان جميل إني اتكلمت معاك.'),
    Phrase('Take care, see you soon!', 'خلي بالك من نفسك، أشوفك قريب!'),
  ]),
  PhraseCategory('المشاعر', 'heart', [
    Phrase("I'm so excited about it!", 'أنا متحمس جدًا للموضوع ده!'),
    Phrase("I'm a bit nervous.", 'أنا متوتر شوية.'),
    Phrase('That made my day!', 'ده خلّى يومي حلو!'),
    Phrase("I'm really proud of myself.", 'أنا فخور بنفسي فعلًا.'),
    Phrase("I'm not in the mood today.", 'ماليش مزاج النهارده.'),
    Phrase("I can't wait!", 'مش قادر أستنى!'),
    Phrase("I'm fed up with this.", 'أنا زهقت من ده.'),
    Phrase('I feel much better now.', 'أنا أحسن كتير دلوقتي.'),
  ]),
  PhraseCategory('إبداء الرأي', 'thinking', [
    Phrase('In my opinion, ...', 'في رأيي، ...'),
    Phrase('I totally agree with you.', 'أنا متفق معاك تمامًا.'),
    Phrase("I see your point, but ...", 'فاهم وجهة نظرك، بس ...'),
    Phrase("I'm not sure about that.", 'مش متأكد من الموضوع ده.'),
    Phrase('That makes sense.', 'ده منطقي.'),
    Phrase('If I were you, I would ...', 'لو كنت مكانك، كنت ...'),
    Phrase("Let's look at it from another angle.", 'تعال نبص عليها من زاوية تانية.'),
    Phrase('To be honest, ...', 'بصراحة، ...'),
  ]),
  PhraseCategory('الشكر والاعتذار', 'smile', [
    Phrase('Thank you so much for your help.', 'شكرًا جدًا على مساعدتك.'),
    Phrase('I really appreciate it.', 'أنا مقدّر ده جدًا.'),
    Phrase("Don't mention it.", 'العفو، ولا يهمك.'),
    Phrase("I'm sorry for being late.", 'آسف على التأخير.'),
    Phrase('My apologies for the confusion.', 'بعتذر عن اللخبطة.'),
    Phrase("No worries, it's okay.", 'ولا يهمك، عادي.'),
    Phrase("It won't happen again.", 'مش هتتكرر تاني.'),
    Phrase('You saved my life!', 'انت أنقذتني!'),
  ]),
  PhraseCategory('في الشغل', 'briefcase', [
    Phrase('Could you send me the details?', 'ممكن تبعتلي التفاصيل؟'),
    Phrase("Let's schedule a meeting.", 'تعال نحدد معاد اجتماع.'),
    Phrase("I'll get back to you soon.", 'هرد عليك قريب.'),
    Phrase("I'm working on it right now.", 'أنا شغال عليه دلوقتي.'),
    Phrase('What is the deadline?', 'إيه آخر معاد للتسليم؟'),
    Phrase("I have strong communication skills.", 'عندي مهارات تواصل قوية.'),
    Phrase('Could you clarify that, please?', 'ممكن توضّح النقطة دي لو سمحت؟'),
    Phrase("Let's keep in touch.", 'خلينا على تواصل.'),
  ]),
  PhraseCategory('السفر', 'airplane', [
    Phrase('Where is the check-in counter?', 'فين مكان تسجيل الوصول؟'),
    Phrase("I'd like to book a room for two nights.", 'عايز أحجز أوضة لليلتين.'),
    Phrase('How can I get to the city center?', 'أروح وسط البلد إزاي؟'),
    Phrase('Is breakfast included?', 'الفطار من ضمن الحجز؟'),
    Phrase('My flight has been delayed.', 'رحلتي اتأخرت.'),
    Phrase("Could you take a photo of us?", 'ممكن تصوّرنا؟'),
    Phrase("I've lost my luggage.", 'شنطتي ضاعت.'),
    Phrase('How far is it from here?', 'هو بعيد قد إيه من هنا؟'),
  ]),
  PhraseCategory('المطعم والتسوق', 'fork_knife', [
    Phrase('Can I see the menu, please?', 'ممكن المنيو لو سمحت؟'),
    Phrase("I'd like to order, please.", 'عايز أطلب لو سمحت.'),
    Phrase('Could we have the bill, please?', 'ممكن الحساب لو سمحت؟'),
    Phrase('Do you have this in a bigger size?', 'عندك ده مقاس أكبر؟'),
    Phrase('How much does this cost?', 'ده بكام؟'),
    Phrase("I'm just looking, thanks.", 'أنا بتفرج بس، شكرًا.'),
    Phrase('Can I pay by card?', 'ينفع أدفع بالفيزا؟'),
    Phrase('This is delicious!', 'ده طعمه تحفة!'),
  ]),
  PhraseCategory('التشجيع والمجاملة', 'clap', [
    Phrase('You did a great job!', 'انت عملت شغل عظيم!'),
    Phrase('Keep up the good work!', 'كمّل على كده!'),
    Phrase("Don't give up!", 'متستسلمش!'),
    Phrase('You look great today.', 'شكلك حلو النهارده.'),
    Phrase('I believe in you.', 'أنا واثق فيك.'),
    Phrase("You've got this!", 'انت قدها!'),
    Phrase('Well done, I knew you could do it.', 'برافو، كنت عارف إنك هتعملها.'),
    Phrase('Practice makes perfect.', 'التمرين بيوصّل للإتقان.'),
  ]),
];
