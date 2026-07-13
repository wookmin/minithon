import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_providers.dart';
import 'analysis_record.dart';

const _maxRecords = 50;

/// 통화 분석 기록. 로그인 사용자별로 Firestore(users/{uid}/analyses)에 저장·동기화된다.
final analysisHistoryProvider =
    AsyncNotifierProvider<AnalysisHistoryNotifier, List<AnalysisRecord>>(
      AnalysisHistoryNotifier.new,
    );

class AnalysisHistoryNotifier extends AsyncNotifier<List<AnalysisRecord>> {
  @override
  Future<List<AnalysisRecord>> build() async {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) return const [];
    final snapshot = await ref
        .watch(firebaseFirestoreProvider)
        .collection('users')
        .doc(uid)
        .collection('analyses')
        .orderBy('createdAt', descending: true)
        .limit(_maxRecords)
        .get();
    return snapshot.docs
        .map((doc) => AnalysisRecord.fromJson(doc.data()))
        .toList();
  }

  Future<void> add(AnalysisRecord record) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref
        .read(firebaseFirestoreProvider)
        .collection('users')
        .doc(uid)
        .collection('analyses')
        .doc(record.id)
        .set(record.toJson());
    ref.invalidateSelf();
    await future;
  }
}
