import '../care/care_models.dart';
import 'recording_candidate.dart';

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
      final name = recipient.name.trim();
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
