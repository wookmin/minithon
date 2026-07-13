import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/functions/functions_client.dart';
import 'functions_need_classifier.dart';
import 'need_classifier.dart';

/// 니즈 분류기 교체 지점.
///
/// 테스트에서는 `overrideWithValue`로 가짜 분류기를 주입한다.
final needClassifierProvider = Provider<NeedClassifier>(
  (ref) => FunctionsNeedClassifier(invoke: ref.watch(callableInvokerProvider)),
);
