import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/core/ui/phone_number_field.dart';

void main() {
  const formatter = KoreanMobilePhoneFormatter();

  TextEditingValue format(String value) {
    return formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: value),
    );
  }

  test('숫자만 입력하면 010-XXXX-XXXX 형식으로 바꾼다', () {
    expect(format('010').text, '010');
    expect(format('0101').text, '010-1');
    expect(format('0101234').text, '010-1234');
    expect(format('01012345678').text, '010-1234-5678');
  });

  test('하이픈이나 공백이 섞여도 숫자 기준으로 다시 포맷한다', () {
    expect(format('010 1234 5678').text, '010-1234-5678');
    expect(format('010-1234-5678').text, '010-1234-5678');
  });

  test('11자리를 넘는 숫자는 잘라낸다', () {
    expect(format('01012345678999').text, '010-1234-5678');
  });
}
