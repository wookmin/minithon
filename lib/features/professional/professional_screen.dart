import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/action_sheet.dart';
import '../../core/ui/avatars.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/soft_card.dart';
import '../care/care_models.dart';
import '../care/care_providers.dart';

class ProfessionalScreen extends ConsumerStatefulWidget {
  const ProfessionalScreen({super.key});

  @override
  ConsumerState<ProfessionalScreen> createState() => _ProfessionalScreenState();
}

class _ProfessionalScreenState extends ConsumerState<ProfessionalScreen> {
  static const _roles = ['전체', '사회복지사', '요양보호사', '병원동행'];
  String _role = '전체';

  @override
  Widget build(BuildContext context) {
    final expertsState = ref.watch(careExpertsProvider);
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
              for (final r in _roles)
                _RoleChip(
                  label: r,
                  accent: accent,
                  selected: r == _role,
                  onTap: () => setState(() => _role = r),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        expertsState.when(
          data: (all) {
            final experts = _role == '전체'
                ? all
                : all
                      .where((e) => e.role.replaceAll(' ', '').contains(_role))
                      .toList();
            if (experts.isEmpty) {
              return _EmptyState(
                title: _role == '전체' ? '등록된 전문가가 없어요' : "'$_role' 전문가가 아직 없어요",
                message: '방문 가능한 전문가가 등록되면 이곳에 표시돼요.',
              );
            }
            return Column(
              children: [
                for (final expert in experts)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _ExpertCard(expert: expert, accent: accent),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const _EmptyState(
            title: '전문가 목록을 불러오지 못했어요',
            message: '잠시 후 다시 시도해주세요.',
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: SoftCard(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          children: [
            Icon(Icons.groups_rounded, color: c.textSecondary, size: 34),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.accent,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
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
                  onPressed: () => showConfirmSheet(
                    context,
                    icon: Icons.chat_bubble_rounded,
                    title: '상담을 요청했어요',
                    message: '${expert.name} 님에게 상담 요청을 보냈어요.\n가능한 시간에 연락드릴게요.',
                  ),
                  child: const Text('상담 요청'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => showConfirmSheet(
                    context,
                    icon: Icons.event_available_rounded,
                    title: '방문 예약을 신청했어요',
                    message:
                        '${expert.name} 님과 방문 일정을 조율할게요.\n확정되면 알림으로 알려드릴게요.',
                  ),
                  child: const Text('방문 예약'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
