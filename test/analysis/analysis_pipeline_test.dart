import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/core/firebase/firebase_providers.dart';
import 'package:senior_needs/core/notifications/notification_service.dart';
import 'package:senior_needs/features/analysis/analysis_history_providers.dart';
import 'package:senior_needs/features/analysis/analysis_pipeline.dart';
import 'package:senior_needs/features/classification/need_category.dart';
import 'package:senior_needs/features/classification/need_classification_result.dart';
import 'package:senior_needs/features/classification/need_classifier.dart';

class _StubClassifier implements NeedClassifier {
  _StubClassifier(this.result);
  final NeedClassificationResult result;

  @override
  Future<NeedClassificationResult> classify(String text) async => result;
}

/// 알림 발송 여부만 기록하는 가짜. 실제 플러그인 호출은 하지 않는다.
class _RecordingNotificationService extends NotificationService {
  _RecordingNotificationService() : super(FlutterLocalNotificationsPlugin());
  final List<NeedCategory> shown = [];

  @override
  Future<void> showNeedNotification(NeedCategory category) async {
    shown.add(category);
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWithValue(firestore),
        currentUidProvider.overrideWithValue('test-uid'),
      ],
    );
    addTearDown(container.dispose);
    await container.read(analysisHistoryProvider.future);
  });

  test('니즈가 있으면 알림 1회 + 기록 저장', () async {
    final notif = _RecordingNotificationService();

    final result = await runNeedAnalysis(
      classifier: _StubClassifier(
        const NeedClassificationResult(
          categories: [NeedCategory.hospital],
          confidence: 0.9,
          reason: '허리 통증 언급',
        ),
      ),
      history: container.read(analysisHistoryProvider.notifier),
      notifications: notif,
      text: '허리가 아프다고 하셨어',
      recipientName: '김영희',
    );

    expect(result.hasActionableNeed, isTrue);
    expect(notif.shown, [NeedCategory.hospital]);

    final records = container.read(analysisHistoryProvider).value!;
    expect(records.length, 1);
    expect(records.first.recipientName, '김영희');
    expect(records.first.categories, [NeedCategory.hospital]);
  });

  test('"없음" 분류면 알림 없이 기록만 저장', () async {
    final notif = _RecordingNotificationService();

    final result = await runNeedAnalysis(
      classifier: _StubClassifier(NeedClassificationResult.none()),
      history: container.read(analysisHistoryProvider.notifier),
      notifications: notif,
      text: '그냥 안부 전화였어',
      recipientName: '김영희',
    );

    expect(result.hasActionableNeed, isFalse);
    expect(notif.shown, isEmpty);

    // 니즈가 없어도 "누구와 언제 통화했는지" 기록은 남아야 한다.
    final records = container.read(analysisHistoryProvider).value!;
    expect(records.length, 1);
    expect(records.first.recipientName, '김영희');
  });
}
