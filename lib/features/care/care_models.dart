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
    return CareRecipient(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      relationship: json['relationship'] as String? ?? '어머니',
      address: json['address'] as String,
      favoriteHospital: json['favoriteHospital'] as String,
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
    required this.title,
    required this.category,
    required this.region,
    required this.distance,
    required this.description,
    required this.status,
    required this.helperCount,
  });

  factory ErrandRequest.fromJson(Map<String, dynamic> json) {
    return ErrandRequest(
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      region: json['region'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      helperCount: json['helperCount'] is int
          ? json['helperCount'] as int
          : int.tryParse('${json['helperCount']}') ?? 0,
    );
  }

  final String title;
  final String category;
  final String region;
  final String distance;
  final String description;
  final String status;
  final int helperCount;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'region': region,
      'distance': distance,
      'description': description,
      'status': status,
      'helperCount': helperCount,
    };
  }
}

class CareExpert {
  const CareExpert({
    required this.name,
    required this.role,
    required this.region,
    required this.rating,
    required this.career,
    required this.availableTime,
    this.reviewCount = 0,
    this.isCertified = false,
    this.rehireRate = 0,
  });

  factory CareExpert.fromJson(Map<String, dynamic> json) {
    double doubleValue(String key) {
      final value = json[key];
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    int intValue(String key) {
      final value = json[key];
      if (value is int) return value;
      return int.tryParse('$value') ?? 0;
    }

    return CareExpert(
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      region: json['region'] as String? ?? '',
      rating: doubleValue('rating'),
      career: json['career'] as String? ?? '',
      availableTime: json['availableTime'] as String? ?? '',
      reviewCount: intValue('reviewCount'),
      isCertified: json['isCertified'] as bool? ?? false,
      rehireRate: intValue('rehireRate'),
    );
  }

  final String name;
  final String role;
  final String region;
  final double rating;
  final String career;
  final String availableTime;
  final int reviewCount;
  final bool isCertified;

  /// 재이용률(%). 0이면 표시하지 않는다.
  final int rehireRate;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'region': region,
      'rating': rating,
      'career': career,
      'availableTime': availableTime,
      'reviewCount': reviewCount,
      'isCertified': isCertified,
      'rehireRate': rehireRate,
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
