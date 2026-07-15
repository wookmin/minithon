import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_providers.dart';
import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/action_sheet.dart';
import '../../core/ui/avatars.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/soft_card.dart';
import '../care/care_models.dart';
import '../care/care_providers.dart';
import '../care/region_matcher.dart';

class GeneralScreen extends ConsumerStatefulWidget {
  const GeneralScreen({super.key});

  @override
  ConsumerState<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends ConsumerState<GeneralScreen> {
  static const _filters = ['전체', '장보기', '수리', '병원 동행', '교통'];
  String _filter = '전체';

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(myRegionErrandsProvider);
    final myAddress = ref.watch(myProfileProvider).asData?.value.address ?? '';
    final myRegion = regionKey(myAddress);
    final accent = context.colors.general;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        ScreenHeader(
          eyebrow: myRegion.isEmpty ? '생활' : myRegion,
          title: '내 지역 도움 요청',
          subtitle: myRegion.isEmpty
              ? '마이에서 내 지역을 등록하면 이웃의 도움 요청을 볼 수 있어요.'
              : '$myRegion 이웃의 도움 요청이에요. 도울 수 있는 요청에 지원해보세요.',
          accent: accent,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (final f in _filters)
                _FilterChip(
                  label: f,
                  selected: f == _filter,
                  onTap: () => setState(() => _filter = f),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        requests.when(
          data: (all) {
            final errands = _filter == '전체'
                ? all
                : all.where((e) => e.category == _filter).toList();
            if (errands.isEmpty) {
              return _EmptyState(
                title: _filter == '전체'
                    ? '등록된 요청이 없어요'
                    : "'$_filter' 요청이 아직 없어요",
                message: '요청이 올라오면 이곳에서 확인하고 지원할 수 있어요.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 20, 2),
                  child: Text(
                    '${errands.length}개의 요청',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final errand in errands)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: _ErrandCard(errand: errand, accent: accent),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                _ErrandSkeleton(),
                SizedBox(height: 12),
                _ErrandSkeleton(),
                SizedBox(height: 12),
                _ErrandSkeleton(),
              ],
            ),
          ),
          error: (_, _) => const _EmptyState(
            title: '요청을 불러오지 못했어요',
            message: '잠시 후 다시 시도해주세요.',
          ),
        ),
      ],
    );
  }
}

class _ErrandSkeleton extends StatelessWidget {
  const _ErrandSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Skeleton(width: 44, height: 44, radius: AppRadius.surface),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 86, height: 18, radius: AppRadius.pill),
                    SizedBox(height: 8),
                    Skeleton(width: 160, height: 16, radius: AppRadius.pill),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Skeleton(width: double.infinity, height: 14, radius: AppRadius.pill),
          SizedBox(height: 8),
          Skeleton(width: 210, height: 14, radius: AppRadius.pill),
          SizedBox(height: 16),
          Skeleton(
            width: double.infinity,
            height: 46,
            radius: AppRadius.control,
          ),
        ],
      ),
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
            Icon(Icons.inbox_rounded, color: c.textSecondary, size: 34),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
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
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  final m = time.month.toString().padLeft(2, '0');
  final d = time.day.toString().padLeft(2, '0');
  return '${time.year}.$m.$d';
}

class _ErrandCard extends ConsumerWidget {
  const _ErrandCard({required this.errand, required this.accent});

  final ErrandRequest errand;
  final Color accent;

  Future<void> _apply(BuildContext context, WidgetRef ref, String uid) async {
    try {
      await ref.read(errandRequestsProvider.notifier).apply(errand.id, uid);
      if (!context.mounted) return;
      await showConfirmSheet(
        context,
        icon: Icons.volunteer_activism_rounded,
        title: '지원했어요',
        message: '요청자에게 지원 의사를 전달했어요.\n연결되면 알림으로 알려드릴게요.',
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('지원에 실패했어요. 잠시 후 다시 시도해주세요.')),
        );
    }
  }

  IconData get _icon {
    switch (errand.category) {
      case '장보기':
        return Icons.shopping_basket_rounded;
      case '수리':
        return Icons.build_rounded;
      case '병원 동행':
        return Icons.directions_walk_rounded;
      case '교통':
        return Icons.directions_car_rounded;
      default:
        return Icons.volunteer_activism_rounded;
    }
  }

  bool get _open => errand.status.isEmpty || errand.status == '모집중';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final uid = ref.watch(currentUidProvider);
    final applied = uid != null && errand.hasApplied(uid);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon: _icon, color: accent, background: c.generalSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Badge(
                          label: errand.category,
                          color: accent,
                          soft: c.generalSoft,
                        ),
                        if (errand.createdAt != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _timeAgo(errand.createdAt!),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        _StatusPill(
                          open: _open,
                          label: _open ? '모집중' : errand.status,
                          accent: accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errand.title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            errand.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(
              color: c.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 16, color: c.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${errand.region} · ${errand.distance}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
              ),
              const Spacer(),
              if (errand.helperCount > 0) ...[
                AvatarStack(count: errand.helperCount, diameter: 24),
                const SizedBox(width: 6),
              ],
              Text(
                '지원 ${errand.helperCount}명',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (errand.requesterName.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: c.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${errand.requesterName} 님 요청',
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: (_open && !applied && uid != null)
                  ? () => _apply(context, ref, uid)
                  : null,
              icon: Icon(
                applied
                    ? Icons.check_rounded
                    : Icons.volunteer_activism_rounded,
                size: 18,
              ),
              label: Text(applied ? '지원함' : (_open ? '지원하기' : '마감된 요청')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.open,
    required this.label,
    required this.accent,
  });

  final bool open;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final color = open ? accent : context.colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.soft});

  final String label;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
