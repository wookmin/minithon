import 'dart:convert';

class CareRecipient {
  const CareRecipient({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.address,
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
    );
  }

  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final String address;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'address': address,
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
