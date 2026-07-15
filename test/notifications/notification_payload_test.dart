import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/core/notifications/notification_payload.dart';
import 'package:senior_needs/features/classification/need_category.dart';

void main() {
  test('3탭 개편 후 니즈 알림은 모두 심부름 화면으로 보낸다', () {
    expect(routeForCategory(NeedCategory.hospital), '/general');
    expect(routeForCategory(NeedCategory.general), '/general');
    expect(routeForCategory(NeedCategory.professional), '/general');
    expect(routeForCategory(NeedCategory.none), isNull);
  });

  test('"없음"은 알림 콘텐츠가 없고, 나머지는 제목/본문을 가진다', () {
    expect(notificationContentFor(NeedCategory.none), isNull);
    for (final category in [
      NeedCategory.hospital,
      NeedCategory.general,
      NeedCategory.professional,
    ]) {
      final content = notificationContentFor(category);
      expect(content, isNotNull);
      expect(content!.title, isNotEmpty);
      expect(content.body, isNotEmpty);
    }
  });
}
