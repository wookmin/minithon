import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/business/business_providers.dart';
import 'package:senior_needs/features/business/local_business.dart';

const _all = [
  LocalBusiness(
    id: '1',
    name: '강남수리',
    category: '수리',
    region: '강남구',
    phone: '',
    description: '',
    rating: 4.5,
    feeWon: 3000,
  ),
  LocalBusiness(
    id: '2',
    name: '강남청소',
    category: '청소',
    region: '강남구',
    phone: '',
    description: '',
    rating: 4.5,
    feeWon: 3000,
  ),
  LocalBusiness(
    id: '3',
    name: '마포수리',
    category: '수리',
    region: '마포구',
    phone: '',
    description: '',
    rating: 4.5,
    feeWon: 3000,
  ),
];

void main() {
  test('같은 지역 + 카테고리로 좁힌다', () {
    final result = matchBusinesses(
      all: _all,
      region: '서울 강남구 테헤란로 1',
      category: '수리',
    );
    expect(result.map((b) => b.id), ['1']);
  });

  test('카테고리만 주면 지역 매칭 업체만', () {
    final result = matchBusinesses(all: _all, region: '강남구 역삼동');
    expect(result.map((b) => b.id), ['1', '2']);
  });

  test('지역에 입점 업체가 없으면 카테고리 전체로 폴백한다', () {
    final result = matchBusinesses(
      all: _all,
      region: '부산 해운대구',
      category: '수리',
    );
    expect(result.map((b) => b.id), ['1', '3']);
  });

  test('지역 미등록(빈 주소)이면 카테고리 필터만 적용', () {
    final result = matchBusinesses(all: _all, region: '', category: '청소');
    expect(result.map((b) => b.id), ['2']);
  });
}
