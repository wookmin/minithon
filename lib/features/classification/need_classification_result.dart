import 'need_category.dart';

class NeedClassificationResult {
  const NeedClassificationResult({
    required this.categories,
    required this.confidence,
    required this.reason,
    this.preferredDate,
    this.failed = false,
    this.serviceType = '',
  });

  factory NeedClassificationResult.none({String reason = '분류 가능한 니즈 없음'}) {
    return NeedClassificationResult(
      categories: const [NeedCategory.none],
      confidence: 1,
      reason: reason,
    );
  }

  /// 분류 자체가 실패한 상태(503·빈 응답·파싱 실패 등).
  /// '니즈 없음'(none)과 구분해, 처리 완료로 기록하지 않고 재시도할 수 있게 한다.
  factory NeedClassificationResult.failure(String reason) {
    return NeedClassificationResult(
      categories: const [NeedCategory.none],
      confidence: 0,
      reason: reason,
      failed: true,
    );
  }

  final List<NeedCategory> categories;
  final double confidence;
  final String reason;

  /// 통화에서 추출된 희망 날짜(있을 때만). 없으면 null → 수동 지정.
  final DateTime? preferredDate;

  /// 분류가 실패했는지. true면 니즈 없음이 아니라 '판단 불가'다.
  final bool failed;

  /// general 니즈의 세부 유형(repair/cleaning/shopping/transport). 없으면 빈 값.
  final String serviceType;

  bool get hasActionableNeed =>
      categories.any((category) => category != NeedCategory.none);

  NeedCategory get primaryCategory => primaryActionCategory(categories);

  String get labels => categories.map((category) => category.label).join(', ');
}
