import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/hospital/hospital_repository.dart';

void main() {
  test('빈 주소는 서버 호출 없이 빈 목록을 반환한다', () async {
    var called = false;
    final repository = FunctionsHospitalRepository(
      invoke: (name, payload) async {
        called = true;
        return {};
      },
    );

    final result = await repository.findNearby('   ');

    expect(called, isFalse);
    expect(result, isEmpty);
  });

  test('서버가 돌려준 병원 문서를 거리순으로 매핑한다', () async {
    late String sentName;
    final repository = FunctionsHospitalRepository(
      invoke: (name, payload) async {
        sentName = name;
        expect(payload['address'], '전북 남원시 향단로 10');
        return {
          'hospitals': [
            {
              'place_name': '남원속내과의원',
              'category_name': '의료,건강 > 병원 > 내과',
              'phone': '063-111-2222',
              'road_address_name': '전북 남원시 시청로 10',
              'address_name': '전북 남원시 도통동 1',
              'distance': '450',
            },
            {
              'place_name': '남원정형외과',
              'category_name': '의료,건강 > 병원 > 정형외과',
              'phone': '',
              'road_address_name': '',
              'address_name': '전북 남원시 왕정동 2',
              'distance': 1800,
            },
          ],
        };
      },
    );

    final result = await repository.findNearby('전북 남원시 향단로 10');

    expect(sentName, 'nearbyHospitals');
    expect(result.length, 2);
    expect(result.first.name, '남원속내과의원');
    expect(result.first.department, '내과');
    expect(result.first.distance, '450m');
    expect(result.first.phone, '063-111-2222');
    // 도로명 없으면 지번 주소로 폴백, distance가 숫자로 와도 포맷
    expect(result[1].address, '전북 남원시 왕정동 2');
    expect(result[1].distance, '1.8km');
  });

  test('hospitals가 없으면 빈 목록을 반환한다', () async {
    final repository = FunctionsHospitalRepository(
      invoke: (name, payload) async => {'hospitals': <dynamic>[]},
    );

    final result = await repository.findNearby('알 수 없는 주소');

    expect(result, isEmpty);
  });

  test('서버 오류는 빈 목록으로 폴백한다', () async {
    final repository = FunctionsHospitalRepository(
      invoke: (name, payload) async => throw Exception('unavailable'),
    );

    final result = await repository.findNearby('전북 남원시');

    expect(result, isEmpty);
  });
}
