import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/soft_card.dart';
import '../care/care_models.dart';
import '../care/care_providers.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipients = ref.watch(careRecipientsProvider);
    final recording = ref.watch(recordingSetupProvider);
    final schedules = ref.watch(careSchedulesProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        recipients.when(
          data: (items) => _CareHero(recipient: items.first, schedules: schedules),
          loading: () => const _LoadingCard(height: 184),
          error: (_, _) =>
              _CareHero(recipient: defaultCareRecipients.first, schedules: schedules),
        ),
        const SizedBox(height: 14),
        recording.when(
          data: (state) => _AnalysisCard(state: state),
          loading: () => const _LoadingCard(height: 88),
          error: (_, _) =>
              const _AnalysisCard(state: RecordingSetupState.incomplete()),
        ),
        const SizedBox(height: 22),
        _QuickActions(
          onHospital: () => context.go('/hospital'),
          onErrand: () => context.go('/general'),
          onExpert: () => context.go('/professional'),
        ),
        const SizedBox(height: 26),
        const _SectionTitle(
          title: '오늘 확인할 일정',
          subtitle: '예약과 요청을 시간순으로 정리했어요',
        ),
        const SizedBox(height: 12),
        _TimelineCard(schedules: schedules),
        const SizedBox(height: 26),
        const _SectionTitle(title: '최근 통화 분석', subtitle: '확인이 필요한 내용만 추렸어요'),
        const SizedBox(height: 12),
        _DetectedNeedStrip(
          onHospital: () => context.go('/hospital'),
          onErrand: () => context.go('/general'),
        ),
      ],
    );
  }
}

class _CareHero extends StatelessWidget {
  const _CareHero({required this.recipient, required this.schedules});

  final CareRecipient recipient;
  final List<CareSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final needsReview =
        schedules.where((s) => s.status.contains('필요')).length;
    return SoftCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.surface),
                ),
                child: Icon(Icons.pets_rounded, color: scheme.primary),
              ),
              const Spacer(),
              if (needsReview > 0)
                _StatusPill(label: '확인 필요 $needsReview건', color: scheme.primary),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${recipient.name} 님\n케어 현황',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 24, height: 1.25),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 16,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  recipient.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SoftMetric(title: '오늘 일정', value: '${schedules.length}건'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SoftMetric(title: '확인 필요', value: '$needsReview건'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoftMetric extends StatelessWidget {
  const _SoftMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.state});

  final RecordingSetupState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = state.isCompleted;
    final color = scheme.primary;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/recording-setup'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.auto_awesome_rounded,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active ? '자동 분석 켜짐' : '자동 분석 설정 필요',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      active
                          ? '통화 후 확인할 내용이 있으면 알려드려요.'
                          : '통화 녹음 설정을 한 번만 확인해주세요.',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onHospital,
    required this.onErrand,
    required this.onExpert,
  });

  final VoidCallback onHospital;
  final VoidCallback onErrand;
  final VoidCallback onExpert;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        _ActionButton(
          icon: Icons.favorite_rounded,
          label: '건강',
          color: c.health,
          soft: c.healthSoft,
          onTap: onHospital,
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.handyman_rounded,
          label: '심부름',
          color: c.general,
          soft: c.generalSoft,
          onTap: onErrand,
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.diversity_1_rounded,
          label: '전문가',
          color: c.professional,
          soft: c.professionalSoft,
          onTap: onExpert,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 18),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(AppRadius.surface),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 11),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

Color _scheduleColor(BuildContext context, String category) {
  final c = context.colors;
  switch (category) {
    case '병원':
      return c.health;
    case '심부름':
      return c.general;
    case '전문 돌봄':
      return c.professional;
    default:
      return Theme.of(context).colorScheme.primary;
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.schedules});

  final List<CareSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          for (var i = 0; i < schedules.length; i++)
            _TimelineRow(
              schedule: schedules[i],
              isLast: i == schedules.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.schedule, required this.isLast});

  final CareSchedule schedule;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _scheduleColor(context, schedule.category);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 11,
              height: 11,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(width: 2, height: 56, color: context.colors.hairline),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        schedule.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _StatusPill(label: schedule.status, color: color),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${schedule.dateTimeLabel} · ${schedule.location}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetectedNeedStrip extends StatelessWidget {
  const _DetectedNeedStrip({required this.onHospital, required this.onErrand});

  final VoidCallback onHospital;
  final VoidCallback onErrand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _DetectedNeedCard(
            title: '허리 통증 언급',
            subtitle: '병원 확인 필요',
            icon: Icons.favorite_rounded,
            color: c.health,
            soft: c.healthSoft,
            onTap: onHospital,
          ),
          const SizedBox(width: 12),
          _DetectedNeedCard(
            title: '전등 교체 요청',
            subtitle: '지원자 확인 가능',
            icon: Icons.lightbulb_rounded,
            color: c.general,
            soft: c.generalSoft,
            onTap: onErrand,
          ),
        ],
      ),
    );
  }
}

class _DetectedNeedCard extends StatelessWidget {
  const _DetectedNeedCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: SoftCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(AppRadius.surface),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 3),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
