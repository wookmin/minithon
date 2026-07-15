import 'package:cloud_functions/cloud_functions.dart';

import '../../core/functions/functions_client.dart';
import 'need_category.dart';
import 'need_classification_result.dart';
import 'need_classifier.dart';

/// 서버(classifyNeed 함수)가 Gemini 분류를 수행하고, 앱은 결과만 받아 해석한다.
/// Gemini API 키는 서버 시크릿으로만 존재하며 앱 번들에 포함되지 않는다.
class FunctionsNeedClassifier implements NeedClassifier {
  FunctionsNeedClassifier({required this.invoke});

  static const _confidenceThreshold = 0.6;

  final CallableInvoker invoke;

  @override
  Future<NeedClassificationResult> classify(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return NeedClassificationResult.none(reason: '빈 텍스트');
    }

    try {
      final now = DateTime.now();
      final today =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final payload = await invoke('classifyNeed', {
        'text': normalized,
        'today': today,
      });
      return _parse(payload);
    } on FirebaseFunctionsException catch (error) {
      return NeedClassificationResult.failure(
        'Gemini 분류 실패: ${error.message ?? error.code}',
      );
    } on Object catch (error) {
      return NeedClassificationResult.failure('Gemini 분류 실패: $error');
    }
  }

  NeedClassificationResult _parse(Map<String, dynamic> payload) {
    final confidenceValue = payload['confidence'];
    final confidence = confidenceValue is num ? confidenceValue.toDouble() : 0.0;
    if (confidence < _confidenceThreshold) {
      return NeedClassificationResult.none(reason: '분류 신뢰도 낮음');
    }

    final rawCategories = payload['categories'];
    if (rawCategories is! List) {
      return NeedClassificationResult.failure('카테고리 형식 오류');
    }

    final categories = rawCategories
        .whereType<String>()
        .map(NeedCategoryText.fromApiValue)
        .nonNulls
        .toSet()
        .toList();
    final normalizedCategories = _normalizeCategories(categories);
    final reason = payload['reason'] is String
        ? (payload['reason'] as String).trim()
        : 'Gemini 구조화 분류';

    if (normalizedCategories.length == 1 &&
        normalizedCategories.first == NeedCategory.none) {
      return NeedClassificationResult.none(
        reason: reason.isEmpty ? '분류 가능한 니즈 없음' : reason,
      );
    }

    return NeedClassificationResult(
      categories: normalizedCategories,
      confidence: confidence,
      reason: reason.isEmpty ? 'Gemini 구조화 분류' : reason,
      preferredDate: _parseDate(payload['preferredDate']),
      serviceType: (payload['serviceType'] as String?)?.trim() ?? '',
    );
  }

  /// 서버가 준 preferredDate(YYYY-MM-DD 또는 빈 문자열)를 날짜로 해석한다.
  DateTime? _parseDate(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  List<NeedCategory> _normalizeCategories(List<NeedCategory> categories) {
    final actionable = categories
        .where((category) => category != NeedCategory.none)
        .toSet()
        .toList();
    if (actionable.isEmpty) return const [NeedCategory.none];

    actionable.sort((a, b) => _priority(a).compareTo(_priority(b)));
    return actionable;
  }

  int _priority(NeedCategory category) {
    switch (category) {
      case NeedCategory.professional:
        return 0;
      case NeedCategory.hospital:
        return 1;
      case NeedCategory.general:
        return 2;
      case NeedCategory.none:
        return 3;
    }
  }
}
