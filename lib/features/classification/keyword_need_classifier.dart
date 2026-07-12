import 'need_category.dart';
import 'need_classification_result.dart';
import 'need_classifier.dart';

/// 규칙(키워드) 기반 니즈 분류기.
///
/// 우선순위: 전문 > 병원 > 일반 (더 구체적인 돌봄 니즈를 먼저 잡는다).
/// 어떤 키워드에도 걸리지 않으면 [NeedCategory.none] → 알림 없음.
class KeywordNeedClassifier implements NeedClassifier {
  const KeywordNeedClassifier();

  static const List<String> _professionalKeywords = [
    '혼자 못',
    '혼자서 못',
    '거동',
    '요양',
    '복지',
    '우울',
    '외롭',
    '돌봄',
    '치매',
    '간병',
  ];

  static const List<String> _hospitalKeywords = [
    '아프',
    '아파',
    '통증',
    '허리',
    '무릎',
    '어지럽',
    '병원',
    '약',
    '열이',
    '숨차',
    '어깨',
    '쑤셔',
    '진료',
  ];

  static const List<String> _generalKeywords = [
    '전등',
    '형광등',
    '전구',
    '고쳐',
    '고쳐야',
    '장보',
    '무겁',
    '청소',
    '심부름',
    '문이 안',
    '수리',
  ];

  @override
  Future<NeedClassificationResult> classify(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return NeedClassificationResult.none(reason: '빈 텍스트');
    }

    final categories = <NeedCategory>[];
    if (_matchesAny(normalized, _professionalKeywords)) {
      categories.add(NeedCategory.professional);
    }
    if (_matchesAny(normalized, _hospitalKeywords)) {
      categories.add(NeedCategory.hospital);
    }
    if (_matchesAny(normalized, _generalKeywords)) {
      categories.add(NeedCategory.general);
    }
    if (categories.isEmpty) return NeedClassificationResult.none();

    return NeedClassificationResult(
      categories: categories,
      confidence: 0.7,
      reason: '키워드 기반 예비 분류',
    );
  }

  bool _matchesAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }
}
