import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors_x.dart';
import 'auth_prefs.dart';
import 'auth_providers.dart';
import 'auth_repository.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _prefs = AuthPrefs();
  bool _busy = false;
  bool _rememberEmail = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final saved = await _prefs.readSavedEmail();
    if (saved != null && mounted) {
      setState(() {
        _email.text = saved;
        _rememberEmail = true;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      // 라우팅은 게이트가, 대상자 미등록 시 온보딩 유도는 홈이 담당한다.
      if (mounted) context.go(_destinationAfterAuth());
    } on Object catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }
  }

  void _loginWithEmail() {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')));
      return;
    }
    _run(() async {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);
      if (_rememberEmail) {
        await _prefs.saveEmail(email);
      } else {
        await _prefs.clearSavedEmail();
      }
    });
  }

  Future<void> _openPasswordReset() async {
    final sent = await showPasswordResetSheet(
      context,
      repository: ref.read(authRepositoryProvider),
      initialEmail: _email.text.trim(),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('재설정 링크를 보냈어요. 메일함을 확인해주세요.')));
    }
  }

  String _destinationAfterAuth() {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from == null || from.isEmpty || from == '/login') return '/home';
    return from;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          children: [
            const AuthBrandMark(),
            const SizedBox(height: 28),
            Text(
              '다시 오셨네요',
              style: text.headlineMedium?.copyWith(
                fontSize: 28,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '부모님 곁을 지키러 로그인해요.',
              style: text.bodyMedium?.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 28),
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
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _loginWithEmail(),
              decoration: const InputDecoration(labelText: '비밀번호'),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _busy
                      ? null
                      : () => setState(() => _rememberEmail = !_rememberEmail),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _rememberEmail,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: _busy
                              ? null
                              : (v) =>
                                    setState(() => _rememberEmail = v ?? false),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '이메일 저장',
                          style: text.bodyMedium?.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _openPasswordReset,
                  child: const Text('비밀번호를 잊으셨나요?'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _loginWithEmail,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('로그인'),
            ),
            const SizedBox(height: 12),
            const AuthDivider(),
            const SizedBox(height: 12),
            GoogleAuthButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => ref.read(authRepositoryProvider).signInWithGoogle(),
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '아직 계정이 없으신가요?',
                  style: TextStyle(color: c.textSecondary, fontSize: 14),
                ),
                TextButton(
                  onPressed: _busy ? null : () => context.push('/signup'),
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
