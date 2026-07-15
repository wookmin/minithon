import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/core/notifications/notification_service.dart';

void main() {
  test('quota 계열 사유는 사용량 한도 안내로 변환한다', () {
    const quotaReasons = [
      '전사 실패: RESOURCE_EXHAUSTED',
      'Quota exceeded for quota metric',
      '전사 실패: 429 Too Many Requests',
      'rate limit reached',
    ];
    for (final reason in quotaReasons) {
      expect(
        analysisFailureMessage(reason),
        'AI 사용량 한도를 초과했어요. 잠시 후 다시 시도해 주세요.',
      );
    }
  });

  test('일반 사유는 원문을 다듬어 그대로 보여준다', () {
    expect(analysisFailureMessage('  전사 결과가 비어 있습니다  '), '전사 결과가 비어 있습니다');
  });

  test('빈 사유는 기본 문구로 대체한다', () {
    expect(analysisFailureMessage('   '), '알 수 없는 오류로 분석에 실패했어요.');
  });
}
