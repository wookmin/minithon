import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_providers.dart';
import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';

/// 이번 세션에 자동 분석 설정을 이미 유도했는지. (중복 유도 방지)
class AnalysisSetupPromptedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markPrompted() => state = true;
}

final analysisSetupPromptedProvider =
    NotifierProvider<AnalysisSetupPromptedNotifier, bool>(
      AnalysisSetupPromptedNotifier.new,
    );

/// 자동 통화 분석을 켜도록 유도하는 1회성 시트.
/// "지금 설정하기" → 녹음 연결 화면, "나중에" → 꺼짐 리마인더 알림.
Future<void> showAnalysisSetupSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final text = Theme.of(sheetContext).textTheme;
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 26,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
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
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: scheme.primary,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '통화 자동 분석을 켤까요?',
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '통화가 끝나면 자동으로 분석해\n놓치는 니즈가 없게 챙겨드려요.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: sheetContext.colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push('/recording-setup');
              },
              child: const Text('지금 설정하기'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                ref.read(notificationServiceProvider).showAnalysisOffReminder();
              },
              child: const Text('나중에 할게요'),
            ),
          ],
        ),
      );
    },
  );
}
