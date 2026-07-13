import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

/// 로그인 상태 스트림. 게이트·화면이 이걸 watch해서 분기한다.
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// 관리자 이메일 화이트리스트. 이 계정으로 로그인하면 [isAdminProvider]가 true.
const adminEmails = <String>['admin@ddonggangaji.com'];

/// 현재 사용자가 관리자인지. (향후 관리자 전용 화면/권한 분기에 사용)
final isAdminProvider = Provider<bool>((ref) {
  final email = ref.watch(authStateProvider).asData?.value?.email?.toLowerCase();
  return email != null && adminEmails.contains(email);
});
