import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase/firebase_providers.dart';
import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/soft_card.dart';
import '../care/care_models.dart';
import '../care/care_providers.dart';
import '../onboarding/onboarding_screen.dart';
import '../recording/analysis_setup_prompt.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipients = ref.watch(careRecipientsProvider);
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
          title: '내가 올린 도움 요청',
          subtitle: '부모님 지역에 올라간 요청과 지원 현황이에요',
        ),
        const SizedBox(height: 12),
        const _MyPostedStrip(),
      ],
    );
  }
}

/// 내가 올린(부모님 지역) 도움 요청과 지원 현황 미리보기.
class _MyPostedStrip extends ConsumerWidget {
  const _MyPostedStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posted = ref.watch(myPostedErrandsProvider);
    return posted.when(
      data: (items) => items.isEmpty
          ? const _EmptyPostedCard()
          : Column(
              children: [
                for (final errand in items.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PostedCard(errand: errand),
                  ),
              ],
            ),
      loading: () => const _LoadingCard(height: 84),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _PostedCard extends StatelessWidget {
  const _PostedCard({required this.errand});

  final ErrandRequest errand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  errand.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusPill(
                label: '지원 ${errand.helperCount}명',
                color: errand.helperCount > 0 ? c.general : c.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 15, color: c.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${errand.category} · ${errand.region}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPostedCard extends StatelessWidget {
  const _EmptyPostedCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SoftCard(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.campaign_outlined, color: c.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '아직 올린 요청이 없어요. 부모님과 통화가 분석되면 필요한 도움이 자동으로 올라와요.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
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
