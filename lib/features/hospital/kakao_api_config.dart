import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 카카오 로컬 API 설정. REST API 키를 .env에서 읽는다.
class KakaoApiConfig {
  const KakaoApiConfig({required this.restApiKey, this.timeout});

  static const defaultTimeout = Duration(seconds: 8);

  factory KakaoApiConfig.fromEnv() {
    final key = dotenv.isInitialized
        ? dotenv.env['KAKAO_REST_API_KEY']?.trim() ?? ''
        : '';
    return KakaoApiConfig(restApiKey: key);
  }

  final String restApiKey;
  final Duration? timeout;

  bool get hasKey => restApiKey.isNotEmpty;

  Duration get requestTimeout => timeout ?? defaultTimeout;
}
