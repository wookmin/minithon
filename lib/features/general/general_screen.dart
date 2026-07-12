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
    final all = ref.watch(errandRequestsProvider);
    final accent = context.colors.general;
    final errands = _filter == '전체'
        ? all
        : all.where((e) => e.category == _filter).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        ScreenHeader(
          eyebrow: '생활',
          title: '지역 심부름',
          subtitle: '가까운 생활 도움과 이동 요청을 확인하세요.',
          accent: accent,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FilledButton.icon(
            onPressed: () => showConfirmSheet(
              context,
              icon: Icons.campaign_rounded,
              title: '요청을 등록했어요',
              message: '가까운 이웃에게 도움 요청이 전달됐어요.\n지원자가 생기면 알려드릴게요.',
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('요청 올리기'),
          ),
        ),
        const SizedBox(height: 16),
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
        if (errands.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
            child: Text(
              "'$_filter' 요청이 아직 없어요",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          )
        else
          for (final errand in errands)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: _ErrandCard(errand: errand, accent: accent),
            ),
      ],
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
    final accent = context.colors.general;
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

class _ErrandCard extends StatelessWidget {
  const _ErrandCard({required this.errand, required this.accent});

  final ErrandRequest errand;
  final Color accent;

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
                        const Spacer(),
                        Text(
                          errand.status,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errand.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            errand.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 16, color: c.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${errand.region} · ${errand.distance}',
                style: TextStyle(color: c.textSecondary, fontSize: 13),
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
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => showConfirmSheet(
              context,
              icon: Icons.volunteer_activism_rounded,
              title: '지원했어요',
              message: '요청자에게 지원 의사를 전달했어요.\n연결되면 알림으로 알려드릴게요.',
            ),
            child: const Text('지원하기'),
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
