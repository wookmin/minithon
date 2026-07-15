import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 똥강아지 로고 마크. assets/images/logo.svg를 지정 크기로 렌더한다.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 42, this.radius = 12});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SvgPicture.asset(
        'assets/images/logo.svg',
        width: size,
        height: size,
      ),
    );
  }
}
