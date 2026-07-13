import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_providers.dart';
import '../classification/classification_providers.dart';
import '../classification/need_classification_result.dart';
import 'analysis_history_providers.dart';
import 'analysis_record.dart';

/// 통화 텍스트를 분류 → 기록 저장 → (니즈 있으면) 알림까지 한 번에 처리한다.
/// dev_input(통화 분석)과 recording_setup(매칭 녹음)이 공통으로 사용한다.
Future<NeedClassificationResult> runNeedAnalysis(
  WidgetRef ref, {
  required String text,
  required String recipientName,
  DateTime? callTime,
}) async {
  final result = await ref.read(needClassifierProvider).classify(text);

  final now = DateTime.now();
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final snippet = normalized.length > 60
      ? '${normalized.substring(0, 60)}…'
      : normalized;
  final summary = result.reason.trim().isNotEmpty ? result.reason.trim() : snippet;

  await ref
      .read(analysisHistoryProvider.notifier)
      .add(
        AnalysisRecord(
          id: now.microsecondsSinceEpoch.toString(),
          createdAt: now,
          recipientName: recipientName,
          callTime: callTime ?? now,
          categories: result.categories,
          reason: result.reason,
          summary: summary,
          snippet: snippet,
        ),
      );

  if (result.hasActionableNeed) {
    await ref
        .read(notificationServiceProvider)
        .showNeedNotification(result.primaryCategory);
  }

  return result;
}
