import '../classification/need_category.dart';

/// 한 번의 통화 분석 결과 기록. (로컬 저장용 — 나중에 서버/DB로 교체 가능)
class AnalysisRecord {
  const AnalysisRecord({
    required this.id,
    required this.createdAt,
    required this.categories,
    required this.reason,
    required this.snippet,
  });

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final categories = rawCategories is List
        ? rawCategories
              .whereType<String>()
              .map(NeedCategoryText.fromApiValue)
              .nonNulls
              .toList()
        : <NeedCategory>[NeedCategory.none];
    return AnalysisRecord(
      id: json['id'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      categories: categories.isEmpty ? [NeedCategory.none] : categories,
      reason: json['reason'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
    );
  }

  final String id;
  final DateTime createdAt;
  final List<NeedCategory> categories;
  final String reason;
  final String snippet;

  bool get hasActionableNeed =>
      categories.any((category) => category != NeedCategory.none);

  NeedCategory get primaryCategory => primaryActionCategory(categories);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'categories': categories.map((category) => category.apiValue).toList(),
      'reason': reason,
      'snippet': snippet,
    };
  }

  String relativeTime(DateTime now) {
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${createdAt.month}월 ${createdAt.day}일';
  }
}
