import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../care/care_models.dart';
import 'recording_candidate.dart';
import 'recording_matcher.dart';
import 'recording_repository.dart';

class RecordingImportService {
  const RecordingImportService({
    required this.repository,
    this.matcher = const RecordingMatcher(),
  });

  static const _allowedExtensions = {
    'm4a',
    'mp3',
    'wav',
    'aac',
    'amr',
    '3gp',
    'flac',
    'ogg',
    'caf',
  };

  final RecordingRepository repository;
  final RecordingMatcher matcher;

  /// 사용자가 파일을 직접 고른다. (iOS·Android 공통)
  Future<RecordingCandidate?> pickManual({
    required List<CareRecipient> recipients,
  }) async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions.toList(),
      withData: false,
    );
    if (selection == null) return null;

    final file = selection.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) return null;

    return matcher.match(
      filePath: path,
      sourceType: RecordingImportSourceType.manual,
      recipients: recipients,
      createdAt: await _modifiedAt(path),
    );
  }

  /// MediaStore 최근 오디오를 읽어 돌봄자와 매칭해 후보 목록을 만든다. (Android)
  Future<List<RecordingCandidate>> scanRecordings({
    required List<CareRecipient> recipients,
    int limit = 20,
  }) async {
    if (!Platform.isAndroid) return const [];
    final hasPermission = await _requestAudioAccess();
    if (!hasPermission) return const [];

    final recordings = await repository.recent(limit: limit);
    return [
      for (final recording in recordings)
        matcher.match(
          filePath: _joinPath(recording.relativePath, recording.name),
          displayName: recording.name,
          contentUri: recording.uri,
          sourceType: RecordingImportSourceType.folderScan,
          recipients: recipients,
          createdAt: recording.dateAdded,
        ),
    ];
  }

  String _joinPath(String dir, String name) {
    if (dir.isEmpty) return name;
    return dir.endsWith('/') ? '$dir$name' : '$dir/$name';
  }

  Future<bool> _requestAudioAccess() async {
    final audio = await Permission.audio.request();
    if (audio.isGranted) return true;
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<DateTime?> _modifiedAt(String path) async {
    try {
      return File(path).lastModified();
    } on Object {
      return null;
    }
  }
}

final recordingImportServiceProvider = Provider<RecordingImportService>(
  (ref) => RecordingImportService(
    repository: ref.read(recordingRepositoryProvider),
  ),
);
