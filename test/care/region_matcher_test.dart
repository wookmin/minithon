import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/care/region_matcher.dart';

void main() {
  group('regionKey', () {
    test('도로명 주소에서 구를 뽑는다', () {
      expect(regionKey('서울 강남구 테헤란로 1'), '강남구');
    });
    test('시+구가 함께면 더 좁은 구를 우선한다', () {
      expect(regionKey('경기 성남시 분당구 판교로 1'), '분당구');
    });
    test('구가 없으면 시를 뽑는다', () {
      expect(regionKey('경기 광명시 오리로 1'), '광명시');
    });
    test('군을 뽑는다', () {
      expect(regionKey('강원 양양군 양양읍'), '양양군');
    });
    test('자유 입력(구+동)에서도 구를 뽑는다', () {
      expect(regionKey('강남구 역삼동'), '강남구');
    });
    test('구/시/군이 없거나 비면 빈 키', () {
      expect(regionKey(''), '');
      expect(regionKey('   '), '');
      expect(regionKey('테헤란로 1'), '');
    });
  });

  group('sameRegion', () {
    test('같은 구면 주소 형식이 달라도 매칭한다', () {
      expect(sameRegion('서울 강남구 테헤란로 1', '강남구 역삼동'), isTrue);
    });
    test('다른 구는 매칭하지 않는다', () {
      expect(sameRegion('서울 강남구', '서울 서초구'), isFalse);
    });
    test('키를 못 뽑으면(빈값) 매칭하지 않는다', () {
      expect(sameRegion('', '강남구'), isFalse);
      expect(sameRegion('강남구', ''), isFalse);
    });
  });
}
