import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'care_models.dart';

const _recipientsKey = 'careRecipients';
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
    final prefs = ref.watch(sharedPreferencesProvider);
    final source = prefs.getString(_recipientsKey);
    if (source == null || source.isEmpty) return defaultCareRecipients;
    try {
      final recipients = decodeRecipients(source);
      return recipients.isEmpty ? defaultCareRecipients : recipients;
    } on Object {
      return defaultCareRecipients;
    }
  }

  Future<void> save(CareRecipient recipient) async {
    final current = <CareRecipient>[
      ...(state.asData?.value ?? defaultCareRecipients),
    ];
    final index = current.indexWhere((item) => item.id == recipient.id);
    if (index >= 0) {
      current[index] = recipient;
    } else {
      current.add(recipient);
    }
    await _persist(current);
  }

  Future<void> _persist(List<CareRecipient> recipients) async {
    state = AsyncData(recipients);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_recipientsKey, encodeRecipients(recipients));
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
    if (source == null || source.isEmpty) return defaultMyProfile;
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return MyProfile.fromJson(decoded);
      }
    } on Object {
      // Fall through to the default profile.
    }
    return defaultMyProfile;
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

final careSchedulesProvider = Provider<List<CareSchedule>>(
  (ref) => demoSchedules,
);

final errandRequestsProvider = Provider<List<ErrandRequest>>(
  (ref) => demoErrands,
);

final careExpertsProvider = Provider<List<CareExpert>>((ref) => demoExperts);
