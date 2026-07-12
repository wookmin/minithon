import 'package:flutter/material.dart';

import '../theme/app_colors_x.dart';
import '../theme/app_shape.dart';

/// 각 탭 상단의 히어로 헤더. 아이브로우 라벨 + 큰 제목 + 보조 문구 + 우측 액션.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onAssistant,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onAssistant;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  eyebrow,
                  style: text.labelLarge?.copyWith(
                    color: accent,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (onAssistant != null) _AssistantButton(onTap: onAssistant!),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: text.headlineMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _AssistantButton extends StatelessWidget {
  const _AssistantButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(color: context.colors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 17, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                '분석',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
