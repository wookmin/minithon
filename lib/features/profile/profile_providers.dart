import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../care/care_providers.dart';
import 'parent_profile.dart';

/// 하드코딩된 부모님 프로필. (확장 지점: 로컬 저장소 구현으로 교체)
final parentProfileProvider = Provider<ParentProfile>((ref) {
  final recipients = ref.watch(careRecipientsProvider).asData?.value;
  final first = recipients?.firstOrNull;
  if (first == null) {
    return const ParentProfile(
      name: '김순자',
      address: '전북특별자치도 남원시 향단로 10',
      age: 78,
    );
  }
  return ParentProfile(name: first.name, address: first.address, age: 78);
});
