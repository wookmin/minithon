import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/functions/functions_client.dart';
import 'hospital.dart';

/// 근처 병원 조회 경계 인터페이스.
abstract interface class HospitalRepository {
  Future<List<Hospital>> findNearby(String address);
}

/// 서버(nearbyHospitals 함수)가 카카오 지오코딩 + 병원(HP8) 조회를 수행하고,
/// 앱은 반환된 카카오 문서를 매핑한다. 카카오 REST 키는 서버 시크릿으로만 존재한다.
class FunctionsHospitalRepository implements HospitalRepository {
  FunctionsHospitalRepository({required this.invoke});

  final CallableInvoker invoke;

  @override
  Future<List<Hospital>> findNearby(String address) async {
    final query = address.trim();
    if (query.isEmpty) return const [];
    try {
      final data = await invoke('nearbyHospitals', {'address': query});
      final documents = data['hospitals'];
      if (documents is! List) return const [];
      return documents.map(_toHospital).whereType<Hospital>().toList();
    } on FirebaseFunctionsException {
      return const [];
    } on Object {
      return const [];
    }
  }

  Hospital? _toHospital(dynamic doc) {
    if (doc is! Map) return null;
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
      latitude: _doubleValue(doc['y']),
      longitude: _doubleValue(doc['x']),
    );
  }

  double? _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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

final hospitalRepositoryProvider = Provider<HospitalRepository>(
  (ref) =>
      FunctionsHospitalRepository(invoke: ref.watch(callableInvokerProvider)),
);
