import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.spa_rounded, color: scheme.primary, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                '멀리 있어도\n마음은 가까이',
                style: text.headlineMedium?.copyWith(
                  fontSize: 32,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '부모님과의 통화를 살펴 병원·생활 도움·전문 돌봄이 필요한 순간을 대신 알아챕니다.',
                style: text.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
              ),
              const Spacer(),
              const _TrustRow(),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('시작하기'),
              ),
              const SizedBox(height: 12),
              Text(
                '지금은 체험 계정으로 바로 시작합니다.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = [
      (Icons.favorite_rounded, '건강', c.health, c.healthSoft),
      (Icons.handyman_rounded, '생활', c.general, c.generalSoft),
      (Icons.diversity_1_rounded, '전문 돌봄', c.professional, c.professionalSoft),
    ];
    return Row(
      children: [
        for (final (icon, label, color, soft) in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(AppRadius.surface),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
