import 'dart:convert';

class CareRecipient {
  const CareRecipient({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.address,
    required this.favoriteHospital,
  });

  factory CareRecipient.fromJson(Map<String, dynamic> json) {
    // 구버전/부분 문서에도 견디도록 모든 필드에 안전 기본값을 둔다.
    // (필드 하나가 빠져 throw되면 대상자 목록 전체 로딩이 실패하기 때문)
    return CareRecipient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '어머니',
      address: json['address'] as String? ?? '',
      favoriteHospital: json['favoriteHospital'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final String address;
  final String favoriteHospital;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'address': address,
      'favoriteHospital': favoriteHospital,
    };
  }
}

class MyProfile {
  const MyProfile({
    required this.name,
    required this.phoneNumber,
    this.address = '',
  });

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    return MyProfile(
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  final String name;
  final String phoneNumber;

  /// 내 거주지 주소. 이 지역의 구인글을 수락(지원)할 수 있다. (부모 지역과 구분)
  final String address;

  MyProfile copyWith({String? name, String? phoneNumber, String? address}) {
    return MyProfile(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'phoneNumber': phoneNumber, 'address': address};
  }
}

class ErrandRequest {
  const ErrandRequest({
    this.id = '',
    required this.title,
    required this.category,
    required this.region,
    required this.distance,
    required this.description,
    required this.status,
    this.helpers = const [],
    this.requesterUid = '',
    this.requesterName = '',
    this.createdAt,
  });

  factory ErrandRequest.fromJson(Map<String, dynamic> json) {
    return ErrandRequest(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      region: json['region'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      helpers:
          (json['helpers'] as List?)
              ?.map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toList() ??
          const [],
      requesterUid: json['requesterUid'] as String? ?? '',
      requesterName: json['requesterName'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  final String id;
  final String title;
  final String category;
  final String region;
  final String distance;
  final String description;
  final String status;

  /// 지원한 사용자 uid 목록.
  final List<String> helpers;
  final String requesterUid;
  final String requesterName;
  final DateTime? createdAt;

  /// 지원자 수 ([helpers]에서 파생).
  int get helperCount => helpers.length;

  /// 해당 사용자가 이미 지원했는지.
  bool hasApplied(String uid) => uid.isNotEmpty && helpers.contains(uid);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'region': region,
      'distance': distance,
      'description': description,
      'status': status,
      'helpers': helpers,
      // 호환·쿼리용으로 파생값도 함께 저장한다(표시는 helpers.length 기준).
      'helperCount': helperCount,
      'requesterUid': requesterUid,
      'requesterName': requesterName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class RecordingSetupState {
  const RecordingSetupState({
    required this.isCompleted,
    required this.backgroundDetectionEnabled,
    this.completedAt,
  });

  factory RecordingSetupState.fromJson(Map<String, dynamic> json) {
    final completedAt = json['completedAt'];
    return RecordingSetupState(
      isCompleted: json['isCompleted'] as bool? ?? false,
      backgroundDetectionEnabled:
          json['backgroundDetectionEnabled'] as bool? ?? false,
      completedAt: completedAt is String
          ? DateTime.tryParse(completedAt)
          : null,
    );
  }

  const RecordingSetupState.incomplete()
    : isCompleted = false,
      backgroundDetectionEnabled = false,
      completedAt = null;

  final bool isCompleted;
  final bool backgroundDetectionEnabled;
  final DateTime? completedAt;

  RecordingSetupState copyWith({
    bool? isCompleted,
    bool? backgroundDetectionEnabled,
    DateTime? completedAt,
  }) {
    return RecordingSetupState(
      isCompleted: isCompleted ?? this.isCompleted,
      backgroundDetectionEnabled:
          backgroundDetectionEnabled ?? this.backgroundDetectionEnabled,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCompleted': isCompleted,
      'backgroundDetectionEnabled': backgroundDetectionEnabled,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

String encodeRecipients(List<CareRecipient> recipients) {
  return jsonEncode(recipients.map((recipient) => recipient.toJson()).toList());
}

List<CareRecipient> decodeRecipients(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List) return const [];
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(CareRecipient.fromJson)
      .toList();
}
