/// 지역 전문 업체(지역 상권 입점). 검색이 어려운 부모님을 대신해
/// AI가 통화 니즈에 맞는 업체를 매칭·연결한다. 연결 건당 수수료가 수익원.
class LocalBusiness {
  const LocalBusiness({
    required this.id,
    required this.name,
    required this.category,
    required this.region,
    required this.phone,
    required this.description,
    required this.rating,
    required this.feeWon,
  });

  factory LocalBusiness.fromJson(Map<String, dynamic> json) {
    final ratingValue = json['rating'];
    final feeValue = json['feeWon'];
    return LocalBusiness(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      region: json['region'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rating: ratingValue is num
          ? ratingValue.toDouble()
          : double.tryParse('$ratingValue') ?? 0,
      feeWon: feeValue is num ? feeValue.toInt() : int.tryParse('$feeValue') ?? 0,
    );
  }

  final String id;
  final String name;

  /// 업체 카테고리. [businessCategories] 중 하나.
  final String category;

  /// 활동 지역(시/군/구 문자열).
  final String region;
  final String phone;
  final String description;
  final double rating;

  /// 연결 건당 수수료(원). 데모 표시용.
  final int feeWon;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'region': region,
      'phone': phone,
      'description': description,
      'rating': rating,
      'feeWon': feeWon,
    };
  }
}

/// 입점 업체 카테고리.
const businessCategories = <String>['수리', '청소', '장보기', '병원 동행', '간병'];
