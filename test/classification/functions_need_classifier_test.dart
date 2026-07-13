import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/classification/functions_need_classifier.dart';
import 'package:senior_needs/features/classification/need_category.dart';

void main() {
  FunctionsNeedClassifier classifierReturning(Map<String, dynamic> payload) {
    return FunctionsNeedClassifier(
      invoke: (name, data) async {
        expect(name, 'classifyNeed');
        expect(data['text'], isNotEmpty);
        return payload;
      },
    );
  }

  test('복수 카테고리를 우선순위대로 정렬해 파싱한다', () async {
    final classifier = classifierReturning({
      'categories': ['hospital', 'general'],
      'confidence': 0.91,
      'reason': '허리 통증과 전등 수리를 함께 언급',
    });

    final result = await classifier.classify('허리도 아프고 전등도 나갔어');

    expect(result.categories, [NeedCategory.hospital, NeedCategory.general]);
    expect(result.hasActionableNeed, isTrue);
  });

  test('none이 다른 카테고리와 섞이면 actionable 카테고리만 남긴다', () async {
    final classifier = classifierReturning({
      'categories': ['none', 'general'],
      'confidence': 0.85,
      'reason': '전등 교체 요청',
    });

    final result = await classifier.classify('전등을 고쳐야 한다');

    expect(result.categories, [NeedCategory.general]);
  });

  test('신뢰도가 임계값 미만이면 none으로 폴백한다', () async {
    final classifier = classifierReturning({
      'categories': ['hospital'],
      'confidence': 0.3,
      'reason': '애매함',
    });

    final result = await classifier.classify('허리가 조금 뻐근한가');

    expect(result.categories, [NeedCategory.none]);
    expect(result.hasActionableNeed, isFalse);
  });

  test('빈 텍스트는 서버 호출 없이 none을 반환한다', () async {
    var called = false;
    final classifier = FunctionsNeedClassifier(
      invoke: (name, data) async {
        called = true;
        return {};
      },
    );

    final result = await classifier.classify('   ');

    expect(called, isFalse);
    expect(result.categories, [NeedCategory.none]);
  });

  test('서버 오류는 none으로 폴백한다', () async {
    final classifier = FunctionsNeedClassifier(
      invoke: (name, data) async => throw Exception('unavailable'),
    );

    final result = await classifier.classify('허리가 아프다');

    expect(result.categories, [NeedCategory.none]);
    expect(result.hasActionableNeed, isFalse);
  });
}
