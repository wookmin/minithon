import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase/firebase_providers.dart';
import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/soft_card.dart';
import '../analysis/analysis_history_providers.dart';
import '../analysis/analysis_record.dart';
import '../business/business_providers.dart';
import '../business/local_business.dart';
import '../care/care_providers.dart';
import '../classification/need_category.dart';
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
          title: '최근 통화 도움',
          subtitle: '통화에서 발견한 니즈에 맞는 업체를 추천해요',
        ),
        const SizedBox(height: 12),
        const _RecommendationStrip(),
      ],
    );
  }
}

/// 최근 통화 니즈에 맞는 지역 업체를 추천한다.
class _RecommendationStrip extends ConsumerWidget {
  const _RecommendationStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(analysisHistoryProvider);
    final all = ref.watch(localBusinessesProvider);

    return history.when(
      data: (records) {
        final needs = records
            .where((r) => r.categories.any((c) => c != NeedCategory.none))
            .take(3)
            .toList();
        if (needs.isEmpty) return const _EmptyReco();
        return Column(
          children: [
            for (final record in needs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecoCard(
                  record: record,
                  business: _pick(all, record),
                ),
              ),
          ],
        );
      },
      loading: () => const _LoadingCard(height: 84),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  LocalBusiness? _pick(List<LocalBusiness> all, AnalysisRecord record) {
    for (final category in record.categories) {
      final biz = businessCategoryForNeed(
        category,
        serviceType: record.serviceType,
      );
      if (biz == null) continue;
      final matched = matchBusinesses(
        all: all,
        region: record.recipientRegion,
        category: biz,
      );
      if (matched.isNotEmpty) return matched.first;
    }
    return null;
  }
}

class _RecoCard extends ConsumerWidget {
  const _RecoCard({required this.record, required this.business});

  final AnalysisRecord record;
  final LocalBusiness? business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final b = business;
    return SoftCard(
      onTap: () {
        ref
            .read(selectedBusinessCategoryProvider.notifier)
            .select(business?.category ?? '전체');
        context.go('/general');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.record_voice_over_outlined,
                size: 18,
                color: c.general,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (b != null)
            Row(
              children: [
                Icon(Icons.storefront_rounded, size: 16, color: c.general),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${b.name} · ${b.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: c.general,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '연결 →',
                  style: text.bodySmall?.copyWith(
                    color: c.general,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            Text(
              '맞는 업체를 찾고 있어요. 해주세요에서 직접 둘러볼 수 있어요.',
              style: text.bodySmall?.copyWith(color: c.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _EmptyReco extends StatelessWidget {
  const _EmptyReco();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SoftCard(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            Icons.record_voice_over_outlined,
            color: c.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '아직 분석된 통화가 없어요. 부모님과 통화하면 필요한 도움을 찾아 업체를 추천해드려요.',
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
