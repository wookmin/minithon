/// 주소 문자열에서 지역 매칭 단위(시/군/구)를 뽑는다.
///
/// 구·군은 시보다 좁은 생활권이라 우선한다. (예: "성남시 분당구" → "분당구")
/// 카카오 도로명 주소("서울 강남구 테헤란로 1")와 자유 입력("강남구 역삼동")을
/// 같은 키로 정규화해, 형식이 달라도 같은 지역이면 매칭되게 한다.
String regionKey(String address) {
  final tokens = address.trim().split(RegExp(r'\s+'))
    ..removeWhere((token) => token.isEmpty);
  if (tokens.isEmpty) return '';

  for (final suffix in const ['구', '군']) {
    for (var i = tokens.length - 1; i >= 0; i--) {
      if (tokens[i].endsWith(suffix)) return tokens[i];
    }
  }
  for (final token in tokens) {
    if (token.endsWith('시')) return token;
  }
  return '';
}

/// 두 주소가 같은 지역(시/군/구)인지 판정한다. 키를 못 뽑으면 매칭하지 않는다.
bool sameRegion(String a, String b) {
  final keyA = regionKey(a);
  if (keyA.isEmpty) return false;
  return keyA == regionKey(b);
}
