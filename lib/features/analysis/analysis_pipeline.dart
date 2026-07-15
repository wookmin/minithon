import '../../core/notifications/notification_service.dart';
import '../care/care_models.dart';
import '../care/errand_from_need.dart';
import '../classification/need_classification_result.dart';
import '../classification/need_classifier.dart';
import 'analysis_history_providers.dart';
import 'analysis_record.dart';

/// 통화 텍스트를 분류 → 기록 저장 → (니즈 있으면) 알림 + 구인글 초안까지 처리한다.
/// dev_input(통화 분석)·recording_setup(매칭 녹음)·백그라운드 분석이 공통으로 사용한다.
/// 의존성을 프로바이더가 아닌 값으로 받아, UI(WidgetRef) 없는 헤드리스 isolate에서도 재사용된다.
///
/// [recipientRegion]과 [onErrandDraft]가 함께 주어지고 니즈가 발견되면,
/// 통화 내용을 부모님 지역의 구인글 초안으로 만들어 [onErrandDraft]로 넘긴다.
Future<NeedClassificationResult> runNeedAnalysis({
  required NeedClassifier classifier,
  required AnalysisHistoryNotifier history,
  required NotificationService notifications,
  required String text,
  required String recipientName,
  DateTime? callTime,
  String recipientRegion = '',
  String requesterUid = '',
  String requesterName = '',
  Future<void> Function(ErrandRequest draft)? onErrandDraft,
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

    // 부모님 지역 정보와 초안 훅이 있으면, 통화 니즈를 그 지역 구인글로 올린다.
    if (onErrandDraft != null && recipientRegion.trim().isNotEmpty) {
      final category = errandCategoryForNeed(result.primaryCategory);
      await onErrandDraft(
        ErrandRequest(
          id: now.microsecondsSinceEpoch.toString(),
          title: errandTitleForCategory(category),
          category: category,
          region: recipientRegion.trim(),
          distance: '부모님 지역',
          description: summary,
          status: '모집중',
          requesterUid: requesterUid,
          requesterName: requesterName,
          createdAt: now,
        ),
      );
    }
  }

  return result;
}
