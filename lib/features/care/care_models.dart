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
  const MyProfile({required this.name, required this.phoneNumber});

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    return MyProfile(
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }

  final String name;
  final String phoneNumber;

  Map<String, dynamic> toJson() {
    return {'name': name, 'phoneNumber': phoneNumber};
  }
}

class CareSchedule {
  const CareSchedule({
    required this.title,
    required this.category,
    required this.dateTimeLabel,
    required this.location,
    required this.status,
  });

  final String title;
  final String category;
  final String dateTimeLabel;
  final String location;
  final String status;
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
    required this.helperCount,
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
      helperCount: json['helperCount'] is int
          ? json['helperCount'] as int
          : int.tryParse('${json['helperCount']}') ?? 0,
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
  final int helperCount;
  final String requesterUid;
  final String requesterName;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'region': region,
      'distance': distance,
      'description': description,
      'status': status,
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
