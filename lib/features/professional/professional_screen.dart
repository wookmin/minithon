import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/avatars.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/soft_card.dart';
import '../care/care_models.dart';
import '../care/care_providers.dart';

class ProfessionalScreen extends ConsumerWidget {
  const ProfessionalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experts = ref.watch(careExpertsProvider);
    final accent = context.colors.professional;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        ScreenHeader(
          eyebrow: '전문 돌봄',
          title: '방문 전문가',
          subtitle: '사회복지사, 요양보호사, 병원 동행 전문가를 바로 확인하세요.',
          accent: accent,
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _RoleChip(label: '전체', selected: true, accent: accent),
              _RoleChip(label: '사회복지사', accent: accent),
              _RoleChip(label: '요양보호사', accent: accent),
              _RoleChip(label: '병원동행', accent: accent),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final expert in experts)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _ExpertCard(expert: expert, accent: accent),
          ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.accent,
    this.selected = false,
  });

  final String label;
  final Color accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? accent : context.colors.hairline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ExpertCard extends StatelessWidget {
  const _ExpertCard({required this.expert, required this.accent});

  final CareExpert expert;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientAvatar(label: expert.name, color: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            expert.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (expert.isCertified) ...[
                          const SizedBox(width: 6),
                          _CertifiedBadge(accent: accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      expert.role,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: accent),
                        const SizedBox(width: 3),
                        Text(
                          expert.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          ' (${expert.reviewCount})',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (expert.rehireRate > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '재이용 ${expert.rehireRate}%',
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoLine(
            icon: Icons.place_outlined,
            text: '${expert.region} · ${expert.career}',
          ),
          const SizedBox(height: 6),
          _InfoLine(icon: Icons.schedule_rounded, text: expert.availableTime),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showMessage(context, '상담 가능 시간을 확인하고 있어요.'),
                  child: const Text('상담 요청'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => _showMessage(context, '방문 예약 요청을 준비하고 있어요.'),
                  child: const Text('방문 예약'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CertifiedBadge extends StatelessWidget {
  const _CertifiedBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 13, color: accent),
          const SizedBox(width: 3),
          Text(
            '인증',
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: c.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: c.textSecondary, fontSize: 13.5),
          ),
        ),
      ],
    );
  }
}
