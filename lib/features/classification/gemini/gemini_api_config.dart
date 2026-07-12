import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiApiConfig {
  const GeminiApiConfig({
    required this.apiKey,
    required this.model,
    this.timeout,
  });

  static const defaultTimeout = Duration(seconds: 30);

  factory GeminiApiConfig.fromEnv() {
    final timeoutSeconds = int.tryParse(
      dotenv.env['GEMINI_TIMEOUT_SECONDS']?.trim() ?? '',
    );

    return GeminiApiConfig(
      apiKey: dotenv.env['GEMINI_API_KEY']?.trim() ?? '',
      model: dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
          ? dotenv.env['GEMINI_MODEL']!.trim()
          : 'gemini-2.5-flash-lite',
      timeout: timeoutSeconds == null
          ? defaultTimeout
          : Duration(seconds: timeoutSeconds),
    );
  }

  final String apiKey;
  final String model;
  final Duration? timeout;

  bool get hasApiKey => apiKey.isNotEmpty;

  Duration get requestTimeout => timeout ?? defaultTimeout;
}
