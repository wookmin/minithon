import '../../core/notifications/notification_service.dart';
import '../classification/need_classification_result.dart';
import '../classification/need_classifier.dart';
import 'analysis_history_providers.dart';
import 'analysis_record.dart';

/// 통화 텍스트를 분류 → 기록 저장 → (니즈 있으면) 알림까지 한 번에 처리한다.
/// dev_input(통화 분석)·recording_setup(매칭 녹음)·백그라운드 분석이 공통으로 사용한다.
/// 의존성을 프로바이더가 아닌 값으로 받아, UI(WidgetRef) 없는 헤드리스 isolate에서도 재사용된다.
Future<NeedClassificationResult> runNeedAnalysis({
  required NeedClassifier classifier,
  required AnalysisHistoryNotifier history,
  required NotificationService notifications,
  required String text,
  required String recipientName,
  DateTime? callTime,
}) async {
  final result = await classifier.classify(text);

  final now = DateTime.now();
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final snippet = normalized.length > 60
      ? '${normalized.substring(0, 60)}…'
      : normalized;
  final summary = result.reason.trim().isNotEmpty ? result.reason.trim() : snippet;

  await history.add(
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
    await notifications.showNeedNotification(result.primaryCategory);
  }

  return result;
}
