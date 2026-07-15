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
    canvas: Color(0xFFF4F5F7),
    hairline: Color(0xFFE4E7EB),
    textSecondary: Color(0xFF4B5768),
    health: Color(0xFFEC441E),
    healthSoft: Color(0xFFFCE8E3),
    general: Color(0xFF997E00),
    generalSoft: Color(0xFFFAF3CD),
    professional: Color(0xFF2F4EFF),
    professionalSoft: Color(0xFFE7EBFF),
  );

  static const dark = AppColorsX(
    canvas: Color(0xFF0D0D0D),
    hairline: Color(0x1FFFFFFF),
    textSecondary: Color(0xFF999DA3),
    health: Color(0xFFFF7349),
    healthSoft: Color(0xFF33201A),
    general: Color(0xFFE5CB45),
    generalSoft: Color(0xFF342E0D),
    professional: Color(0xFF4964FF),
    professionalSoft: Color(0xFF1B2140),
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
