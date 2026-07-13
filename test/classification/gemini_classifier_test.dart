import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:senior_needs/features/classification/gemini/gemini_api_config.dart';
import 'package:senior_needs/features/classification/gemini/gemini_classifier.dart';
import 'package:senior_needs/features/classification/need_category.dart';

void main() {
  GeminiClassifier classifierFor(http.Client client) {
    return GeminiClassifier(
      config: const GeminiApiConfig(
        apiKey: 'test-key',
        model: 'test-model',
        timeout: Duration(seconds: 30),
      ),
      client: client,
      retryDelay: Duration.zero,
    );
  }

  test('Gemini JSON 응답을 복수 카테고리로 파싱한다', () async {
    final classifier = classifierFor(
      MockClient((request) async {
        expect(request.url.path, '/v1beta/models/test-model:generateContent');
        expect(request.headers['x-goog-api-key'], 'test-key');
        final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        expect(requestBody['generationConfig'], isA<Map<String, dynamic>>());
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'categories': ['hospital', 'general'],
                        'confidence': 0.91,
                        'reason': '허리 통증과 전등 수리를 함께 언급',
                      }),
                    },
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

    final result = await classifier.classify('허리도 아프고 전등도 나갔어');

    expect(result.categories, [NeedCategory.hospital, NeedCategory.general]);
    expect(result.hasActionableNeed, isTrue);
  });

  test('none이 다른 카테고리와 섞이면 actionable 카테고리만 남긴다', () async {
    final classifier = classifierFor(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'categories': ['none', 'general'],
                        'confidence': 0.85,
                        'reason': '전등 교체 요청',
                      }),
                    },
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

    final result = await classifier.classify('전등을 고쳐야 한다');

    expect(result.categories, [NeedCategory.general]);
  });

  test('파싱 실패는 none으로 폴백한다', () async {
    final classifier = classifierFor(
      MockClient((request) async {
        return http.Response('not-json', 200);
      }),
    );

    final result = await classifier.classify('허리가 아프다');

    expect(result.categories, [NeedCategory.none]);
    expect(result.hasActionableNeed, isFalse);
  });

  test('503은 짧게 재시도하고 성공 응답을 사용한다', () async {
    var calls = 0;
    final classifier = classifierFor(
      MockClient((request) async {
        calls++;
        if (calls == 1) {
          return http.Response(
            jsonEncode({
              'error': {'message': 'The model is overloaded.'},
            }),
            503,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'categories': ['hospital'],
                        'confidence': 0.9,
                        'reason': '허리 통증 언급',
                      }),
                    },
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

    final result = await classifier.classify('허리가 아프다');

    expect(calls, 2);
    expect(result.categories, [NeedCategory.hospital]);
  });

  test('API 키가 없으면 호출 없이 none으로 폴백한다', () async {
    final classifier = GeminiClassifier(
      config: const GeminiApiConfig(
        apiKey: '',
        model: 'test-model',
        timeout: Duration(seconds: 30),
      ),
      client: MockClient((request) async {
        fail('API key가 없으면 HTTP 호출을 하지 않아야 한다.');
      }),
    );

    final result = await classifier.classify('허리가 아프다');

    expect(result.categories, [NeedCategory.none]);
  });
}
