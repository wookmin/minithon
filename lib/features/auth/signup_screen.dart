import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors_x.dart';
import '../care/care_models.dart';
import '../care/care_providers.dart';
import 'auth_providers.dart';
import 'auth_repository.dart';
import 'auth_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signup() async {
    if (_busy) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _snack('이름, 이메일, 비밀번호를 모두 입력해주세요.');
      return;
    }
    if (password.length < 6) {
      _snack('비밀번호는 6자 이상으로 입력해주세요.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(email: email, password: password, name: name);
      await ref
          .read(myProfileProvider.notifier)
          .save(MyProfile(name: name, phoneNumber: ''));
      // 가입 직후엔 부모님 등록 온보딩으로.
      if (mounted) context.go('/onboarding');
    } on Object catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _snack(authErrorMessage(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            AuthBackHeader(
              title: '회원가입',
              onBack: _busy ? null : () => context.go('/login'),
            ),
            const SizedBox(height: 24),
            Text(
              '똥강아지 시작하기',
              style: text.headlineMedium?.copyWith(
                fontSize: 26,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '부모님을 함께 챙길 계정을 만들어요.',
              style: text.bodyMedium?.copyWith(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '이름',
                hintText: '홍길동',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'name@example.com',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _signup(),
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '6자 이상',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _signup,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('가입하고 시작하기'),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '가입 시 서비스 이용약관에 동의하게 됩니다.',
                style: TextStyle(color: c.textSecondary, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
