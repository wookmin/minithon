import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/core/firebase/firebase_providers.dart';
import 'package:senior_needs/features/analysis/analysis_history_providers.dart';
import 'package:senior_needs/features/analysis/analysis_record.dart';
import 'package:senior_needs/features/classification/need_category.dart';

void main() {
  test('AnalysisRecord는 JSON 왕복 후에도 값이 보존된다', () {
    final record = AnalysisRecord(
      id: 'r1',
      createdAt: DateTime.parse('2026-07-12T10:00:00.000'),
      recipientName: '김영희',
      callTime: DateTime.parse('2026-07-12T09:55:00.000'),
      categories: const [NeedCategory.hospital, NeedCategory.general],
      reason: '허리 통증과 전등 교체 언급',
      summary: '허리 통증과 전등 교체를 이야기함',
      snippet: '허리가 아프고 전등도 나갔어',
    );

    final restored = AnalysisRecord.fromJson(record.toJson());

    expect(restored.id, 'r1');
    expect(restored.categories, [NeedCategory.hospital, NeedCategory.general]);
    expect(restored.reason, record.reason);
    expect(restored.summary, record.summary);
    expect(restored.snippet, record.snippet);
    expect(restored.createdAt, record.createdAt);
    expect(restored.recipientName, record.recipientName);
    expect(restored.callTime, record.callTime);
    expect(restored.hasActionableNeed, isTrue);
  });

  test('add는 최신순으로 쌓이고 클라우드에 저장된다', () async {
    final firestore = FakeFirebaseFirestore();
    final container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWithValue(firestore),
        currentUidProvider.overrideWithValue('test-uid'),
      ],
    );
    addTearDown(container.dispose);

    // 초기값 로딩
    await container.read(analysisHistoryProvider.future);

    final notifier = container.read(analysisHistoryProvider.notifier);
    await notifier.add(
      AnalysisRecord(
        id: '1',
        createdAt: DateTime.parse('2026-07-12T09:00:00.000'),
        categories: const [NeedCategory.hospital],
        reason: '첫 번째',
        snippet: 'a',
      ),
    );
    await notifier.add(
      AnalysisRecord(
        id: '2',
        createdAt: DateTime.parse('2026-07-12T10:00:00.000'),
        categories: const [NeedCategory.none],
        reason: '두 번째',
        snippet: 'b',
      ),
    );

    final records = container.read(analysisHistoryProvider).value!;
    expect(records.map((r) => r.id).toList(), ['2', '1']);

    // 같은 Firestore를 쓰는 새 컨테이너에서 다시 읽어도 유지돼야 한다.
    final reopened = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWithValue(firestore),
        currentUidProvider.overrideWithValue('test-uid'),
      ],
    );
    addTearDown(reopened.dispose);
    final persisted = await reopened.read(analysisHistoryProvider.future);
    expect(persisted.map((r) => r.id).toList(), ['2', '1']);
  });
}
