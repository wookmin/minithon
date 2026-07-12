import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/classification/keyword_need_classifier.dart';
import 'package:senior_needs/features/classification/need_category.dart';

void main() {
  const classifier = KeywordNeedClassifier();

  group('KeywordNeedClassifier', () {
    test('"허리가 아프다" → hospital', () async {
      final result = await classifier.classify('허리가 아프다');
      expect(result.categories, [NeedCategory.hospital]);
    });

    test('"전등을 고쳐야 한다" → general', () async {
      final result = await classifier.classify('전등을 고쳐야 한다');
      expect(result.categories, [NeedCategory.general]);
    });

    test('잡담 → none', () async {
      final result = await classifier.classify('오늘 날씨 좋네 밥 먹었어');
      expect(result.categories, [NeedCategory.none]);
    });

    test('빈 문자열 → none', () async {
      expect((await classifier.classify('')).categories, [NeedCategory.none]);
      expect((await classifier.classify('   ')).categories, [
        NeedCategory.none,
      ]);
    });

    test('복수 니즈를 함께 반환', () async {
      final result = await classifier.classify('혼자 못 일어나겠고 여기저기 아프다');
      expect(result.categories, [
        NeedCategory.professional,
        NeedCategory.hospital,
      ]);
    });

    test('요양/돌봄 니즈 → professional', () async {
      final result = await classifier.classify('요양보호사가 필요할 것 같아');
      expect(result.categories, [NeedCategory.professional]);
    });
  });
}
