import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gemini/gemini_api_config.dart';
import 'gemini/gemini_classifier.dart';
import 'need_classifier.dart';

/// 니즈 분류기 교체 지점.
///
/// 테스트에서는 `overrideWithValue`로 가짜 분류기를 주입한다.
final geminiApiConfigProvider = Provider<GeminiApiConfig>(
  (ref) => GeminiApiConfig.fromEnv(),
);

final needClassifierProvider = Provider<NeedClassifier>(
  (ref) => GeminiClassifier(config: ref.watch(geminiApiConfigProvider)),
);
