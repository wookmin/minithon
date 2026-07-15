import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../recording/analysis_setup_prompt.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipients = ref.watch(careRecipientsProvider);
    final schedules = ref.watch(careSchedulesProvider);
    final setup = ref.watch(recordingSetupProvider).asData?.value;

    final uidReady = ref.watch(currentUidProvider) != null;
    final hasRecipient = recipients.asData?.value.isNotEmpty ?? false;
    final noRecipient = uidReady && (recipients.asData?.value.isEmpty ?? false);

    if (noRecipient && !ref.watch(onboardingPromptedProvider)) {
      // 대상자가 없으면 온보딩 우선.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(onboardingPromptedProvider.notifier).markPrompted();
        context.push('/onboarding');
      });
    } else if (uidReady &&
        hasRecipient &&
        setup != null &&
        !setup.backgroundDetectionEnabled &&
        !ref.watch(analysisSetupPromptedProvider)) {
      // 대상자는 있는데 자동 분석이 꺼져 있으면 세션 1회 설정을 유도.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(analysisSetupPromptedProvider.notifier).markPrompted();
        showAnalysisSetupSheet(context, ref);
      });
    }

    final recipientName = recipients.asData?.value.isNotEmpty ?? false
        ? recipients.asData!.value.first.name
        : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        recipients.when(
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _AddParentCard(
                    onTap: () => context.push('/onboarding'),
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: _LoadingCard(height: 96),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _AddParentCard(onTap: () => context.push('/onboarding')),
          ),
        ),
        const _SectionTitle(
          title: '오늘 확인할 일정',
          subtitle: '예약과 요청을 시간순으로 정리했어요',
        ),
        const SizedBox(height: 12),
        _ScheduleList(schedules: schedules, recipientName: recipientName),
        const SizedBox(height: 20),
        const _WelfareBanner(),
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

class _WelfareBanner extends StatelessWidget {
  const _WelfareBanner();

  static final Uri _welfareUri = Uri.parse('https://www.bokjiro.go.kr');

  Future<void> _open(BuildContext context) async {
    final opened = await launchUrl(
      _welfareUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('복지로 사이트를 열지 못했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    return Material(
      color: c.professionalSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.surface),
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: scheme.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '복지 한눈에 모아보기',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '부모님께 맞는 지원 제도를 공식 사이트에서 확인해보세요.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: c.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, color: scheme.primary, size: 21),
            ],
          ),
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

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({required this.schedules, required this.recipientName});

  final List<CareSchedule> schedules;
  final String recipientName;

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Text(
          '예정된 일정이 없어요.\n통화 분석이나 요청이 생기면 여기에 표시돼요.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < schedules.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _ScheduleCard(schedule: schedules[i], recipientName: recipientName),
        ],
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.recipientName});

  final CareSchedule schedule;
  final String recipientName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _scheduleColor(context, schedule.category);
    final parts = schedule.dateTimeLabel.split(' ');
    final day = parts.isNotEmpty ? parts.first : '';
    final time = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final who = recipientName.isEmpty ? '' : '$recipientName 님 · ';

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(width: 1, color: c.hairline),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    schedule.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$who${schedule.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _StatusPill(label: schedule.status, color: color),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: c.textSecondary,
            ),
          ],
        ),
      ),
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
            label: visual.label,
            title: record.reason.isEmpty ? visual.tagline : record.reason,
            meta: record.relativeTime(now),
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
    required this.label,
    required this.title,
    required this.meta,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  final String label;
  final String title;
  final String meta;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 180,
      child: SoftCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.28,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w300,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '바로 확인 →',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ],
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
