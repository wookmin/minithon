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
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    '똥강아지',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 3),
              Text(
                '멀리 있어도\n똥강아지가 챙길게요',
                style: text.headlineMedium?.copyWith(
                  fontSize: 32,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '부모님과의 통화를 살펴,\n도움이 필요한 순간을 대신 알아챕니다.',
                style: text.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
              ),
              const Spacer(flex: 2),
              _ValueRow(
                icon: Icons.favorite_rounded,
                color: c.health,
                soft: c.healthSoft,
                title: '건강 신호를 놓치지 않아요',
                subtitle: '통화 속 아픈 곳·병원 얘기를 감지',
              ),
              const SizedBox(height: 18),
              _ValueRow(
                icon: Icons.handyman_rounded,
                color: c.general,
                soft: c.generalSoft,
                title: '생활 도움을 연결해요',
                subtitle: '장보기·수리·이동을 이웃과 이어줘요',
              ),
              const SizedBox(height: 18),
              _ValueRow(
                icon: Icons.diversity_1_rounded,
                color: c.professional,
                soft: c.professionalSoft,
                title: '전문가를 바로 찾아드려요',
                subtitle: '요양보호사·사회복지사 매칭',
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('시작하기'),
              ),
              const SizedBox(height: 14),
              Text(
                '가입 없이 체험 계정으로 바로 시작해요',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.color,
    required this.soft,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final Color soft;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(AppRadius.surface),
          ),
          child: Icon(icon, color: color, size: 23),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13.5, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
