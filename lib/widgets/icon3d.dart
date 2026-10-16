import 'package:flutter/material.dart';

/// أيقونة 3D (Fluent Emoji من مايكروسوفت — رخصة MIT).
/// الصور بتتنزل وقت بناء البرنامج، ولو صورة مش موجودة بيظهر الإيموجي العادي.
class Icon3D extends StatelessWidget {
  final String name;
  final double size;
  const Icon3D(this.name, {super.key, this.size = 40});

  static const Map<String, String> fallback = {
    'rocket': '🚀', 'fire': '🔥', 'trophy': '🏆', 'star': '⭐', 'glowing_star': '🌟',
    'party': '🎉', 'books': '📚', 'speech': '💬', 'microphone': '🎤', 'headphone': '🎧',
    'brain': '🧠', 'bullseye': '🎯', 'memo': '📝', 'light_bulb': '💡', 'crown': '👑',
    'gem': '💎', 'medal': '🥇', 'sports_medal': '🏅', 'airplane': '✈️', 'fork_knife': '🍽️',
    'shopping': '🛍️', 'briefcase': '💼', 'hospital': '🏥', 'clapper': '🎬', 'soccer': '⚽',
    'house': '🏡', 'sun': '☀️', 'globe': '🌍', 'seedling': '🌱', 'graduation': '🎓',
    'check': '✅', 'cross': '❌', 'speaker': '🔊', 'bookmark': '🔖', 'heart': '❤️',
    'waving': '👋', 'muscle': '💪', 'clap': '👏', 'thinking': '🤔', 'smile': '😊',
    'star_struck': '🤩', 'pencil': '✏️', 'chart': '📈', 'calendar': '🗓️', 'lock': '🔒',
    'puzzle': '🧩', 'family': '🫂', 'ear': '👂', 'turtle': '🐢', 'rabbit': '🐇', 'key': '🔑',
    'camera': '📸', 'hourglass': '⏳', 'thumbs_up': '👍', 'sparkles': '✨', 'compass': '🧭',
    'video': '📹', 'robot': '🤖', 'hundred': '💯', 'sad': '😕', 'gift': '🎁', 'map': '🗺️',
  };

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/3d/$name.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: (size * 3).round(),
      errorBuilder: (_, __, ___) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(fallback[name] ?? '✨', style: TextStyle(fontSize: size * 0.78, height: 1)),
        ),
      ),
    );
  }
}
