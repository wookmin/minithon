import '../classification/need_category.dart';

/// 통화에서 분류된 [NeedCategory]를 구인글 카테고리(장보기/수리/병원 동행/교통)로 매핑한다.
/// 건강·전문 돌봄 니즈는 이웃이 수행 가능한 '병원 동행'으로 수렴시킨다.
String errandCategoryForNeed(NeedCategory category) {
  switch (category) {
    case NeedCategory.hospital:
    case NeedCategory.professional:
      return '병원 동행';
    case NeedCategory.general:
    case NeedCategory.none:
      return '장보기';
  }
}

/// 구인글 카테고리별 기본 제목. (통화 자동 생성 시 사용)
String errandTitleForCategory(String category) {
  switch (category) {
    case '병원 동행':
      return '병원 동행이 필요해요';
    case '장보기':
      return '장보기 도움이 필요해요';
    case '수리':
      return '집 수리 도움이 필요해요';
    case '교통':
      return '이동(교통) 도움이 필요해요';
    default:
      return '생활 도움이 필요해요';
  }
}
