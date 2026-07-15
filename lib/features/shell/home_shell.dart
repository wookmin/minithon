import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/brand_logo.dart';

/// 하단 5탭 컨테이너. 상단엔 브랜드 워드마크 + 알림(분석 기록) · 분석 시작 버튼.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: _ProductHeader(
          currentIndex: navigationShell.currentIndex,
          onAdd: () => _showQuickActionSheet(context),
          onAnalyze: () => context.push('/analysis-history'),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman_rounded),
            label: '심부름',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '마이',
          ),
        ],
      ),
    );
  }

  void _showQuickActionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => _QuickActionSheet(
        onSelected: (route) {
          Navigator.of(sheetContext).pop();
          if (route.startsWith('/general')) {
            context.go('/general');
          } else if (route == '/my') {
            context.go('/my');
          } else {
            context.push(route);
          }
        },
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({
    required this.currentIndex,
    required this.onAdd,
    required this.onAnalyze,
  });

  final int currentIndex;
  final VoidCallback onAdd;
  final VoidCallback onAnalyze;

  String get _sectionLabel {
    switch (currentIndex) {
      case 0:
        return '지역 심부름';
      case 1:
        return '홈';
      case 2:
        return '마이';
      default:
        return '홈';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    return Material(
      color: scheme.surface,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Row(
            children: [
              const _BrandIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '똥강아지',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _sectionLabel,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: '알림',
                onTap: onAnalyze,
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.add_rounded,
                tooltip: '추가',
                isEmphasis: true,
                onTap: onAdd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    return const BrandLogo(size: 42);
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isEmphasis = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isEmphasis
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final foreground = isEmphasis ? scheme.onPrimary : scheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: foreground, size: 22),
          ),
        ),
      ),
    );
  }
}

class _QuickActionSheet extends StatelessWidget {
  const _QuickActionSheet({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('무엇을 시작할까요?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '자주 쓰는 작업을 바로 열 수 있어요.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 18),
          _QuickActionTile(
            icon: Icons.graphic_eq_rounded,
            title: '녹음 파일 분석',
            subtitle: '통화 녹음을 STT와 Gemini로 확인',
            onTap: () => onSelected('/call-analysis'),
          ),
          _QuickActionTile(
            icon: Icons.settings_voice_rounded,
            title: '녹음 연결 설정',
            subtitle: '자동녹음·파일 선택·폴더 스캔 관리',
            onTap: () => onSelected('/recording-setup'),
          ),
          _QuickActionTile(
            icon: Icons.person_add_alt_1_rounded,
            title: '돌봄자 관리',
            subtitle: '부모님 정보와 자주 가는 병원 수정',
            onTap: () => onSelected('/my'),
          ),
          _QuickActionTile(
            icon: Icons.campaign_rounded,
            title: '심부름 요청',
            subtitle: '지역 도움 요청 화면으로 이동',
            onTap: () => onSelected('/general'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.surface),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.surface),
                ),
                child: Icon(icon, color: scheme.primary, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
