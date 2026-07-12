import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 기기에서 찾은 최근 녹음 파일.
class LatestRecording {
  const LatestRecording({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;
}

/// 안드로이드 네이티브(MediaStore)와 통신해 최근 통화 녹음을 가져오고,
/// 통화 종료 알림으로 앱이 열렸는지 여부를 확인한다. (Android 전용)
class RecordingRepository {
  RecordingRepository([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('senior_needs/recordings');

  final MethodChannel _channel;

  /// MediaStore에서 가장 최근 오디오 파일을 읽어온다. 없으면 null.
  Future<LatestRecording?> latest() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'latestRecording',
    );
    if (result == null) return null;

    final bytes = result['bytes'];
    final name = result['name'];
    if (bytes is! Uint8List || name is! String) return null;

    return LatestRecording(
      name: name,
      bytes: bytes,
      mimeType: result['mimeType'] as String? ?? 'audio/mpeg',
    );
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
