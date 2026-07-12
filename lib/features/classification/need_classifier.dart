import 'need_classification_result.dart';

/// 텍스트를 니즈 카테고리로 분류하는 경계 인터페이스.
///
/// 이번 단계는 [KeywordNeedClassifier](규칙 기반) 구현을 쓰지만,
/// 다음 단계에서 LLM 기반 구현으로 교체할 수 있도록 시그니처를
/// `Future`로 고정한다. (호출부 변경 없이 async 구현 주입 가능)
abstract interface class NeedClassifier {
  Future<NeedClassificationResult> classify(String text);
}
