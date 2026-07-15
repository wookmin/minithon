import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/care/care_models.dart';

ErrandRequest _sample({List<String> helpers = const []}) => ErrandRequest(
  title: '장보기 도움',
  category: '장보기',
  region: '강남구 역삼동',
  distance: '내 주변',
  description: '저녁 장보기가 필요해요.',
  status: '모집중',
  helpers: helpers,
);

void main() {
  test('helperCount는 helpers 길이에서 파생된다', () {
    expect(_sample(helpers: const ['a', 'b']).helperCount, 2);
    expect(_sample().helperCount, 0);
  });

  test('hasApplied는 지원한 uid에만 true', () {
    final errand = _sample(helpers: const ['u1']);
    expect(errand.hasApplied('u1'), isTrue);
    expect(errand.hasApplied('u2'), isFalse);
    expect(errand.hasApplied(''), isFalse);
  });

  test('helpers를 직렬화·역직렬화하고 helperCount도 함께 저장한다', () {
    final json = _sample(helpers: const ['u1', 'u2']).toJson();
    expect(json['helpers'], ['u1', 'u2']);
    expect(json['helperCount'], 2);
    final restored = ErrandRequest.fromJson(json);
    expect(restored.helpers, ['u1', 'u2']);
    expect(restored.helperCount, 2);
  });

  test('구버전 문서(helpers 없음)는 빈 목록으로 복원한다', () {
    final restored = ErrandRequest.fromJson({'title': 't', 'helperCount': 5});
    expect(restored.helpers, isEmpty);
    expect(restored.helperCount, 0);
  });
}
