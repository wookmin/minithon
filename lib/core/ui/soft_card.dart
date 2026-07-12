import 'package:flutter/material.dart';

import '../theme/app_colors_x.dart';
import '../theme/app_shape.dart';

/// 라운드 + 소프트 섀도 카드. 앱 전체 카드 컨테이너 표준.
/// 라이트에선 그림자로, 다크에선 헤어라인으로 표면을 띄운다.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: isDark ? Border.all(color: context.colors.hairline) : null,
        boxShadow: softCardShadow(scheme.brightness),
      ),
      child: Material(
        color: color ?? scheme.surface,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// 아이콘을 감싸는 라운드 타일 (소프트 배경 + 컬러 아이콘).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 48,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.surface),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
