import 'package:flutter/material.dart';

import 'app_colors_x.dart';
import 'app_shape.dart';

/// 앱 테마. 상록수 그린 브랜드 + 따뜻한 세이지 페이퍼 바탕.
abstract final class AppTheme {
  static const _brand = Color(0xFF2E6B4F);
  static const _brandDark = Color(0xFF6FBF93);

  static ThemeData light() => _base(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: _brand,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCEBE1),
      onPrimaryContainer: Color(0xFF15321F),
      secondary: _brand,
      surface: Colors.white,
      onSurface: Color(0xFF1E241F),
      surfaceContainerHighest: Color(0xFFEDEEE8),
    ),
    colorsX: AppColorsX.light,
  );

  static ThemeData dark() => _base(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: _brandDark,
      onPrimary: Color(0xFF06210F),
      primaryContainer: Color(0xFF244735),
      onPrimaryContainer: Color(0xFFD6EEDD),
      secondary: _brandDark,
      surface: Color(0xFF1C221E),
      onSurface: Color(0xFFECEFEA),
      surfaceContainerHighest: Color(0xFF232A25),
    ),
    colorsX: AppColorsX.dark,
  );

  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme scheme,
    required AppColorsX colorsX,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colorsX.canvas,
      fontFamily: 'Pretendard',
    );

    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 27,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.15,
        color: scheme.onSurface,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14.5,
        height: 1.4,
        color: colorsX.textSecondary,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );

    return base.copyWith(
      textTheme: text,
      extensions: [colorsX],
      appBarTheme: AppBarTheme(
        backgroundColor: colorsX.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1C221E),
        elevation: 0,
        height: 68,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : colorsX.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.onPrimaryContainer : colorsX.textSecondary,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colorsX.hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: colorsX.hairline),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        hintStyle: TextStyle(color: colorsX.textSecondary),
        labelStyle: TextStyle(color: colorsX.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: scheme.primary,
          side: BorderSide(color: colorsX.hairline),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: TextStyle(
          color: scheme.surface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
    );
  }
}
