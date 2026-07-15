import 'package:flutter/material.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/ui/brand_logo.dart';
import 'auth_repository.dart';

/// 로그인·회원가입 상단 브랜드 로고 + 워드마크.
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BrandLogo(size: 40),
        const SizedBox(width: 10),
        Text(
          '해됴',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}

/// 뒤로가기 칩 + 제목. (회원가입 등 하위 인증 화면 상단)
class AuthBackHeader extends StatelessWidget {
  const AuthBackHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Material(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.chevron_left_rounded,
                color: scheme.onSurface,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// "또는" 구분선.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final line = Expanded(child: Divider(color: c.hairline, thickness: 1));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '또는',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
        ),
        line,
      ],
    );
  }
}

/// Google 계속하기 버튼.
class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFF4285F4),
          shape: BoxShape.circle,
        ),
        child: const Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
      label: const Text('Google로 계속하기'),
    );
  }
}

/// 비밀번호 재설정 바텀시트를 띄운다. 성공하면 true를 반환한다.
Future<bool?> showPasswordResetSheet(
  BuildContext context, {
  required AuthRepository repository,
  String? initialEmail,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _PasswordResetSheet(
      repository: repository,
      initialEmail: initialEmail,
    ),
  );
}

class _PasswordResetSheet extends StatefulWidget {
  const _PasswordResetSheet({required this.repository, this.initialEmail});

  final AuthRepository repository;
  final String? initialEmail;

  @override
  State<_PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<_PasswordResetSheet> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('이메일을 입력해주세요.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repository.sendPasswordReset(email);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 4, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '비밀번호 재설정',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '가입하신 이메일로 재설정 링크를 보내드려요.',
            style: text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: 'name@example.com',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('재설정 링크 보내기'),
          ),
        ],
      ),
    );
  }
}
