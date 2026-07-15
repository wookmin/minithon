import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    this.label = '전화번호',
    this.hint = '010-0000-0000',
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        const KoreanMobilePhoneFormatter(),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        constraints: const BoxConstraints(minHeight: 60),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
      ),
    );
  }
}

class KoreanMobilePhoneFormatter extends TextInputFormatter {
  const KoreanMobilePhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final formatted = _format(limited);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
  }
}
