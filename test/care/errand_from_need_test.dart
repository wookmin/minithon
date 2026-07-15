import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/care/errand_from_need.dart';
import 'package:senior_needs/features/classification/need_category.dart';

void main() {
  group('errandCategoryForNeed', () {
    test('건강/전문 니즈는 병원 동행으로 매핑한다', () {
      expect(errandCategoryForNeed(NeedCategory.hospital), '병원 동행');
      expect(errandCategoryForNeed(NeedCategory.professional), '병원 동행');
    });
    test('일반 니즈는 장보기로 매핑한다', () {
      expect(errandCategoryForNeed(NeedCategory.general), '장보기');
    });
  });

  group('errandTitleForCategory', () {
    test('구인 카테고리별 기본 제목을 준다', () {
      expect(errandTitleForCategory('병원 동행'), '병원 동행이 필요해요');
      expect(errandTitleForCategory('장보기'), '장보기 도움이 필요해요');
      expect(errandTitleForCategory('수리'), '집 수리 도움이 필요해요');
      expect(errandTitleForCategory('교통'), '이동(교통) 도움이 필요해요');
    });
    test('모르는 카테고리는 일반 문구로 폴백한다', () {
      expect(errandTitleForCategory('기타'), '생활 도움이 필요해요');
    });
  });
}
