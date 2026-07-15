import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../core/firebase/firebase_providers.dart';
import '../auth/auth_providers.dart';
import 'care_models.dart';

// 로컬 캐시 키는 UID별로 분리해, 같은 기기에서 계정을 바꿔도
// 이전 사용자의 프로필·설정이 노출되지 않게 한다.
String _myProfileKey(String? uid) => 'myProfile_${uid ?? 'anon'}';
String _recordingSetupKey(String? uid) => 'recordingSetupState_${uid ?? 'anon'}';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences override is required'),
);

final careRecipientsProvider =
    AsyncNotifierProvider<CareRecipientsNotifier, List<CareRecipient>>(
      CareRecipientsNotifier.new,
    );

class CareRecipientsNotifier extends AsyncNotifier<List<CareRecipient>> {
  @override
  Future<List<CareRecipient>> build() async {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) return const [];
    final snapshot = await ref
        .watch(firebaseFirestoreProvider)
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.recipients)
        .get();
    return snapshot.docs
        .map((doc) => CareRecipient.fromJson(doc.data()))
        // 필수 정보(식별자·이름)가 비어 있는 손상 문서는 목록에서 제외한다.
        .where(
          (recipient) => recipient.id.isNotEmpty && recipient.name.isNotEmpty,
        )
        .toList();
  }

  Future<void> save(CareRecipient recipient) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref
        .read(firebaseFirestoreProvider)
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.recipients)
        .doc(recipient.id)
        .set(recipient.toJson());
    ref.invalidateSelf();
    await future;
  }
}

final myProfileProvider = AsyncNotifierProvider<MyProfileNotifier, MyProfile>(
  MyProfileNotifier.new,
);

class MyProfileNotifier extends AsyncNotifier<MyProfile> {
  @override
  Future<MyProfile> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid = ref.watch(currentUidProvider);
    final source = prefs.getString(_myProfileKey(uid));
    final authProfile = _profileFromAuth();
    if (source != null && source.isNotEmpty) {
      try {
        final decoded = jsonDecode(source);
        if (decoded is Map<String, dynamic>) {
          final saved = MyProfile.fromJson(decoded);
          final savedName = saved.name.trim();
          return MyProfile(
            name: savedName.isNotEmpty ? savedName : authProfile.name,
            phoneNumber: saved.phoneNumber,
            address: saved.address,
          );
        }
      } on Object {
        // 저장 형식이 깨졌으면 아래 로그인 사용자 정보로 폴백.
      }
    }
    return authProfile;
  }

  MyProfile _profileFromAuth() {
    final user = ref.watch(authStateProvider).asData?.value;
    final displayName = user?.displayName?.trim();
    final name = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (user?.email?.split('@').first ?? '사용자');
    return MyProfile(name: name, phoneNumber: '');
  }

  Future<void> save(MyProfile profile) async {
    state = AsyncData(profile);
    final prefs = ref.read(sharedPreferencesProvider);
    final uid = ref.read(currentUidProvider);
    await prefs.setString(_myProfileKey(uid), jsonEncode(profile.toJson()));
  }
}

final recordingSetupProvider =
    AsyncNotifierProvider<RecordingSetupNotifier, RecordingSetupState>(
      RecordingSetupNotifier.new,
    );

class RecordingSetupNotifier extends AsyncNotifier<RecordingSetupState> {
  @override
  Future<RecordingSetupState> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid = ref.watch(currentUidProvider);
    final source = prefs.getString(_recordingSetupKey(uid));
    if (source == null || source.isEmpty) {
      return const RecordingSetupState.incomplete();
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return RecordingSetupState.fromJson(decoded);
      }
    } on Object {
      // Fall through to the safe incomplete state.
    }
    return const RecordingSetupState.incomplete();
  }

  Future<void> complete() async {
    final next = RecordingSetupState(
      isCompleted: true,
      backgroundDetectionEnabled: true,
      completedAt: DateTime.now(),
    );
    await _persist(next);
  }

  Future<void> setBackgroundDetectionEnabled(bool enabled) async {
    final current =
        state.asData?.value ?? const RecordingSetupState.incomplete();
    final next = current.copyWith(backgroundDetectionEnabled: enabled);
    await _persist(next);
  }

  Future<void> _persist(RecordingSetupState next) async {
    state = AsyncData(next);
    final prefs = ref.read(sharedPreferencesProvider);
    final uid = ref.read(currentUidProvider);
    await prefs.setString(_recordingSetupKey(uid), jsonEncode(next.toJson()));
  }
}
