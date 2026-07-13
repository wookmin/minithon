import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../core/firebase/firebase_providers.dart';
import '../auth/auth_providers.dart';
import 'care_models.dart';

const _recordingSetupKey = 'recordingSetupState';
const _myProfileKey = 'myProfile';

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
    final source = prefs.getString(_myProfileKey);
    if (source != null && source.isNotEmpty) {
      try {
        final decoded = jsonDecode(source);
        if (decoded is Map<String, dynamic>) {
          return MyProfile.fromJson(decoded);
        }
      } on Object {
        // 저장 형식이 깨졌으면 아래 로그인 사용자 정보로 폴백.
      }
    }
    // 저장된 프로필이 없으면 로그인한 사용자 정보에서 이름을 가져온다.
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
    await prefs.setString(_myProfileKey, jsonEncode(profile.toJson()));
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
    final source = prefs.getString(_recordingSetupKey);
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
    await prefs.setString(_recordingSetupKey, jsonEncode(next.toJson()));
  }
}

final careSchedulesProvider = Provider<List<CareSchedule>>((ref) => const []);

final errandRequestsProvider = FutureProvider<List<ErrandRequest>>((ref) async {
  final snapshot = await ref
      .watch(firebaseFirestoreProvider)
      .collection(FirestorePaths.errands)
      .get();
  return snapshot.docs
      .map((doc) => ErrandRequest.fromJson(doc.data()))
      .where((request) => request.title.isNotEmpty)
      .toList();
});

final careExpertsProvider = FutureProvider<List<CareExpert>>((ref) async {
  final snapshot = await ref
      .watch(firebaseFirestoreProvider)
      .collection(FirestorePaths.experts)
      .get();
  return snapshot.docs
      .map((doc) => CareExpert.fromJson(doc.data()))
      .where((expert) => expert.name.isNotEmpty)
      .toList();
});
