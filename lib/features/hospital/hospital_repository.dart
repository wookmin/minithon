import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hospital.dart';

/// 근처 병원 조회 경계 인터페이스.
///
/// 확장 지점: 이번 단계는 [DummyHospitalRepository](더미 목록).
/// 다음 단계에서 지도/장소 API 구현으로 교체(화면/provider 무변경).
abstract interface class HospitalRepository {
  Future<List<Hospital>> findNearby(String address);
}

class DummyHospitalRepository implements HospitalRepository {
  const DummyHospitalRepository();

  @override
  Future<List<Hospital>> findNearby(String address) async {
    // 주소는 헤더/로그용으로만 사용. 실제 위치 조회는 다음 단계.
    return const [
      Hospital(
        name: '남원의료원',
        department: '정형외과 · 내과',
        address: '전북특별자치도 남원시 시청로 66',
        distance: '1.2km',
        isOpenNow: true,
        hours: '오늘 09:00 - 17:30',
        phone: '063-620-1114',
        rating: 4.6,
        reviewCount: 214,
      ),
      Hospital(
        name: '남원제일병원',
        department: '정형외과 · 재활의학과',
        address: '전북특별자치도 남원시 용성로 34',
        distance: '2.4km',
        isOpenNow: true,
        hours: '오늘 08:30 - 18:00',
        phone: '063-625-2000',
        rating: 4.4,
        reviewCount: 88,
      ),
      Hospital(
        name: '행복한통증의학과의원',
        department: '통증의학과',
        address: '전북특별자치도 남원시 향단로 22',
        distance: '3.1km',
        isOpenNow: false,
        hours: '오늘 진료 마감 · 내일 09:00',
        phone: '063-631-7575',
        rating: 4.8,
        reviewCount: 156,
      ),
    ];
  }
}

final hospitalRepositoryProvider = Provider<HospitalRepository>(
  (ref) => const DummyHospitalRepository(),
);
