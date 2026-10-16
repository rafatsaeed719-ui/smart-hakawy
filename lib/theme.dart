import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF120D2B);
  static const surface = Color(0xFF1D1640);
  static const card = Color(0xFF261D52);
  static const line = Color(0xFF3A2F70);
  static const accent = Color(0xFFFFB547); // كهرماني
  static const mint = Color(0xFF5EE6C8);
  static const text = Color(0xFFF4F1FF);
  static const muted = Color(0xFFA9A2CF);
  static const danger = Color(0xFFFF6B81);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6C4DFF),
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: const Color(0xFF2A1A00),
    secondary: AppColors.mint,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.danger,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: Brightness.dark);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// شعار البرنامج: فقاعة كلام فيها حرف H.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 72});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC56B), Color(0xFFFF8A5C)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'حكاوي',
        style: TextStyle(
          fontSize: size * 0.26,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF2A1A00),
        ),
      ),
    );
  }
}

void toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : null,
    ));
}
