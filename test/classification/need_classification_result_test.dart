import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/classification/need_category.dart';
import 'package:senior_needs/features/classification/need_classification_result.dart';

void main() {
  test('failure는 실패 상태이며 니즈 없음(none)과 구분된다', () {
    final failure = NeedClassificationResult.failure('Gemini 503');
    expect(failure.failed, isTrue);
    expect(failure.hasActionableNeed, isFalse);
    expect(failure.reason, 'Gemini 503');
  });

  test('none은 실패가 아니다', () {
    final none = NeedClassificationResult.none();
    expect(none.failed, isFalse);
    expect(none.hasActionableNeed, isFalse);
  });

  test('니즈 있는 결과는 실패가 아니고 actionable', () {
    const result = NeedClassificationResult(
      categories: [NeedCategory.hospital],
      confidence: 0.9,
      reason: '병원',
    );
    expect(result.failed, isFalse);
    expect(result.hasActionableNeed, isTrue);
  });
}
