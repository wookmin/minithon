import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../classification/gemini/gemini_api_config.dart';

/// 오디오 전사 결과. 성공 시 [text], 실패 시 [error]만 채워진다.
class AudioTranscriptionResult {
  const AudioTranscriptionResult._({this.text, this.error});

  const AudioTranscriptionResult.success(String text) : this._(text: text);
  const AudioTranscriptionResult.failure(String error) : this._(error: error);

  final String? text;
  final String? error;

  bool get isSuccess => text != null && text!.trim().isNotEmpty;
}

/// 녹음 파일(오디오)을 Gemini에 인라인으로 보내 한국어 통화 내용을 전사한다.
/// iOS처럼 통화 자동녹음이 없는 환경에서 사용자가 올린 파일을 텍스트로 바꾼다.
class AudioTranscriptionService {
  AudioTranscriptionService({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  static const _prompt =
      '이 오디오는 한국어 통화 녹음이다. 들리는 대화 내용을 그대로 한국어로 받아써라. '
      '화자 표시, 설명, 요약 없이 발화 내용만 출력한다.';

  /// 인라인 요청 상한(약 20MB). 초과 시 명확한 안내를 위해 미리 막는다.
  static const _maxBytes = 18 * 1024 * 1024;

  final GeminiApiConfig config;
  final http.Client _client;

  Future<AudioTranscriptionResult> transcribe({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (!config.hasApiKey) {
      return const AudioTranscriptionResult.failure('Gemini API 키가 설정되지 않음');
    }
    if (bytes.isEmpty) {
      return const AudioTranscriptionResult.failure('빈 파일입니다');
    }
    if (bytes.length > _maxBytes) {
      return const AudioTranscriptionResult.failure('파일이 너무 큽니다 (18MB 이하만 지원)');
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/${config.model}:generateContent',
    );

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': config.apiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': _prompt},
                    {
                      'inlineData': {
                        'mimeType': mimeType,
                        'data': base64Encode(bytes),
                      },
                    },
                  ],
                },
              ],
              'generationConfig': {'temperature': 0, 'maxOutputTokens': 2048},
            }),
          )
          .timeout(config.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = utf8.decode(response.bodyBytes);
        return AudioTranscriptionResult.failure(
          '전사 실패 (${response.statusCode}) ${_errorMessage(body)}'.trim(),
        );
      }

      final transcript = _extractText(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
      if (transcript == null || transcript.trim().isEmpty) {
        return const AudioTranscriptionResult.failure('전사 결과가 비어 있습니다');
      }
      return AudioTranscriptionResult.success(transcript.trim());
    } on TimeoutException {
      return AudioTranscriptionResult.failure(
        '전사 시간 초과 (${config.requestTimeout.inSeconds}초)',
      );
    } on Object catch (error) {
      return AudioTranscriptionResult.failure('전사 실패: $error');
    }
  }

  String? _extractText(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final content = (candidates.first as Map<String, dynamic>)['content'];
    if (content is! Map<String, dynamic>) return null;
    final parts = content['parts'];
    if (parts is! List) return null;
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map<String, dynamic> && part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }
    return buffer.toString();
  }

  String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return error['message'] as String;
        }
      }
    } on Object {
      // Ignore malformed error bodies.
    }
    return '';
  }
}
