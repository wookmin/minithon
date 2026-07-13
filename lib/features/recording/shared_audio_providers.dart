import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 외부 앱(음성 메모 등)에서 공유돼 들어온 오디오 파일 경로.
/// 공유 진입 → set(path) → 통화 분석 화면이 읽어 분석 후 set(null)로 비운다.
class SharedAudioNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? path) => state = path;
}

final sharedAudioPathProvider = NotifierProvider<SharedAudioNotifier, String?>(
  SharedAudioNotifier.new,
);
