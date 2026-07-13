import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:senior_needs/features/hospital/hospital_repository.dart';
import 'package:senior_needs/features/hospital/kakao_api_config.dart';

void main() {
  test('키가 없으면 더미 목록으로 폴백한다', () async {
    final repository = KakaoHospitalRepository(
      config: const KakaoApiConfig(restApiKey: ''),
      client: MockClient((request) async {
        fail('키가 없으면 호출하지 않아야 한다.');
      }),
    );

    final result = await repository.findNearby('전북 남원시 향단로 10');

    expect(result, isNotEmpty);
    expect(result.first.name, '남원의료원');
  });

  test('주소 지오코딩 후 병원을 거리순으로 매핑한다', () async {
    final repository = KakaoHospitalRepository(
      config: const KakaoApiConfig(restApiKey: 'test-key'),
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'KakaoAK test-key');
        if (request.url.path.contains('search/address')) {
          return http.Response(
            jsonEncode({
              'documents': [
                {'x': '127.12', 'y': '35.41'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        expect(request.url.queryParameters['category_group_code'], 'HP8');
        return http.Response(
          jsonEncode({
            'documents': [
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
                'distance': '1800',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await repository.findNearby('전북 남원시 향단로 10');

    expect(result.length, 2);
    expect(result.first.name, '남원속내과의원');
    expect(result.first.department, '내과');
    expect(result.first.distance, '450m');
    expect(result.first.phone, '063-111-2222');
    // 도로명 없으면 지번 주소로 폴백
    expect(result[1].address, '전북 남원시 왕정동 2');
    expect(result[1].distance, '1.8km');
  });

  test('distance가 숫자로 와도 거리를 포맷한다', () async {
    final repository = KakaoHospitalRepository(
      config: const KakaoApiConfig(restApiKey: 'test-key'),
      client: MockClient((request) async {
        if (request.url.path.contains('search/address')) {
          return http.Response(
            jsonEncode({
              'documents': [
                {'x': '127.1', 'y': '35.4'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({
            'documents': [
              {
                'place_name': '테스트병원',
                'category_name': '의료,건강 > 병원 > 내과',
                'phone': '063-000-0000',
                'road_address_name': '전북 남원시 1',
                'distance': 1500,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await repository.findNearby('전북 남원시');

    expect(result.first.distance, '1.5km');
  });

  test('지오코딩 결과가 없으면 더미로 폴백한다', () async {
    final repository = KakaoHospitalRepository(
      config: const KakaoApiConfig(restApiKey: 'test-key'),
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({'documents': []}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await repository.findNearby('알 수 없는 주소');

    expect(result.first.name, '남원의료원');
  });
}
