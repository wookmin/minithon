import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cloud Functions 배포 리전. (functions/src/index.ts 의 setGlobalOptions 와 일치)
const kFunctionsRegion = 'asia-northeast3';

/// 서버 callable 함수를 호출하고 결과를 문자열 키 맵으로 돌려주는 시그니처.
///
/// 테스트에서는 이 함수를 가짜로 주입해 서버 없이 동작을 검증한다.
typedef CallableInvoker =
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> payload,
    );

/// callable 응답(data)은 중첩 맵이 `Map<Object?, Object?>`로 오므로 문자열 키로 정규화.
Map<String, dynamic> callableDataToMap(Object? data) {
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

final firebaseFunctionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: kFunctionsRegion),
);

final callableInvokerProvider = Provider<CallableInvoker>((ref) {
  // FirebaseFunctions 는 실제 호출 시점에만 해석한다.
  // (Firebase 미초기화 환경에서 provider/위젯 빌드가 깨지지 않도록 지연 접근)
  return (name, payload) async {
    final functions = ref.read(firebaseFunctionsProvider);
    final result = await functions.httpsCallable(name).call(payload);
    return callableDataToMap(result.data);
  };
});
