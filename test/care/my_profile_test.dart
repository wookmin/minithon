import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/care/care_models.dart';

void main() {
  test('address(내 거주지)를 직렬화·역직렬화한다', () {
    const profile = MyProfile(
      name: '이민욱',
      phoneNumber: '010-1234-5678',
      address: '서울 강남구 테헤란로 1',
    );
    final restored = MyProfile.fromJson(profile.toJson());
    expect(restored.name, '이민욱');
    expect(restored.phoneNumber, '010-1234-5678');
    expect(restored.address, '서울 강남구 테헤란로 1');
  });

  test('address 누락(구버전 문서)이면 빈 문자열로 안전하게 복원한다', () {
    final restored = MyProfile.fromJson({
      'name': '홍길동',
      'phoneNumber': '010-0000-0000',
    });
    expect(restored.address, '');
  });

  test('copyWith는 지정한 필드만 바꾸고 나머지는 유지한다', () {
    const profile = MyProfile(name: '이민욱', phoneNumber: '010', address: '강남');
    final updated = profile.copyWith(address: '마포');
    expect(updated.name, '이민욱');
    expect(updated.phoneNumber, '010');
    expect(updated.address, '마포');
  });
}
