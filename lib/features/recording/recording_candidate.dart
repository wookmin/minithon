import '../care/care_models.dart';

enum RecordingImportSourceType { manual, folderScan, background }

enum RecordingMatchType { phone, name, none }

class RecordingCandidate {
  const RecordingCandidate({
    required this.filePath,
    required this.fileName,
    required this.sourceType,
    required this.matchType,
    this.contentUri,
    this.createdAt,
    this.matchedRecipient,
    this.confidence = 0,
  });

  final String filePath;
  final String fileName;

  /// MediaStore content:// URI. 파일 경로 대신 이걸로 바이트를 읽는다(있으면).
  final String? contentUri;
  final DateTime? createdAt;
  final RecordingImportSourceType sourceType;
  final RecordingMatchType matchType;
  final CareRecipient? matchedRecipient;
  final double confidence;

  bool get isMatched =>
      matchedRecipient != null && matchType != RecordingMatchType.none;

  String get sourceLabel {
    switch (sourceType) {
      case RecordingImportSourceType.manual:
        return '직접 선택';
      case RecordingImportSourceType.folderScan:
        return '폴더 스캔';
      case RecordingImportSourceType.background:
        return '자동 감지';
    }
  }

  String get matchLabel {
    switch (matchType) {
      case RecordingMatchType.phone:
        return '전화번호 매칭';
      case RecordingMatchType.name:
        return '이름 매칭';
      case RecordingMatchType.none:
        return '매칭 안 됨';
    }
  }
}
