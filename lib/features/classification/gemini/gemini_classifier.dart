import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../need_category.dart';
import '../need_classification_result.dart';
import '../need_classifier.dart';
import 'gemini_api_config.dart';
import 'gemini_classification_prompt.dart';
import 'gemini_classification_schema.dart';

class GeminiClassifier implements NeedClassifier {
  GeminiClassifier({
    required this.config,
    http.Client? client,
    this.retryDelay = const Duration(milliseconds: 350),
  }) : _client = client ?? http.Client();

  static const _confidenceThreshold = 0.6;
  static const _maxAttempts = 3;

  final GeminiApiConfig config;
  final http.Client _client;
  final Duration retryDelay;

  @override
  Future<NeedClassificationResult> classify(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return NeedClassificationResult.none(reason: '빈 텍스트');
    }
    if (!config.hasApiKey) {
      return NeedClassificationResult.none(reason: 'Gemini API 키가 설정되지 않음');
    }

    try {
      for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
        final response = await _sendRequest(normalized);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _parseResponseBody(utf8.decode(response.bodyBytes));
        }

        final body = utf8.decode(response.bodyBytes);
        final retryable = _isRetryableStatus(response.statusCode);
        if (retryable && attempt < _maxAttempts) {
          await Future<void>.delayed(retryDelay * attempt);
          continue;
        }

        return NeedClassificationResult.none(
          reason: _failureReason(response.statusCode, body),
        );
      }

      return NeedClassificationResult.none(reason: 'Gemini 서버가 바쁩니다');
    } on TimeoutException {
      return NeedClassificationResult.none(
        reason: 'Gemini 응답 시간 초과 (${config.requestTimeout.inSeconds}초)',
      );
    } on Object catch (error) {
      return NeedClassificationResult.none(reason: 'Gemini 분류 실패: $error');
    }
  }

  Future<http.Response> _sendRequest(String normalized) {
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/${config.model}:generateContent',
    );
    return _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': config.apiKey,
          },
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': geminiNeedClassificationPrompt},
              ],
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': '통화 텍스트:\n$normalized'},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0,
              'maxOutputTokens': 256,
              'responseMimeType': 'application/json',
              'responseSchema': geminiNeedClassificationSchema,
            },
          }),
        )
        .timeout(config.requestTimeout);
  }

  NeedClassificationResult _parseResponseBody(String body) {
    final decoded = jsonDecode(body);
    final outputText = _extractOutputText(decoded);
    if (outputText == null || outputText.trim().isEmpty) {
      return NeedClassificationResult.none(reason: 'Gemini 응답 비어 있음');
    }

    final payload = jsonDecode(outputText);
    if (payload is! Map<String, dynamic>) {
      return NeedClassificationResult.none(reason: 'Gemini JSON 형식 오류');
    }

    final confidenceValue = payload['confidence'];
    final confidence = confidenceValue is num
        ? confidenceValue.toDouble()
        : 0.0;
    if (confidence < _confidenceThreshold) {
      return NeedClassificationResult.none(reason: '분류 신뢰도 낮음');
    }

    final rawCategories = payload['categories'];
    if (rawCategories is! List) {
      return NeedClassificationResult.none(reason: '카테고리 형식 오류');
    }

    final categories = rawCategories
        .whereType<String>()
        .map(NeedCategoryText.fromApiValue)
        .nonNulls
        .toSet()
        .toList();
    final normalizedCategories = _normalizeCategories(categories);
    final reason = payload['reason'] is String
        ? (payload['reason'] as String).trim()
        : 'Gemini 구조화 분류';

    if (normalizedCategories.length == 1 &&
        normalizedCategories.first == NeedCategory.none) {
      return NeedClassificationResult.none(
        reason: reason.isEmpty ? '분류 가능한 니즈 없음' : reason,
      );
    }

    return NeedClassificationResult(
      categories: normalizedCategories,
      confidence: confidence,
      reason: reason.isEmpty ? 'Gemini 구조화 분류' : reason,
    );
  }

  String? _extractOutputText(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;

    final outputText = decoded['output_text'] ?? decoded['outputText'];
    if (outputText is String) return outputText;

    final candidates = decoded['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map<String, dynamic>) {
        final content = first['content'];
        if (content is Map<String, dynamic>) {
          final parts = content['parts'];
          if (parts is List && parts.isNotEmpty) {
            final firstPart = parts.first;
            if (firstPart is Map<String, dynamic> &&
                firstPart['text'] is String) {
              return firstPart['text'] as String;
            }
          }
        }
      }
    }

    return null;
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

  bool _isRetryableStatus(int statusCode) {
    return statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  String _failureReason(int statusCode, String body) {
    final message = _errorMessage(body);
    if (_isRetryableStatus(statusCode)) {
      return 'Gemini 서버가 바쁩니다 ($statusCode) $message';
    }
    return 'Gemini 호출 실패 ($statusCode) $message';
  }

  List<NeedCategory> _normalizeCategories(List<NeedCategory> categories) {
    final actionable = categories
        .where((category) => category != NeedCategory.none)
        .toSet()
        .toList();
    if (actionable.isEmpty) return const [NeedCategory.none];

    actionable.sort((a, b) => _priority(a).compareTo(_priority(b)));
    return actionable;
  }

  int _priority(NeedCategory category) {
    switch (category) {
      case NeedCategory.professional:
        return 0;
      case NeedCategory.hospital:
        return 1;
      case NeedCategory.general:
        return 2;
      case NeedCategory.none:
        return 3;
    }
  }
}
