import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/analysis/analysis_record.dart';
import 'package:senior_needs/features/classification/need_category.dart';

void main() {
  test('recipientRegion을 직렬화·역직렬화한다', () {
    final record = AnalysisRecord(
      id: '1',
      createdAt: DateTime(2026, 7, 16),
      categories: const [NeedCategory.hospital],
      reason: '병원 동행 필요',
      snippet: '허리가 아프다',
      recipientName: '어머니',
      recipientRegion: '부산 해운대구 1',
    );
    final restored = AnalysisRecord.fromJson(record.toJson());
    expect(restored.recipientRegion, '부산 해운대구 1');
  });

  test('recipientRegion 누락(구버전)이면 빈 문자열', () {
    final restored = AnalysisRecord.fromJson({
      'id': '1',
      'recipientName': '어머니',
      'reason': 'r',
      'snippet': 's',
    });
    expect(restored.recipientRegion, '');
  });
}
