import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../care/care_providers.dart';
import 'parent_profile.dart';

/// 등록된 첫 돌봄 대상자에서 파생. 등록된 대상자가 없으면 null.
final parentProfileProvider = Provider<ParentProfile?>((ref) {
  final first = ref.watch(careRecipientsProvider).asData?.value.firstOrNull;
  if (first == null) return null;
  return ParentProfile(name: first.name, address: first.address);
});
