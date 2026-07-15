import 'need_category.dart';

class NeedClassificationResult {
  const NeedClassificationResult({
    required this.categories,
    required this.confidence,
    required this.reason,
    this.preferredDate,
  });

  factory NeedClassificationResult.none({String reason = '분류 가능한 니즈 없음'}) {
    return NeedClassificationResult(
      categories: const [NeedCategory.none],
      confidence: 1,
      reason: reason,
    );
  }

  final List<NeedCategory> categories;
  final double confidence;
  final String reason;

  /// 통화에서 추출된 희망 날짜(있을 때만). 없으면 null → 수동 지정.
  final DateTime? preferredDate;

  bool get hasActionableNeed =>
      categories.any((category) => category != NeedCategory.none);

  NeedCategory get primaryCategory => primaryActionCategory(categories);

  String get labels => categories.map((category) => category.label).join(', ');
}
