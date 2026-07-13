import 'package:flutter/material.dart';

import '../theme/app_colors_x.dart';
import '../theme/app_shape.dart' show AppRadius;

/// 로딩 자리표시자. 은은하게 명멸하는 회색 박스. (스피너 대체 — 요즘 앱 스타일)
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.hairline;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              base,
              scheme.surfaceContainerHighest,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// 카드 안에서 여러 줄 스켈레톤을 쌓을 때 쓰는 헬퍼.
class SkeletonLines extends StatelessWidget {
  const SkeletonLines({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines; i++) ...[
          Skeleton(
            width: i.isEven ? double.infinity : 160,
            height: 14,
            radius: AppRadius.pill,
          ),
          if (i != lines - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
