import 'package:flutter/material.dart';

import '../theme/app_colors_x.dart';
import '../theme/app_shape.dart';

/// 액션 완료를 알리는 확인 바텀시트. (데모용 스낵바 대체 — 완료 상태를 명확히 보여준다)
Future<void> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.check_circle_rounded,
  String buttonLabel = '확인',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final text = Theme.of(context).textTheme;
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 26,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.surface),
                ),
                child: Icon(icon, color: scheme.primary, size: 30),
              ),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: text.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(buttonLabel),
            ),
          ],
        ),
      );
    },
  );
}
