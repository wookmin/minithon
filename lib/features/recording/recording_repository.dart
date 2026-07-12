import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// MediaStore에서 조회한 녹음 메타데이터. 바이트는 [RecordingRepository.readBytes]로 별도 조회.
class RemoteRecording {
  const RemoteRecording({
    required this.name,
    required this.uri,
    this.relativePath = '',
    this.dateAdded,
  });

  final String name;
  final String uri;
  final String relativePath;
  final DateTime? dateAdded;
}

/// 안드로이드 네이티브(MediaStore)와 통신해 최근 통화 녹음을 가져오고,
/// 통화 종료 알림으로 앱이 열렸는지 여부를 확인한다. (Android 전용)
class RecordingRepository {
  RecordingRepository([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('senior_needs/recordings');

  final MethodChannel _channel;

  /// MediaStore에서 최근 오디오 목록을 최신순으로 가져온다.
  Future<List<RemoteRecording>> recent({int limit = 20}) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'recentRecordings',
      {'limit': limit},
    );
    if (result == null) return const [];

    return result.whereType<Map>().map((item) {
      final rawDate = item['dateAdded'];
      return RemoteRecording(
        name: item['name'] as String? ?? 'recording',
        uri: item['uri'] as String? ?? '',
        relativePath: item['relativePath'] as String? ?? '',
        dateAdded: rawDate is int
            ? DateTime.fromMillisecondsSinceEpoch(rawDate * 1000)
            : null,
      );
    }).where((recording) => recording.uri.isNotEmpty).toList();
  }

  /// content:// URI의 파일 바이트를 읽어온다. 실패 시 null.
  Future<Uint8List?> readBytes(String uri) {
    return _channel.invokeMethod<Uint8List>('readRecording', {'uri': uri});
  }

  /// 통화 종료 알림을 탭해 앱이 실행됐는지 확인하고 플래그를 소비한다.
  Future<bool> consumePendingAnalyze() async {
    final result = await _channel.invokeMethod<bool>('consumePendingAnalyze');
    return result ?? false;
  }

  /// 앱이 켜져 있는 동안 알림을 탭했을 때(네이티브 → Dart) 호출된다.
  void setAnalyzeListener(void Function() onAnalyze) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'analyzeLatest') onAnalyze();
    });
  }
}

final recordingRepositoryProvider = Provider<RecordingRepository>(
  (ref) => RecordingRepository(),
);
