import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase/firebase_providers.dart';
import '../../core/notifications/notification_payload.dart';
import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/category_visual.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/soft_card.dart';
import '../analysis/analysis_history_providers.dart';
import '../care/care_models.dart';
import '../care/care_providers.dart';
import '../onboarding/onboarding_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipients = ref.watch(careRecipientsProvider);
    final recording = ref.watch(recordingSetupProvider);
    final schedules = ref.watch(careSchedulesProvider);

    // 로그인 uid가 확정되고, 대상자가 하나도 없으면 세션 최초 1회 온보딩을 띄운다.
    final uidReady = ref.watch(currentUidProvider) != null;
    final noRecipient = uidReady && (recipients.asData?.value.isEmpty ?? false);
    if (noRecipient && !ref.watch(onboardingPromptedProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(onboardingPromptedProvider.notifier).markPrompted();
        context.push('/onboarding');
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        recipients.when(
          data: (items) => items.isEmpty
              ? _AddParentCard(onTap: () => context.push('/onboarding'))
              : _CareHero(recipient: items.first, schedules: schedules),
          loading: () => const _LoadingCard(height: 184),
          error: (_, _) =>
              _AddParentCard(onTap: () => context.push('/onboarding')),
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
        const _DetectedNeedStrip(),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/analysis-history'),
            child: const Text('전체 기록 보기'),
          ),
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
    final c = context.colors;
    final needsReview = schedules.where((s) => s.status.contains('필요')).length;
    final nextSchedule = schedules.isEmpty ? null : schedules.first;
    final recipientMeta = [
      recipient.relationship,
      if (recipient.favoriteHospital.isNotEmpty) recipient.favoriteHospital,
    ].join(' · ');
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  recipient.name.characters.first,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${recipient.name} 님',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recipientMeta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (needsReview > 0)
                _StatusPill(
                  label: '확인 필요 $needsReview건',
                  color: scheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '오늘의 케어 브리핑',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 24, height: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            needsReview > 0 ? '확인이 필요한 일정이 있어요.' : '급하게 확인할 내용은 없어요.',
            style: TextStyle(
              color: needsReview > 0 ? scheme.primary : c.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (nextSchedule != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.surface),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    color: _scheduleColor(context, nextSchedule.category),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextSchedule.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${nextSchedule.dateTimeLabel} · ${nextSchedule.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SoftMetric(
                  title: '오늘 일정',
                  value: '${schedules.length}건',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SoftMetric(title: '확인 필요', value: '$needsReview건'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 16, color: c.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  recipient.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
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
    if (schedules.isEmpty) {
      return SoftCard(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Icon(
              Icons.event_available_rounded,
              color: context.colors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '예정된 일정이 없어요.\n통화 분석이나 요청이 생기면 여기에 표시돼요.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
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

class _DetectedNeedStrip extends ConsumerWidget {
  const _DetectedNeedStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(analysisHistoryProvider);
    final records = (history.asData?.value ?? const [])
        .where((record) => record.hasActionableNeed)
        .take(6)
        .toList();

    if (records.isEmpty) {
      return SoftCard(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: context.colors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '아직 확인이 필요한 통화가 없어요.\n통화를 분석하면 여기에 모여요.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: records.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final record = records[index];
          final visual = categoryVisual(context, record.primaryCategory);
          final route = routeForCategory(record.primaryCategory);
          return _DetectedNeedCard(
            title: record.reason.isEmpty ? visual.tagline : record.reason,
            subtitle: '${visual.label} · ${record.relativeTime(now)}',
            icon: visual.icon,
            color: visual.color,
            soft: visual.soft,
            onTap: route == null ? () {} : () => context.go(route),
          );
        },
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddParentCard extends StatelessWidget {
  const _AddParentCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.surface),
            ),
            child: Icon(Icons.person_add_alt_1_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '부모님을 등록해주세요',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '통화 분석과 병원 검색을 시작할 수 있어요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.textSecondary,
          ),
        ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Skeleton(width: 44, height: 44, radius: AppRadius.surface),
                SizedBox(width: 12),
                Skeleton(width: 120, height: 15, radius: AppRadius.pill),
              ],
            ),
            const SizedBox(height: 16),
            const Skeleton(
              width: double.infinity,
              height: 13,
              radius: AppRadius.pill,
            ),
          ],
        ),
      ),
    );
  }
}
