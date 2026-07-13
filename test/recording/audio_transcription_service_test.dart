import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/features/recording/audio_transcription_service.dart';

void main() {
  final sampleBytes = Uint8List.fromList([1, 2, 3, 4]);

  test('오디오를 base64로 보내 전사 텍스트를 돌려준다', () async {
    late String sentName;
    late Map<String, dynamic> sentPayload;
    final service = AudioTranscriptionService(
      invoke: (name, payload) async {
        sentName = name;
        sentPayload = payload;
        return {'transcript': '허리가 아프다고 하셨어요'};
      },
    );

    final result = await service.transcribe(
      bytes: sampleBytes,
      mimeType: 'audio/mp4',
    );

    expect(result.isSuccess, isTrue);
    expect(result.text, '허리가 아프다고 하셨어요');
    expect(sentName, 'transcribeAudio');
    expect(sentPayload['mimeType'], 'audio/mp4');
    expect(sentPayload['audioBase64'], base64Encode(sampleBytes));
  });

  test('빈 파일은 서버 호출 없이 실패를 반환한다', () async {
    var called = false;
    final service = AudioTranscriptionService(
      invoke: (name, payload) async {
        called = true;
        return {};
      },
    );

    final result = await service.transcribe(
      bytes: Uint8List(0),
      mimeType: 'audio/mp4',
    );

    expect(called, isFalse);
    expect(result.isSuccess, isFalse);
  });

  test('전사 결과가 비어 있으면 실패를 반환한다', () async {
    final service = AudioTranscriptionService(
      invoke: (name, payload) async => {'transcript': '   '},
    );

    final result = await service.transcribe(
      bytes: sampleBytes,
      mimeType: 'audio/mp4',
    );

    expect(result.isSuccess, isFalse);
  });

  test('서버 오류는 실패 메시지로 반환한다', () async {
    final service = AudioTranscriptionService(
      invoke: (name, payload) async =>
          throw Exception('Unsupported audio format.'),
    );

    final result = await service.transcribe(
      bytes: sampleBytes,
      mimeType: 'audio/mp4',
    );

    expect(result.isSuccess, isFalse);
    expect(result.error, contains('전사 실패'));
  });
}
