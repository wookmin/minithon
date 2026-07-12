import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/core/notifications/notification_providers.dart';
import 'package:senior_needs/core/notifications/notification_service.dart';
import 'package:senior_needs/features/classification/classification_providers.dart';
import 'package:senior_needs/features/classification/keyword_need_classifier.dart';
import 'package:senior_needs/features/classification/need_category.dart';
import 'package:senior_needs/features/dev_input/dev_input_screen.dart';

/// 알림 호출만 기록하는 가짜 서비스.
class FakeNotificationService extends NotificationService {
  FakeNotificationService() : super(FlutterLocalNotificationsPlugin());

  final List<NeedCategory> shown = [];

  @override
  Future<void> init({
    required void Function(String route) onSelectRoute,
  }) async {}

  @override
  Future<void> showNeedNotification(NeedCategory category) async {
    shown.add(category);
  }
}

void main() {
  Future<FakeNotificationService> pumpDevInput(WidgetTester tester) async {
    final fake = FakeNotificationService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(fake),
          needClassifierProvider.overrideWithValue(
            const KeywordNeedClassifier(),
          ),
        ],
        child: const MaterialApp(home: DevInputScreen()),
      ),
    );
    return fake;
  }

  testWidgets('"허리가 아프다" 입력 → hospital 분류 + 알림 발송', (tester) async {
    final fake = await pumpDevInput(tester);

    await tester.enterText(find.byType(TextField), '허리가 아프다');
    await tester.tap(find.widgetWithText(FilledButton, '분석하기'));
    await tester.pumpAndSettle();

    expect(fake.shown, [NeedCategory.hospital]);
    expect(find.text('니즈를 감지했어요'), findsOneWidget);
  });

  testWidgets('잡담 입력 → none, 알림 없음', (tester) async {
    final fake = await pumpDevInput(tester);

    await tester.enterText(find.byType(TextField), '오늘 날씨 좋네 밥 먹었어');
    await tester.tap(find.widgetWithText(FilledButton, '분석하기'));
    await tester.pumpAndSettle();

    expect(fake.shown, isEmpty);
    expect(find.text('특별한 니즈가 없어요'), findsOneWidget);
    expect(find.text('알림을 보내지 않았어요'), findsOneWidget);
  });
}
