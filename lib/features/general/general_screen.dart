import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/action_sheet.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/soft_card.dart';
import '../business/business_providers.dart';
import '../business/local_business.dart';
import '../care/care_providers.dart';
import '../care/region_matcher.dart';

/// 해주세요 — 검색이 어려운 부모님을 대신해 지역 전문 업체를 연결한다.
class GeneralScreen extends ConsumerStatefulWidget {
  const GeneralScreen({super.key});

  @override
  ConsumerState<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends ConsumerState<GeneralScreen> {
  static const _filters = ['전체', '수리', '청소', '장보기', '병원 동행', '간병'];
  String _filter = '전체';
  int _recipientIndex = 0;

  @override
  Widget build(BuildContext context) {
    final recipients =
        ref.watch(careRecipientsProvider).asData?.value ?? const [];
    final index = recipients.isEmpty
        ? 0
        : _recipientIndex.clamp(0, recipients.length - 1);
    final parentAddress = recipients.isEmpty ? '' : recipients[index].address;
    final parentRegion = regionKey(parentAddress);
    final accent = context.colors.general;

    final all = ref.watch(localBusinessesProvider);
    final isDemo = ref.watch(businessesAreDemoProvider);
    final businesses = matchBusinesses(
      all: all,
      region: parentAddress,
      category: _filter == '전체' ? null : _filter,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        ScreenHeader(
          eyebrow: parentRegion.isEmpty ? '지역 상권' : parentRegion,
          title: '해주세요',
          subtitle: parentRegion.isEmpty
              ? '마이에서 부모님 지역을 등록하면 그 동네 전문 업체를 연결해드려요.'
              : '$parentRegion 전문 업체를 연결해드려요. 검색은 저희가 대신할게요.',
          accent: accent,
        ),
        if (recipients.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (var i = 0; i < recipients.length; i++)
                  _FilterChip(
                    label: recipients[i].name,
                    selected: i == index,
                    onTap: () => setState(() => _recipientIndex = i),
                  ),
              ],
            ),
          ),
        ],
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
        if (businesses.isEmpty)
          const _EmptyState(
            title: '연결할 업체가 없어요',
            message: '다른 카테고리를 선택하거나 잠시 후 다시 시도해주세요.',
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 20, 2),
            child: Text(
              '${businesses.length}곳 연결 가능',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final business in businesses)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: _BusinessCard(
                business: business,
                accent: accent,
                isDemo: isDemo,
              ),
            ),
        ],
      ],
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.business,
    required this.accent,
    required this.isDemo,
  });

  final LocalBusiness business;
  final Color accent;
  final bool isDemo;

  Future<void> _connect(BuildContext context) async {
    // 더미(시연) 업체는 실제 전화 대신 데모 안내만 한다. (오연결·오해 방지)
    if (isDemo) {
      await showConfirmSheet(
        context,
        icon: Icons.info_outline_rounded,
        title: '데모 업체예요',
        message: '실제 제휴 업체가 아니라 시연용이에요.\n정식 버전에서는 검증된 지역 업체로 바로 연결됩니다.',
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: business.phone.replaceAll(' ', ''));
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('전화 연결을 시작하지 못했어요.')));
    }
  }

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
              _Badge(label: business.category, color: accent, soft: c.generalSoft),
              if (isDemo) ...[
                const SizedBox(width: 6),
                _Badge(
                  label: '데모',
                  color: c.textSecondary,
                  soft: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ],
              const SizedBox(width: 8),
              Icon(Icons.star_rounded, size: 15, color: Colors.amber.shade600),
              const SizedBox(width: 2),
              Text(
                business.rating.toStringAsFixed(1),
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '연결 수수료 ${_won(business.feeWon)}',
                style: text.bodySmall?.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            business.name,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            business.description,
            style: text.bodyMedium?.copyWith(color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 15, color: c.textSecondary),
              const SizedBox(width: 4),
              Text(
                business.region,
                style: text.bodySmall?.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _connect(context),
              icon: const Icon(Icons.call_rounded, size: 18),
              label: const Text('전화 연결'),
            ),
          ),
        ],
      ),
    );
  }

  String _won(int value) {
    if (value <= 0) return '무료';
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '$buffer원';
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
            Icon(Icons.storefront_outlined, color: c.textSecondary, size: 34),
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
