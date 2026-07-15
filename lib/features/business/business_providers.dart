import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../care/region_matcher.dart';
import '../classification/need_category.dart';
import 'local_business.dart';

/// 입점 업체 목록. 지금은 더미 상수, 이후 Firestore로 교체 가능한 지점.
final localBusinessesProvider = Provider<List<LocalBusiness>>(
  (ref) => kDummyBusinesses,
);

/// 통화 니즈 카테고리 → 업체 카테고리. none은 매칭 대상이 없다.
String? businessCategoryForNeed(NeedCategory category) {
  switch (category) {
    case NeedCategory.hospital:
      return '병원 동행';
    case NeedCategory.professional:
      return '간병';
    case NeedCategory.general:
      return '장보기';
    case NeedCategory.none:
      return null;
  }
}

/// 지역·카테고리로 업체를 추린다.
/// 같은 지역(시/군/구) 업체를 우선하고, 지역 매칭이 하나도 없으면
/// (부모 지역 미등록·미입점) 카테고리만 맞는 전체를 폴백으로 보여준다.
List<LocalBusiness> matchBusinesses({
  required List<LocalBusiness> all,
  required String region,
  String? category,
}) {
  var pool = all;
  if (category != null && category.isNotEmpty) {
    pool = pool.where((business) => business.category == category).toList();
  }
  if (regionKey(region).isEmpty) return pool;
  final sameRegionPool = pool
      .where((business) => sameRegion(business.region, region))
      .toList();
  return sameRegionPool.isNotEmpty ? sameRegionPool : pool;
}

/// 데모용 입점 업체(로컬 상수). 지역 × 카테고리로 다양하게 구성.
const kDummyBusinesses = <LocalBusiness>[
  LocalBusiness(
    id: 'b-gn-repair',
    name: '강남 24시 생활수리',
    category: '수리',
    region: '강남구',
    phone: '02-555-0111',
    description: '전등·수도·문고리 등 집안 잔고장 당일 방문 수리.',
    rating: 4.8,
    feeWon: 3000,
  ),
  LocalBusiness(
    id: 'b-gn-clean',
    name: '깨끗한이웃 청소',
    category: '청소',
    region: '강남구',
    phone: '02-555-0122',
    description: '어르신 가정 정기 청소·환기·정리 정돈.',
    rating: 4.7,
    feeWon: 3000,
  ),
  LocalBusiness(
    id: 'b-gn-care',
    name: '든든 방문간병',
    category: '간병',
    region: '강남구',
    phone: '02-555-0133',
    description: '요양보호사 방문 돌봄·말벗·복약 확인.',
    rating: 4.9,
    feeWon: 5000,
  ),
  LocalBusiness(
    id: 'b-gn-hospital',
    name: '함께가요 병원동행',
    category: '병원 동행',
    region: '강남구',
    phone: '02-555-0144',
    description: '병원 예약·이동·접수·수납까지 1:1 동행.',
    rating: 4.8,
    feeWon: 4000,
  ),
  LocalBusiness(
    id: 'b-sc-repair',
    name: '서초 홈픽스',
    category: '수리',
    region: '서초구',
    phone: '02-566-0211',
    description: '가전·가구 설치 및 소규모 집수리 전문.',
    rating: 4.6,
    feeWon: 3000,
  ),
  LocalBusiness(
    id: 'b-sc-market',
    name: '서초 장보기 도우미',
    category: '장보기',
    region: '서초구',
    phone: '02-566-0222',
    description: '장보기 대행·무거운 짐 배달·생필품 정기 배송.',
    rating: 4.5,
    feeWon: 2000,
  ),
  LocalBusiness(
    id: 'b-sc-hospital',
    name: '서초 안심 병원동행',
    category: '병원 동행',
    region: '서초구',
    phone: '02-566-0233',
    description: '거동 불편 어르신 병원 동행·검사 보조.',
    rating: 4.7,
    feeWon: 4000,
  ),
  LocalBusiness(
    id: 'b-mp-clean',
    name: '마포 반짝 청소',
    category: '청소',
    region: '마포구',
    phone: '02-333-0311',
    description: '입주·거주 청소, 어르신 가정 맞춤 정리.',
    rating: 4.6,
    feeWon: 3000,
  ),
  LocalBusiness(
    id: 'b-mp-repair',
    name: '마포 생활수리반',
    category: '수리',
    region: '마포구',
    phone: '02-333-0322',
    description: '보일러·전기·배관 응급 수리 당일 대응.',
    rating: 4.4,
    feeWon: 3000,
  ),
  LocalBusiness(
    id: 'b-mp-care',
    name: '마포 온기 돌봄',
    category: '간병',
    region: '마포구',
    phone: '02-333-0333',
    description: '단기·정기 방문 돌봄, 치매 어르신 케어.',
    rating: 4.8,
    feeWon: 5000,
  ),
  LocalBusiness(
    id: 'b-bd-market',
    name: '분당 살뜰장보기',
    category: '장보기',
    region: '분당구',
    phone: '031-777-0411',
    description: '마트 장보기 대행·정기 식자재 배송.',
    rating: 4.7,
    feeWon: 2000,
  ),
  LocalBusiness(
    id: 'b-bd-hospital',
    name: '분당 효도 병원동행',
    category: '병원 동행',
    region: '분당구',
    phone: '031-777-0422',
    description: '대형병원 예약·동행·귀가까지 전 과정 지원.',
    rating: 4.9,
    feeWon: 4000,
  ),
  LocalBusiness(
    id: 'b-bd-repair',
    name: '분당 집수리 명가',
    category: '수리',
    region: '분당구',
    phone: '031-777-0433',
    description: '누수·전기·창호 등 집수리 종합 서비스.',
    rating: 4.6,
    feeWon: 3000,
  ),
  LocalBusiness(
    id: 'b-sp-care',
    name: '송파 늘봄 간병',
    category: '간병',
    region: '송파구',
    phone: '02-444-0511',
    description: '병원·가정 간병, 24시간 돌봄 매칭.',
    rating: 4.7,
    feeWon: 5000,
  ),
  LocalBusiness(
    id: 'b-sp-clean',
    name: '송파 크린메이트',
    category: '청소',
    region: '송파구',
    phone: '02-444-0522',
    description: '어르신 가정 정기 청소·소독·정리.',
    rating: 4.5,
    feeWon: 3000,
  ),
  LocalBusiness(
    id: 'b-sp-market',
    name: '송파 이웃장보기',
    category: '장보기',
    region: '송파구',
    phone: '02-444-0533',
    description: '장보기·약국 심부름·생필품 대행.',
    rating: 4.4,
    feeWon: 2000,
  ),
];
