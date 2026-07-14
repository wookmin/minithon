import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/core/firebase/firebase_providers.dart';
import 'package:senior_needs/features/auth/auth_providers.dart';
import 'package:senior_needs/features/auth/auth_repository.dart';
import 'package:senior_needs/features/care/care_models.dart';
import 'package:senior_needs/features/care/care_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> containerWithPrefs() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseFirestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        currentUidProvider.overrideWithValue('test-uid'),
        authStateProvider.overrideWith((ref) => Stream<AppUser?>.value(null)),
      ],
    );
  }

  test('돌봄 대상자를 로컬 저장 provider에 저장한다', () async {
    final container = await containerWithPrefs();
    addTearDown(container.dispose);

    final initial = await container.read(careRecipientsProvider.future);
    expect(initial, isEmpty);

    const recipient = CareRecipient(
      id: 'recipient-2',
      name: '박영수',
      phoneNumber: '010-1111-2222',
      relationship: '아버지',
      address: '서울시 송파구 올림픽로 1',
      favoriteHospital: '서울아산병원',
    );

    await container.read(careRecipientsProvider.notifier).save(recipient);

    final saved = container.read(careRecipientsProvider).asData!.value;
    expect(saved.map((item) => item.name), contains('박영수'));
    expect(saved.length, 1);
  });

  test('CareRecipient.fromJson은 누락 필드에도 throw 없이 기본값을 채운다', () {
    final recipient = CareRecipient.fromJson(const {
      'id': 'r1',
      'name': '김순자',
      'phoneNumber': '010-1234-5678',
      // address / relationship / favoriteHospital 누락(구버전 문서)
    });

    expect(recipient.address, '');
    expect(recipient.relationship, '어머니');
    expect(recipient.favoriteHospital, '');
  });

  test('손상 문서(식별자·이름 없음)는 목록에서 제외되고 나머지는 정상 로드된다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final firestore = FakeFirebaseFirestore();
    final recipients = firestore
        .collection('users')
        .doc('test-uid')
        .collection('recipients');
    // 정상 문서
    await recipients.doc('good').set(const {
      'id': 'good',
      'name': '박영수',
      'phoneNumber': '010-1111-2222',
      'relationship': '아버지',
      'address': '서울시 송파구 올림픽로 1',
      'favoriteHospital': '서울아산병원',
    });
    // 구버전 부분 문서(주소 등 누락) — throw 없이 로드돼야 함
    await recipients.doc('legacy').set(const {
      'id': 'legacy',
      'name': '김순자',
      'phoneNumber': '010-3333-4444',
    });
    // 손상 문서(식별자·이름 없음) — 제외돼야 함
    await recipients.doc('broken').set(const {'phoneNumber': '010-0000-0000'});

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseFirestoreProvider.overrideWithValue(firestore),
        currentUidProvider.overrideWithValue('test-uid'),
        authStateProvider.overrideWith((ref) => Stream<AppUser?>.value(null)),
      ],
    );
    addTearDown(container.dispose);

    final loaded = await container.read(careRecipientsProvider.future);
    expect(loaded.map((r) => r.id), containsAll(['good', 'legacy']));
    expect(loaded.any((r) => r.id.isEmpty), isFalse);
    expect(loaded.length, 2);
  });

  test('자동녹음 등록 완료 상태를 저장한다', () async {
    final container = await containerWithPrefs();
    addTearDown(container.dispose);

    final initial = await container.read(recordingSetupProvider.future);
    expect(initial.isCompleted, isFalse);

    await container.read(recordingSetupProvider.notifier).complete();

    final completed = container.read(recordingSetupProvider).asData!.value;
    expect(completed.isCompleted, isTrue);
    expect(completed.backgroundDetectionEnabled, isTrue);
    expect(completed.completedAt, isNotNull);

    await container
        .read(recordingSetupProvider.notifier)
        .setBackgroundDetectionEnabled(false);

    final disabled = container.read(recordingSetupProvider).asData!.value;
    expect(disabled.backgroundDetectionEnabled, isFalse);
  });

  test('심부름 요청을 Firestore에 저장하고 최신순으로 로드한다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final firestore = FakeFirebaseFirestore();
    final now = DateTime(2026, 7, 14, 12);

    final oldRequest = ErrandRequest(
      id: 'old-request',
      title: '장보기 도움',
      category: '장보기',
      region: '마포구 공덕동',
      distance: '1.2km',
      description: '저녁 장보기가 필요해요.',
      status: '모집중',
      helperCount: 1,
      createdAt: now.subtract(const Duration(hours: 2)),
    );
    await firestore
        .collection('errands')
        .doc(oldRequest.id)
        .set(oldRequest.toJson());

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseFirestoreProvider.overrideWithValue(firestore),
        currentUidProvider.overrideWithValue('test-uid'),
        authStateProvider.overrideWith((ref) => Stream<AppUser?>.value(null)),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(errandRequestsProvider.future);
    expect(initial.single.id, 'old-request');

    final newRequest = ErrandRequest(
      id: 'new-request',
      title: '전등 교체가 필요해요',
      category: '수리',
      region: '마포구 아현동',
      distance: '내 주변',
      description: '거실 전등이 나갔어요.',
      status: '모집중',
      helperCount: 0,
      requesterUid: 'test-uid',
      requesterName: '홍길동',
      createdAt: now,
    );

    await container.read(errandRequestsProvider.notifier).add(newRequest);

    final savedDoc = await firestore
        .collection('errands')
        .doc('new-request')
        .get();
    expect(savedDoc.data()?['title'], '전등 교체가 필요해요');

    final loaded = container.read(errandRequestsProvider).asData!.value;
    expect(loaded.map((request) => request.id), ['new-request', 'old-request']);
  });

  test('내 정보를 로컬 저장 provider에 저장한다', () async {
    final container = await containerWithPrefs();
    addTearDown(container.dispose);

    final initial = await container.read(myProfileProvider.future);
    expect(initial.name, '사용자');

    const profile = MyProfile(name: '홍길동', phoneNumber: '010-3333-4444');

    await container.read(myProfileProvider.notifier).save(profile);

    final saved = container.read(myProfileProvider).asData!.value;
    expect(saved.name, '홍길동');
    expect(saved.phoneNumber, '010-3333-4444');
  });
}
