import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/status_screen.dart';
import 'services/data.dart';
import 'services/local_store.dart';
import 'services/voice.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: kFirebaseOptions);
  Voice.I.rate = await LocalStore.speechRate() ?? 0.5;
  runApp(const HakawyApp());
}

class HakawyApp extends StatelessWidget {
  const HakawyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

/// بيحدد المستخدم يشوف إيه: تسجيل دخول / منتظر موافقة / محظور / الرئيسية.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Data.authChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Splash();
        final user = snap.data;
        if (user == null) return const AuthScreen();
        return _ProfileGate(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  final User user;
  const _ProfileGate({super.key, required this.user});
  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late final Future<void> _ensure = Data.ensureUserDoc(widget.user);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _ensure,
      builder: (context, f) {
        if (f.connectionState != ConnectionState.done) return const Splash();
        if (f.hasError) {
          return StatusScreen(
            icon: Icons.wifi_off_rounded,
            title: 'مشكلة في الاتصال',
            message: 'اتأكد من الإنترنت وافتح البرنامج تاني.\n${f.error}',
          );
        }
        return StreamBuilder<AppUser?>(
          stream: Data.watchMe(),
          builder: (context, s) {
            if (!s.hasData && s.connectionState == ConnectionState.waiting) return const Splash();
            final me = s.data;
            if (me == null) {
              return const StatusScreen(
                icon: Icons.hourglass_top_rounded,
                title: 'في انتظار الموافقة',
                message: 'حسابك محتاج موافقة الإدارة. اقفل البرنامج وافتحه تاني بعد شوية.',
              );
            }
            if (me.isAdmin || me.status == 'approved') return HomeScreen(me: me);
            if (me.status == 'blocked') {
              return const StatusScreen(
                icon: Icons.block_rounded,
                title: 'الحساب موقوف',
                message: 'الحساب ده متوقف من الإدارة. لو فيه خطأ تواصل معانا.',
              );
            }
            return StatusScreen(
              icon: Icons.hourglass_top_rounded,
              title: 'أهلاً ${me.name} 👋',
              message:
                  'حسابك اتعمل بنجاح وفي انتظار موافقة الإدارة.\nأول ما يتفعّل هتدخل على طول من غير ما تعمل حاجة.',
            );
          },
        );
      },
    );
  }
}

class Splash extends StatelessWidget {
  const Splash({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 96),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
