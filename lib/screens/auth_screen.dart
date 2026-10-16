import 'package:flutter/material.dart';

import '../config.dart';
import '../services/data.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _register = false;
  bool _busy = false;
  bool _hide = true;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.isEmpty || (_register && _name.text.trim().isEmpty)) {
      toast(context, 'كمّل البيانات الأول', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      if (_register) {
        await Data.register(_name.text, email, pass);
      } else {
        await Data.signIn(email, pass);
      }
    } catch (e) {
      if (mounted) toast(context, Data.authError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      toast(context, 'اكتب الإيميل الأول', error: true);
      return;
    }
    try {
      await Data.resetPassword(email);
      if (mounted) toast(context, 'بعتنالك رابط تغيير الباسورد على الإيميل');
    } catch (e) {
      if (mounted) toast(context, Data.authError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(size: 92)),
                const SizedBox(height: 18),
                const Text(kAppName,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('اتكلم إنجليزي مع شخصية بالذكاء الاصطناعي\nكأنك في مكالمة فيديو',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.6)),
                const SizedBox(height: 32),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('تسجيل دخول')),
                    ButtonSegment(value: true, label: Text('حساب جديد')),
                  ],
                  selected: {_register},
                  onSelectionChanged: (s) => setState(() => _register = s.first),
                ),
                const SizedBox(height: 20),
                if (_register) ...[
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'الاسم', prefixIcon: Icon(Icons.person_outline_rounded)),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'الإيميل', prefixIcon: Icon(Icons.alternate_email_rounded)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pass,
                  obscureText: _hide,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'الباسورد',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_hide ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Text(_register ? 'إنشاء الحساب' : 'دخول'),
                ),
                if (!_register)
                  TextButton(onPressed: _forgot, child: const Text('نسيت الباسورد؟')),
                if (_register)
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text(
                      'بعد التسجيل، الحساب بيتفعّل بعد موافقة الإدارة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
