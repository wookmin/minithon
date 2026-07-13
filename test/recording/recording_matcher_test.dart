import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/care/care_models.dart';
import 'package:senior_needs/features/recording/recording_candidate.dart';
import 'package:senior_needs/features/recording/recording_matcher.dart';

void main() {
  const matcher = RecordingMatcher();
  const recipients = [
    CareRecipient(
      id: 'recipient-1',
      name: '김순자',
      phoneNumber: '010-3245-7788',
      relationship: '어머니',
      address: '서울시 강남구 테헤란로 1',
      favoriteHospital: '가까운 병원',
    ),
  ];

  test('파일명 속 전화번호로 등록된 돌봄자를 매칭한다', () {
    final candidate = matcher.match(
      filePath: '/storage/emulated/0/Recordings/Call/Call_010-3245-7788.m4a',
      sourceType: RecordingImportSourceType.folderScan,
      recipients: recipients,
    );

    expect(candidate.matchType, RecordingMatchType.phone);
    expect(candidate.matchedRecipient?.name, '김순자');
    expect(candidate.isMatched, isTrue);
  });

  test('국가번호가 붙은 전화번호도 같은 돌봄자로 매칭한다', () {
    final candidate = matcher.match(
      filePath: '/recordings/+82 10 3245 7788_20260712.m4a',
      sourceType: RecordingImportSourceType.manual,
      recipients: recipients,
    );

    expect(candidate.matchType, RecordingMatchType.phone);
    expect(candidate.matchedRecipient?.name, '김순자');
  });

  test('전화번호가 없으면 파일명 속 이름으로 보조 매칭한다', () {
    final candidate = matcher.match(
      filePath: '/recordings/2026-07-12_김순자_안부전화.m4a',
      sourceType: RecordingImportSourceType.manual,
      recipients: recipients,
    );

    expect(candidate.matchType, RecordingMatchType.name);
    expect(candidate.matchedRecipient?.name, '김순자');
  });

  test('이름에 공백이 있어도 삼성 통화녹음 파일명과 매칭한다', () {
    const spaced = [
      CareRecipient(
        id: 'recipient-2',
        name: '멋사 조현욱',
        phoneNumber: '010-7577-8343',
        relationship: '아버지',
        address: '서울시 강남구 테헤란로 1',
        favoriteHospital: '가까운 병원',
      ),
    ];

    final candidate = matcher.match(
      filePath: '/storage/emulated/0/Recordings/Call/',
      displayName: '통화 녹음 멋사 조현욱_260713_203441.m4a',
      sourceType: RecordingImportSourceType.folderScan,
      recipients: spaced,
    );

    expect(candidate.matchType, RecordingMatchType.name);
    expect(candidate.matchedRecipient?.name, '멋사 조현욱');
    expect(candidate.isMatched, isTrue);
  });

  test('등록된 정보와 맞지 않는 녹음은 분석 대상으로 보지 않는다', () {
    final candidate = matcher.match(
      filePath: '/recordings/unknown_010-9999-8888.m4a',
      sourceType: RecordingImportSourceType.manual,
      recipients: recipients,
    );

    expect(candidate.matchType, RecordingMatchType.none);
    expect(candidate.matchedRecipient, isNull);
    expect(candidate.isMatched, isFalse);
  });
}
