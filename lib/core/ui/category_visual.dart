import 'package:flutter/material.dart';

import '../../features/classification/need_category.dart';
import '../theme/app_colors_x.dart';

/// 카테고리별 색상·아이콘·라벨을 한 곳에서 매핑. (칩·아이콘 타일·결과 카드에서 재사용)
class CategoryVisual {
  const CategoryVisual({
    required this.color,
    required this.soft,
    required this.icon,
    required this.label,
    required this.tagline,
  });

  final Color color;
  final Color soft;
  final IconData icon;
  final String label;
  final String tagline;
}

CategoryVisual categoryVisual(BuildContext context, NeedCategory category) {
  final c = context.colors;
  switch (category) {
    case NeedCategory.hospital:
      return CategoryVisual(
        color: c.health,
        soft: c.healthSoft,
        icon: Icons.favorite_rounded,
        label: '건강',
        tagline: '병원 · 진료가 필요해요',
      );
    case NeedCategory.general:
      return CategoryVisual(
        color: c.general,
        soft: c.generalSoft,
        icon: Icons.handyman_rounded,
        label: '생활',
        tagline: '생활 도움이 필요해요',
      );
    case NeedCategory.professional:
      return CategoryVisual(
        color: c.professional,
        soft: c.professionalSoft,
        icon: Icons.diversity_1_rounded,
        label: '전문 돌봄',
        tagline: '전문가 손길이 필요해요',
      );
    case NeedCategory.none:
      return CategoryVisual(
        color: c.textSecondary,
        soft: c.hairline,
        icon: Icons.check_circle_rounded,
        label: '해당 없음',
        tagline: '특별한 니즈가 없어요',
      );
  }
}
