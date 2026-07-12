import 'dart:convert';

class CareRecipient {
  const CareRecipient({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.favoriteHospital,
  });

  factory CareRecipient.fromJson(Map<String, dynamic> json) {
    return CareRecipient(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      address: json['address'] as String,
      favoriteHospital: json['favoriteHospital'] as String,
    );
  }

  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final String favoriteHospital;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'favoriteHospital': favoriteHospital,
    };
  }
}

class MyProfile {
  const MyProfile({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    return MyProfile(
      name: json['name'] as String? ?? defaultMyProfile.name,
      phoneNumber:
          json['phoneNumber'] as String? ?? defaultMyProfile.phoneNumber,
      relationship:
          json['relationship'] as String? ?? defaultMyProfile.relationship,
    );
  }

  final String name;
  final String phoneNumber;
  final String relationship;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
    };
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

  final String title;
  final String category;
  final String region;
  final String distance;
  final String description;
  final String status;
  final int helperCount;
}

class CareExpert {
  const CareExpert({
    required this.name,
    required this.role,
    required this.region,
    required this.rating,
    required this.career,
    required this.availableTime,
  });

  final String name;
  final String role;
  final String region;
  final double rating;
  final String career;
  final String availableTime;
}

class RecordingSetupState {
  const RecordingSetupState({required this.isCompleted, this.completedAt});

  factory RecordingSetupState.fromJson(Map<String, dynamic> json) {
    final completedAt = json['completedAt'];
    return RecordingSetupState(
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: completedAt is String
          ? DateTime.tryParse(completedAt)
          : null,
    );
  }

  const RecordingSetupState.incomplete()
    : isCompleted = false,
      completedAt = null;

  final bool isCompleted;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() {
    return {
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

String encodeRecipients(List<CareRecipient> recipients) {
  return jsonEncode(recipients.map((recipient) => recipient.toJson()).toList());
}

List<CareRecipient> decodeRecipients(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List) return defaultCareRecipients;
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(CareRecipient.fromJson)
      .toList();
}

const defaultCareRecipients = [
  CareRecipient(
    id: 'recipient-1',
    name: '김순자',
    phoneNumber: '010-3245-7788',
    address: '전북특별자치도 남원시 향단로 10',
    favoriteHospital: '남원의료원',
  ),
];

const defaultMyProfile = MyProfile(
  name: '이인욱',
  phoneNumber: '010-9876-1234',
  relationship: '자녀',
);

const demoSchedules = [
  CareSchedule(
    title: '남원의료원 정형외과',
    category: '병원',
    dateTimeLabel: '오늘 15:30',
    location: '남원의료원',
    status: '확인 필요',
  ),
  CareSchedule(
    title: '거실 전등 교체',
    category: '심부름',
    dateTimeLabel: '내일 10:00',
    location: '향단로 10',
    status: '2명 가능',
  ),
  CareSchedule(
    title: '방문 복지 상담',
    category: '전문 돌봄',
    dateTimeLabel: '금요일 14:00',
    location: '자택 방문',
    status: '예약됨',
  ),
];

const demoErrands = [
  ErrandRequest(
    title: '남원의료원 진료 동행',
    category: '병원 동행',
    region: '남원시 도통동',
    distance: '1.8km',
    description: '오전 진료 후 약국까지 함께 이동할 분을 찾고 있어요.',
    status: '오늘 가능',
    helperCount: 4,
  ),
  ErrandRequest(
    title: '거실 전등 교체',
    category: '수리',
    region: '남원시 왕정동',
    distance: '2.3km',
    description: '사다리가 필요한 작업이에요. 전구는 미리 준비되어 있습니다.',
    status: '새 요청',
    helperCount: 1,
  ),
  ErrandRequest(
    title: '전주 병원 이동 도움',
    category: '교통',
    region: '남원 → 전주',
    distance: '49km',
    description: '오전 8:40 출발 예정입니다. 보호자 동승도 문의 가능해요.',
    status: '동승 가능',
    helperCount: 3,
  ),
  ErrandRequest(
    title: '쌀과 생필품 장보기',
    category: '장보기',
    region: '남원시 금동',
    distance: '900m',
    description: '쌀 10kg과 세제처럼 무거운 물품 위주로 부탁드려요.',
    status: '근처 요청',
    helperCount: 2,
  ),
];

const demoExperts = [
  CareExpert(
    name: '박지영',
    role: '방문 사회복지사',
    region: '남원시 전역',
    rating: 4.9,
    career: '복지 상담 8년',
    availableTime: '오늘 17:00 전화 상담',
  ),
  CareExpert(
    name: '이정호',
    role: '요양보호사',
    region: '도통동 · 왕정동',
    rating: 4.8,
    career: '방문 돌봄 6년',
    availableTime: '내일 10:30 방문 가능',
  ),
  CareExpert(
    name: '최민서',
    role: '병원 동행 매니저',
    region: '남원 · 전주',
    rating: 4.7,
    career: '동행 320건',
    availableTime: '이번 주 화·목 가능',
  ),
];
