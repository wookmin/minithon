import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:senior_needs/features/classification/gemini/gemini_api_config.dart';
import 'package:senior_needs/features/recording/audio_transcription_service.dart';

void main() {
  const config = GeminiApiConfig(
    apiKey: 'test-key',
    model: 'test-model',
    timeout: Duration(seconds: 30),
  );

  final sampleBytes = Uint8List.fromList([1, 2, 3, 4]);

  test('오디오를 인라인으로 보내 전사 텍스트를 돌려준다', () async {
    late Map<String, dynamic> sentBody;
    final service = AudioTranscriptionService(
      config: config,
      client: MockClient((request) async {
        expect(request.url.path, '/v1beta/models/test-model:generateContent');
        expect(request.headers['x-goog-api-key'], 'test-key');
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '허리가 아프다고 하셨어요'},
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await service.transcribe(
      bytes: sampleBytes,
      mimeType: 'audio/mp4',
    );

    expect(result.isSuccess, isTrue);
    expect(result.text, '허리가 아프다고 하셨어요');

    final parts = (sentBody['contents'] as List).first['parts'] as List;
    final inlineData = parts.last['inlineData'] as Map<String, dynamic>;
    expect(inlineData['mimeType'], 'audio/mp4');
    expect(inlineData['data'], base64Encode(sampleBytes));
  });

  test('API 키가 없으면 호출 없이 실패를 반환한다', () async {
    final service = AudioTranscriptionService(
      config: const GeminiApiConfig(
        apiKey: '',
        model: 'test-model',
        timeout: Duration(seconds: 30),
      ),
      client: MockClient((request) async {
        fail('API key가 없으면 HTTP 호출을 하지 않아야 한다.');
      }),
    );

    final result = await service.transcribe(
      bytes: sampleBytes,
      mimeType: 'audio/mp4',
    );

    expect(result.isSuccess, isFalse);
    expect(result.error, contains('API 키'));
  });

  test('빈 파일은 호출 없이 실패를 반환한다', () async {
    final service = AudioTranscriptionService(
      config: config,
      client: MockClient((request) async {
        fail('빈 파일이면 HTTP 호출을 하지 않아야 한다.');
      }),
    );

    final result = await service.transcribe(
      bytes: Uint8List(0),
      mimeType: 'audio/mp4',
    );

    expect(result.isSuccess, isFalse);
  });

  test('오류 응답은 상태 코드와 메시지를 담아 실패로 반환한다', () async {
    final service = AudioTranscriptionService(
      config: config,
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'Unsupported audio format.'},
          }),
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await service.transcribe(
      bytes: sampleBytes,
      mimeType: 'audio/mp4',
    );

    expect(result.isSuccess, isFalse);
    expect(result.error, contains('400'));
    expect(result.error, contains('Unsupported audio format.'));
  });
}
