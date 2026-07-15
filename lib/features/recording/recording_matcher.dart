import '../care/care_models.dart';
import 'recording_candidate.dart';

/// 녹음이 방금 끝난 통화의 것인지 생성 시각으로 판별한다.
///
/// 통화 녹음은 통화 종료 시점 근처에 저장되므로, 녹음 생성 시각이
/// [통화 종료 − maxCallDuration] ~ [통화 종료 + buffer] 범위 안이면 후보로 본다.
/// 이름·전화번호만 맞는 과거 녹음을 현재 통화로 오분석하는 것을 막는다.
/// 두 시각 중 하나라도 알 수 없으면(0 이하) 필터하지 않는다(하위호환).
bool isRecordingForCall({
  required int recordingEpochMs,
  required int callEndedEpochMs,
  Duration maxCallDuration = const Duration(hours: 3),
  Duration buffer = const Duration(minutes: 5),
}) {
  if (callEndedEpochMs <= 0 || recordingEpochMs <= 0) return true;
  final diffMs = callEndedEpochMs - recordingEpochMs;
  return diffMs >= -buffer.inMilliseconds &&
      diffMs <= maxCallDuration.inMilliseconds;
}

class RecordingMatcher {
  const RecordingMatcher();

  RecordingCandidate match({
    required String filePath,
    required RecordingImportSourceType sourceType,
    required List<CareRecipient> recipients,
    DateTime? createdAt,
    String? contentUri,
    String? displayName,
  }) {
    final fileName = displayName ?? _fileName(filePath);
    final searchable = '$fileName $filePath';
    final phones = extractPhoneCandidates(searchable);

    for (final recipient in recipients) {
      final recipientPhone = normalizePhone(recipient.phoneNumber);
      if (recipientPhone.isEmpty) continue;
      if (phones.contains(recipientPhone)) {
        return RecordingCandidate(
          filePath: filePath,
          fileName: fileName,
          contentUri: contentUri,
          createdAt: createdAt,
          sourceType: sourceType,
          matchType: RecordingMatchType.phone,
          matchedRecipient: recipient,
          confidence: 1,
        );
      }
    }

    final normalizedNameSource = searchable.replaceAll(RegExp(r'\s+'), '');
    for (final recipient in recipients) {
      // 파일명 쪽 공백을 제거하므로 대상자 이름도 공백을 제거해 비교한다.
      // (삼성 통화녹음 "통화 녹음 멋사 조현욱_..." ↔ 대상자 "멋사 조현욱")
      final name = recipient.name.replaceAll(RegExp(r'\s+'), '');
      if (name.isEmpty) continue;
      if (normalizedNameSource.contains(name)) {
        return RecordingCandidate(
          filePath: filePath,
          fileName: fileName,
          contentUri: contentUri,
          createdAt: createdAt,
          sourceType: sourceType,
          matchType: RecordingMatchType.name,
          matchedRecipient: recipient,
          confidence: 0.72,
        );
      }
    }

    return RecordingCandidate(
      filePath: filePath,
      fileName: fileName,
      contentUri: contentUri,
      createdAt: createdAt,
      sourceType: sourceType,
      matchType: RecordingMatchType.none,
    );
  }

  String normalizePhone(String source) {
    var digits = source.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('82') && digits.length >= 11) {
      digits = '0${digits.substring(2)}';
    }
    return digits;
  }

  Set<String> extractPhoneCandidates(String source) {
    final compact = source.replaceAll(RegExp(r'[^0-9+]'), ' ');
    final matches = RegExp(
      r'(?:\+?82[-\s]?)?0?1[016789][-\s]?\d{3,4}[-\s]?\d{4}',
    ).allMatches(compact);
    return matches.map((match) => normalizePhone(match.group(0)!)).toSet();
  }

  String _fileName(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isEmpty ? path : parts.last;
  }
}
