import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/core/notifications/notification_payload.dart';
import 'package:senior_needs/features/classification/need_category.dart';

void main() {
  test('분류 카테고리별 알림 라우트를 유지한다', () {
    expect(routeForCategory(NeedCategory.hospital), '/hospital');
    expect(routeForCategory(NeedCategory.general), '/general');
    expect(routeForCategory(NeedCategory.professional), '/professional');
    expect(routeForCategory(NeedCategory.none), isNull);
  });
}
