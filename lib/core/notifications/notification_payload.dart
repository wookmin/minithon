import '../../features/classification/need_category.dart';

/// 카테고리 → 알림에 실을 목적지 라우트.
/// [NeedCategory.none]은 알림을 띄우지 않으므로 라우트가 없다(null).
/// 3탭 개편으로 건강·전문가 화면이 사라져, 니즈 알림은 모두 심부름(구인) 화면으로 보낸다.
String? routeForCategory(NeedCategory category) {
  switch (category) {
    case NeedCategory.hospital:
    case NeedCategory.general:
    case NeedCategory.professional:
      return '/general';
    case NeedCategory.none:
      return null;
  }
}

/// 카테고리별 알림 제목/본문.
({String title, String body})? notificationContentFor(NeedCategory category) {
  switch (category) {
    case NeedCategory.hospital:
      return (title: '건강 관련 니즈 발견', body: '부모님이 몸이 불편하신 것 같아요. 근처 병원을 확인해보세요.');
    case NeedCategory.general:
      return (title: '심부름 니즈 발견', body: '부모님께 생활 도움이 필요해 보여요. 요청을 확인해보세요.');
    case NeedCategory.professional:
      return (title: '전문 돌봄 니즈 발견', body: '전문 돌봄이 필요해 보여요. 전문 탭을 확인해보세요.');
    case NeedCategory.none:
      return null;
  }
}
