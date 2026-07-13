import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'hospital.dart';
import 'kakao_api_config.dart';

/// 근처 병원 조회 경계 인터페이스.
abstract interface class HospitalRepository {
  Future<List<Hospital>> findNearby(String address);
}

/// 카카오 로컬 API로 주소를 좌표로 바꾼 뒤 반경 내 병원(HP8)을 거리순으로 조회한다.
/// 키가 없거나 조회 실패 시 [DummyHospitalRepository]로 폴백해 화면이 비지 않게 한다.
class KakaoHospitalRepository implements HospitalRepository {
  KakaoHospitalRepository({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  static const _host = 'dapi.kakao.com';
  static const _fallback = DummyHospitalRepository();

  final KakaoApiConfig config;
  final http.Client _client;

  @override
  Future<List<Hospital>> findNearby(String address) async {
    if (!config.hasKey || address.trim().isEmpty) {
      return _fallback.findNearby(address);
    }
    try {
      final coord = await _geocode(address);
      if (coord == null) return _fallback.findNearby(address);

      final hospitals = await _searchHospitals(coord.$1, coord.$2);
      return hospitals.isEmpty ? _fallback.findNearby(address) : hospitals;
    } on Object {
      return _fallback.findNearby(address);
    }
  }

  Map<String, String> get _headers => {
    'Authorization': 'KakaoAK ${config.restApiKey}',
  };

  /// 주소 → (경도 x, 위도 y). 실패 시 null.
  Future<(String, String)?> _geocode(String address) async {
    final uri = Uri.https(_host, '/v2/local/search/address.json', {
      'query': address,
      'size': '1',
    });
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(config.requestTimeout);
    if (response.statusCode != 200) return null;

    final documents = _documents(response.bodyBytes);
    if (documents.isEmpty) return null;
    final first = documents.first;
    final x = first['x'];
    final y = first['y'];
    if (x is String && y is String) return (x, y);
    return null;
  }

  Future<List<Hospital>> _searchHospitals(String x, String y) async {
    final uri = Uri.https(_host, '/v2/local/search/category.json', {
      'category_group_code': 'HP8',
      'x': x,
      'y': y,
      'radius': '5000',
      'sort': 'distance',
      'size': '15',
    });
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(config.requestTimeout);
    if (response.statusCode != 200) return const [];

    return _documents(response.bodyBytes)
        .map(_toHospital)
        .whereType<Hospital>()
        .toList();
  }

  List<dynamic> _documents(List<int> bodyBytes) {
    final decoded = jsonDecode(utf8.decode(bodyBytes));
    if (decoded is Map<String, dynamic> && decoded['documents'] is List) {
      return decoded['documents'] as List;
    }
    return const [];
  }

  Hospital? _toHospital(dynamic doc) {
    if (doc is! Map<String, dynamic>) return null;
    final name = doc['place_name'] as String?;
    if (name == null || name.isEmpty) return null;

    final road = doc['road_address_name'] as String?;
    final jibun = doc['address_name'] as String?;
    final rawDistance = doc['distance'];
    final meters = rawDistance is int
        ? rawDistance
        : rawDistance is String
        ? int.tryParse(rawDistance)
        : null;

    return Hospital(
      name: name,
      department: _department(doc['category_name'] as String?),
      address: (road != null && road.isNotEmpty ? road : jibun) ?? '',
      distance: _formatDistance(meters),
      phone: doc['phone'] as String? ?? '',
    );
  }

  /// "의료,건강 > 병원 > 내과" → "내과"
  String _department(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) return '병원';
    final parts = categoryName
        .split('>')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && part != '병원')
        .toList();
    return parts.isEmpty ? '병원' : parts.last;
  }

  String _formatDistance(int? meters) {
    if (meters == null) return '';
    if (meters < 1000) return '${meters}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}

/// 키가 없거나 실패했을 때 쓰는 더미 목록. (오프라인/데모 폴백)
class DummyHospitalRepository implements HospitalRepository {
  const DummyHospitalRepository();

  @override
  Future<List<Hospital>> findNearby(String address) async {
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

final kakaoApiConfigProvider = Provider<KakaoApiConfig>(
  (ref) => KakaoApiConfig.fromEnv(),
);

final hospitalRepositoryProvider = Provider<HospitalRepository>(
  (ref) => KakaoHospitalRepository(config: ref.watch(kakaoApiConfigProvider)),
);
