import 'package:flutter/material.dart';

/// 앱 고유 색상(카테고리 코딩·헤어라인 등). 테마와 함께 light/dark 전환된다.
@immutable
class AppColorsX extends ThemeExtension<AppColorsX> {
  const AppColorsX({
    required this.canvas,
    required this.hairline,
    required this.textSecondary,
    required this.health,
    required this.healthSoft,
    required this.general,
    required this.generalSoft,
    required this.professional,
    required this.professionalSoft,
  });

  final Color canvas;
  final Color hairline;
  final Color textSecondary;
  final Color health;
  final Color healthSoft;
  final Color general;
  final Color generalSoft;
  final Color professional;
  final Color professionalSoft;

  static const light = AppColorsX(
    canvas: Color(0xFFF2F3EE),
    hairline: Color(0xFFE7E8E2),
    textSecondary: Color(0xFF6C736B),
    health: Color(0xFFC65D4B),
    healthSoft: Color(0xFFF7E6E1),
    general: Color(0xFFB77D2A),
    generalSoft: Color(0xFFF6EAD3),
    professional: Color(0xFF5A6FA6),
    professionalSoft: Color(0xFFE4E8F3),
  );

  static const dark = AppColorsX(
    canvas: Color(0xFF141815),
    hairline: Color(0xFF2A312B),
    textSecondary: Color(0xFF9AA29A),
    health: Color(0xFFE08872),
    healthSoft: Color(0xFF33241F),
    general: Color(0xFFE0B25E),
    generalSoft: Color(0xFF322A1B),
    professional: Color(0xFF93A6D8),
    professionalSoft: Color(0xFF20263A),
  );

  @override
  AppColorsX copyWith({
    Color? canvas,
    Color? hairline,
    Color? textSecondary,
    Color? health,
    Color? healthSoft,
    Color? general,
    Color? generalSoft,
    Color? professional,
    Color? professionalSoft,
  }) {
    return AppColorsX(
      canvas: canvas ?? this.canvas,
      hairline: hairline ?? this.hairline,
      textSecondary: textSecondary ?? this.textSecondary,
      health: health ?? this.health,
      healthSoft: healthSoft ?? this.healthSoft,
      general: general ?? this.general,
      generalSoft: generalSoft ?? this.generalSoft,
      professional: professional ?? this.professional,
      professionalSoft: professionalSoft ?? this.professionalSoft,
    );
  }

  @override
  AppColorsX lerp(AppColorsX? other, double t) {
    if (other == null) return this;
    return AppColorsX(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      health: Color.lerp(health, other.health, t)!,
      healthSoft: Color.lerp(healthSoft, other.healthSoft, t)!,
      general: Color.lerp(general, other.general, t)!,
      generalSoft: Color.lerp(generalSoft, other.generalSoft, t)!,
      professional: Color.lerp(professional, other.professional, t)!,
      professionalSoft: Color.lerp(
        professionalSoft,
        other.professionalSoft,
        t,
      )!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorsX get colors {
    final theme = Theme.of(this);
    return theme.extension<AppColorsX>() ??
        (theme.brightness == Brightness.dark
            ? AppColorsX.dark
            : AppColorsX.light);
  }
}
