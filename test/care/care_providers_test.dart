import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/care/care_models.dart';
import 'package:senior_needs/features/care/care_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> containerWithPrefs() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  test('돌봄 대상자를 로컬 저장 provider에 저장한다', () async {
    final container = await containerWithPrefs();
    addTearDown(container.dispose);

    final initial = await container.read(careRecipientsProvider.future);
    expect(initial.first.name, '김순자');

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

  test('내 정보를 로컬 저장 provider에 저장한다', () async {
    final container = await containerWithPrefs();
    addTearDown(container.dispose);

    final initial = await container.read(myProfileProvider.future);
    expect(initial.name, '이인욱');

    const profile = MyProfile(name: '홍길동', phoneNumber: '010-3333-4444');

    await container.read(myProfileProvider.notifier).save(profile);

    final saved = container.read(myProfileProvider).asData!.value;
    expect(saved.name, '홍길동');
    expect(saved.phoneNumber, '010-3333-4444');
  });
}
