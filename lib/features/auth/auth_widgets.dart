import 'package:flutter/material.dart';

import '../../core/theme/app_colors_x.dart';

/// 로그인·회원가입 상단 브랜드 로고 + 워드마크.
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.pets_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Text(
          '똥강아지',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
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
