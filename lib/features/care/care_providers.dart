import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../core/firebase/firebase_providers.dart';
import '../auth/auth_providers.dart';
import 'care_models.dart';
import 'region_matcher.dart';

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
    final source = prefs.getString(_myProfileKey);
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

final errandRequestsProvider =
    AsyncNotifierProvider<ErrandRequestsNotifier, List<ErrandRequest>>(
      ErrandRequestsNotifier.new,
    );

class ErrandRequestsNotifier extends AsyncNotifier<List<ErrandRequest>> {
  @override
  Future<List<ErrandRequest>> build() async {
    final snapshot = await ref
        .watch(firebaseFirestoreProvider)
        .collection(FirestorePaths.errands)
        .get();
    final requests = snapshot.docs
        .map((doc) => ErrandRequest.fromJson(doc.data()))
        .where((request) => request.title.isNotEmpty)
        .toList();
    requests.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return requests;
  }

  Future<void> add(ErrandRequest request) async {
    await ref
        .read(firebaseFirestoreProvider)
        .collection(FirestorePaths.errands)
        .doc(request.id)
        .set(request.toJson());
    ref.invalidateSelf();
    await future;
  }

  /// 부탁해요의 희망 날짜를 지정/변경한다. null이면 미정으로 되돌린다.
  Future<void> setPreferredDate(String errandId, DateTime? date) async {
    if (errandId.isEmpty) return;
    await ref
        .read(firebaseFirestoreProvider)
        .collection(FirestorePaths.errands)
        .doc(errandId)
        .update({'preferredDate': date?.toIso8601String()});
    ref.invalidateSelf();
    await future;
  }

  /// 도움 요청에 지원한다. 같은 uid의 중복 지원은 arrayUnion으로 자연히 무시된다.
  Future<void> apply(String errandId, String uid) async {
    if (errandId.isEmpty || uid.isEmpty) return;
    await ref
        .read(firebaseFirestoreProvider)
        .collection(FirestorePaths.errands)
        .doc(errandId)
        .update({
          'helpers': FieldValue.arrayUnion([uid]),
        });
    ref.invalidateSelf();
    await future;
  }
}

/// 내 거주지 지역에 올라온, 남이 올린 도움 요청. (지원/수락 대상)
/// 내 지역이 미등록이면 빈 목록 → 화면에서 등록을 안내한다.
final myRegionErrandsProvider = FutureProvider<List<ErrandRequest>>((ref) async {
  final all = await ref.watch(errandRequestsProvider.future);
  final me = await ref.watch(myProfileProvider.future);
  final uid = ref.watch(currentUidProvider);
  if (regionKey(me.address).isEmpty) return const [];
  return all
      .where((request) => request.requesterUid != uid)
      .where((request) => sameRegion(request.region, me.address))
      .toList();
});

/// 내가 올린 도움 요청. (부모 지역에 올린 것 — 상태·지원자 관리용)
final myPostedErrandsProvider = FutureProvider<List<ErrandRequest>>((ref) async {
  final all = await ref.watch(errandRequestsProvider.future);
  final uid = ref.watch(currentUidProvider);
  if (uid == null || uid.isEmpty) return const [];
  return all.where((request) => request.requesterUid == uid).toList();
});
