import '../classification/need_category.dart';

/// 한 번의 통화 분석 결과 기록. (로컬 저장용 — 나중에 서버/DB로 교체 가능)
class AnalysisRecord {
  AnalysisRecord({
    required this.id,
    required this.createdAt,
    required this.categories,
    required this.reason,
    required this.snippet,
    String? recipientName,
    String? recipientRegion,
    String? serviceType,
    DateTime? callTime,
    String? summary,
  }) : recipientName = _nonEmptyOr(recipientName, '알 수 없음'),
       recipientRegion = recipientRegion?.trim() ?? '',
       serviceType = serviceType?.trim() ?? '',
       callTime = callTime ?? createdAt,
       summary = _nonEmptyOr(summary, reason);

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final categories = rawCategories is List
        ? rawCategories
              .whereType<String>()
              .map(NeedCategoryText.fromApiValue)
              .nonNulls
              .toList()
        : <NeedCategory>[NeedCategory.none];
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final callTime =
        DateTime.tryParse(json['callTime'] as String? ?? '') ?? createdAt;
    return AnalysisRecord(
      id: json['id'] as String? ?? '',
      createdAt: createdAt,
      recipientName: json['recipientName'] as String?,
      recipientRegion: json['recipientRegion'] as String?,
      serviceType: json['serviceType'] as String?,
      callTime: callTime,
      categories: categories.isEmpty ? [NeedCategory.none] : categories,
      reason: json['reason'] as String? ?? '',
      summary: json['summary'] as String?,
      snippet: json['snippet'] as String? ?? '',
    );
  }

  final String id;
  final DateTime createdAt;
  final String recipientName;

  /// 분석 당시 이 통화 상대(부모)의 지역 주소. 대상자별 업체 추천 기준.
  final String recipientRegion;

  /// general 니즈 세부 유형(repair/cleaning/shopping/transport). 업체 카테고리 매핑용.
  final String serviceType;
  final DateTime callTime;
  final List<NeedCategory> categories;
  final String reason;
  final String summary;
  final String snippet;

  bool get hasActionableNeed =>
      categories.any((category) => category != NeedCategory.none);

  NeedCategory get primaryCategory => primaryActionCategory(categories);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'recipientName': recipientName,
      'recipientRegion': recipientRegion,
      'serviceType': serviceType,
      'callTime': callTime.toIso8601String(),
      'categories': categories.map((category) => category.apiValue).toList(),
      'reason': reason,
      'summary': summary,
      'snippet': snippet,
    };
  }

  String relativeTime(DateTime now) {
    final diff = now.difference(callTime);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${callTime.month}월 ${callTime.day}일';
  }

  String callTimeLabel() {
    final hour = callTime.hour.toString().padLeft(2, '0');
    final minute = callTime.minute.toString().padLeft(2, '0');
    return '${callTime.month}월 ${callTime.day}일 $hour:$minute';
  }
}

String _nonEmptyOr(String? value, String fallback) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return fallback;
  return trimmed;
}
