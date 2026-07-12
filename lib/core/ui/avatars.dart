import 'package:flutter/material.dart';

import '../theme/app_colors_x.dart';

/// 사진 대신 쓰는 그라데이션 아바타. 이니셜 한 글자를 얹는다.
/// (실제 프로필 사진 연동 전까지 카드에 온기·밀도를 준다)
class GradientAvatar extends StatelessWidget {
  const GradientAvatar({
    super.key,
    required this.label,
    required this.color,
    this.size = 52,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.12)!,
            Color.lerp(color, Colors.black, 0.16)!,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label.characters.first,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// 지원자 수를 겹친 원형 아바타 더미로 보여준다. (당근·숨고 스타일)
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.count, this.diameter = 26});

  final int count;
  final double diameter;

  static const _palette = [
    Color(0xFFC65D4B),
    Color(0xFFB77D2A),
    Color(0xFF5A6FA6),
    Color(0xFF2E6B4F),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = count.clamp(0, 3);
    final overlap = diameter * 0.32;
    final surface = Theme.of(context).colorScheme.surface;

    return SizedBox(
      height: diameter,
      width: visible == 0
          ? 0
          : diameter + (visible - 1) * (diameter - overlap) + (count > 3 ? 12 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible; i++)
            Positioned(
              left: i * (diameter - overlap),
              child: Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  color: _palette[i % _palette.length],
                  shape: BoxShape.circle,
                  border: Border.all(color: surface, width: 2),
                ),
              ),
            ),
          if (count > 3)
            Positioned(
              left: visible * (diameter - overlap),
              child: Container(
                height: diameter,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.hairline,
                  borderRadius: BorderRadius.circular(diameter),
                ),
                child: Text(
                  '+${count - 3}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
