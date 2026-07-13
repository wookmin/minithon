import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_providers.dart';
import 'firestore_paths.dart';

/// Firestore 인스턴스. 테스트에서는 FakeFirebaseFirestore로 override한다.
final firebaseFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// 현재 로그인 사용자 uid. 미로그인 시 null.
/// 스트림이 아직 emit 전이어도 저장소의 currentUser로 즉시 확인해 로그인 직후 공백을 막는다.
final currentUidProvider = Provider<String?>((ref) {
  final streamed = ref.watch(authStateProvider).asData?.value?.uid;
  if (streamed != null) return streamed;
  return ref.watch(authRepositoryProvider).currentUser?.uid;
});

/// users/{uid} 문서 참조. uid 없으면 null.
DocumentReference<Map<String, dynamic>>? userDoc(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(FirestorePaths.users)
      .doc(uid);
}
