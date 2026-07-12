import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechTranscriptionService {
  SpeechTranscriptionService({SpeechToText? speechToText})
    : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;
  bool _isReady = false;

  bool get isListening => _speechToText.isListening;

  Future<bool> initialize() async {
    if (_isReady) return true;
    _isReady = await _speechToText.initialize();
    return _isReady;
  }

  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
    void Function(String status)? onStatus,
  }) async {
    final ready = await initialize();
    if (!ready) {
      onStatus?.call('음성 인식을 사용할 수 없습니다');
      return;
    }

    await _speechToText.listen(
      listenOptions: SpeechListenOptions(
        localeId: 'ko_KR',
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
  }

  Future<void> stop() => _speechToText.stop();
}
