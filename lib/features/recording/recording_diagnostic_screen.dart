import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../care/care_providers.dart';
import 'recording_candidate.dart';
import 'recording_matcher.dart';
import 'recording_repository.dart';

/// 통화녹음 접근 진단 화면.
///
/// recent()(MediaStore)가 실제로 어떤 파일을 반환하는지, 권한 상태는 어떤지,
/// 각 파일이 등록된 대상자와 매칭되는지를 기기에서 눈으로 확인하기 위한 디버그 뷰.
class RecordingDiagnosticScreen extends ConsumerStatefulWidget {
  const RecordingDiagnosticScreen({super.key});

  @override
  ConsumerState<RecordingDiagnosticScreen> createState() =>
      _RecordingDiagnosticScreenState();
}

class _RecordingDiagnosticScreenState
    extends ConsumerState<RecordingDiagnosticScreen> {
  final Map<String, String> _permissions = {};
  List<RemoteRecording> _recordings = const [];
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final permissions = <String, String>{};
    for (final entry in const {
      'audio': Permission.audio,
      'phone': Permission.phone,
      'notification': Permission.notification,
      'storage': Permission.storage,
      'battery(무시)': Permission.ignoreBatteryOptimizations,
    }.entries) {
      permissions[entry.key] = (await entry.value.status).name;
    }

    List<RemoteRecording> recordings = const [];
    String? error;
    try {
      recordings = await ref
          .read(recordingRepositoryProvider)
          .recent(limit: 50);
    } on Object catch (e) {
      error = '$e';
    }

    if (!mounted) return;
    setState(() {
      _permissions
        ..clear()
        ..addAll(permissions);
      _recordings = recordings;
      _error = error;
      _loading = false;
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.audio,
      Permission.phone,
      Permission.notification,
      Permission.storage,
    ].request();
    await Permission.ignoreBatteryOptimizations.request();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final recipients =
        ref.watch(careRecipientsProvider).asData?.value ?? const [];
    const matcher = RecordingMatcher();

    return Scaffold(
      appBar: AppBar(
        title: const Text('녹음 접근 진단'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!Platform.isAndroid)
            const _Card(
              title: '안내',
              child: Text('recent()는 Android 전용입니다. 이 진단은 실기기(Android)에서 확인하세요.'),
            ),
          _Card(
            title: '권한 상태',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in _permissions.entries)
                  Text('${entry.key}: ${entry.value}'),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _requestPermissions,
                  child: const Text('권한 요청'),
                ),
              ],
            ),
          ),
          _Card(
            title: '등록된 대상자 (${recipients.length})',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recipients.isEmpty)
                  const Text('없음 — 먼저 대상자를 등록하세요.')
                else
                  for (final r in recipients)
                    Text('· ${r.name}  ${r.phoneNumber}'),
              ],
            ),
          ),
          _Card(
            title: 'recent() 결과 (${_recordings.length})',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loading) const Text('불러오는 중…'),
                if (_error != null)
                  Text('에러: $_error',
                      style: const TextStyle(color: Colors.red)),
                if (!_loading && _error == null && _recordings.isEmpty)
                  const Text(
                    '앱이 볼 수 있는 오디오가 없습니다.\n'
                    '(삼성 통화녹음이 여기에 안 나오면 = MediaStore 미노출 = 접근 제한 확정)',
                  ),
                for (final rec in _recordings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecordingRow(
                      recording: rec,
                      matchLabel: _matchLabel(matcher, rec, recipients),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _matchLabel(
    RecordingMatcher matcher,
    RemoteRecording rec,
    List recipients,
  ) {
    if (recipients.isEmpty) return '대상자 없음';
    final candidate = matcher.match(
      filePath: '${rec.relativePath}${rec.name}',
      displayName: rec.name,
      contentUri: rec.uri,
      sourceType: RecordingImportSourceType.folderScan,
      recipients: List.from(recipients),
      createdAt: rec.dateAdded,
    );
    if (!candidate.isMatched) return '매칭 안 됨';
    return '매칭: ${candidate.matchedRecipient?.name} (${candidate.matchType.name})';
  }
}

class _RecordingRow extends StatelessWidget {
  const _RecordingRow({required this.recording, required this.matchLabel});

  final RemoteRecording recording;
  final String matchLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(recording.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('path: ${recording.relativePath}',
            style: const TextStyle(fontSize: 12)),
        Text('date: ${recording.dateAdded}  |  $matchLabel',
            style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
