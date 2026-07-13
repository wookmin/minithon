import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

import '../../core/functions/functions_client.dart';

/// 오디오 전사 결과. 성공 시 [text], 실패 시 [error]만 채워진다.
class AudioTranscriptionResult {
  const AudioTranscriptionResult._({this.text, this.error});

  const AudioTranscriptionResult.success(String text) : this._(text: text);
  const AudioTranscriptionResult.failure(String error) : this._(error: error);

  final String? text;
  final String? error;

  bool get isSuccess => text != null && text!.trim().isNotEmpty;
}

/// 녹음 파일(오디오)을 서버(transcribeAudio 함수)로 보내 한국어 통화 내용을 전사한다.
/// Gemini API 키는 서버 시크릿으로만 존재하며 앱 번들에 포함되지 않는다.
class AudioTranscriptionService {
  AudioTranscriptionService({required this.invoke});

  /// 인라인 요청 상한(약 18MB). 초과 시 명확한 안내를 위해 미리 막는다.
  static const _maxBytes = 18 * 1024 * 1024;

  final CallableInvoker invoke;

  Future<AudioTranscriptionResult> transcribe({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (bytes.isEmpty) {
      return const AudioTranscriptionResult.failure('빈 파일입니다');
    }
    if (bytes.length > _maxBytes) {
      return const AudioTranscriptionResult.failure('파일이 너무 큽니다 (18MB 이하만 지원)');
    }

    try {
      final data = await invoke('transcribeAudio', {
        'audioBase64': base64Encode(bytes),
        'mimeType': mimeType,
      });
      final transcript = (data['transcript'] as String?)?.trim() ?? '';
      if (transcript.isEmpty) {
        return const AudioTranscriptionResult.failure('전사 결과가 비어 있습니다');
      }
      return AudioTranscriptionResult.success(transcript);
    } on FirebaseFunctionsException catch (error) {
      return AudioTranscriptionResult.failure(
        '전사 실패: ${error.message ?? error.code}',
      );
    } on Object catch (error) {
      return AudioTranscriptionResult.failure('전사 실패: $error');
    }
  }
}
