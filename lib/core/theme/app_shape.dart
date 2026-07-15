import 'package:flutter/material.dart';

/// 요소 크기별 라운드 위계. 모든 곡률은 여기서만 정의한다.
abstract final class AppRadius {
  /// 화면 위 최상위 카드.
  static const card = 16.0;

  /// 카드 안에 중첩되는 표면·아이콘 타일.
  static const surface = 12.0;

  /// 인풋 등 사각 컨트롤.
  static const control = 14.0;

  /// 칩·배지·버튼처럼 완전히 둥근 알약형.
  static const pill = 999.0;
}

/// 라이트/다크에 맞춰 카드 표면에 얹는 그림자.
/// 라이트는 부드러운 2단 그림자, 다크는 그림자 대신 헤어라인으로 위계를 준다.
List<BoxShadow> softCardShadow(Brightness brightness) {
  if (brightness == Brightness.dark) return const [];
  return const [
    BoxShadow(
      color: Color(0x0F121F5C),
      blurRadius: 24,
      spreadRadius: -10,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
}
