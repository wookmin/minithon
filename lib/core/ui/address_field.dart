import 'package:flutter/material.dart';
import 'package:kpostal/kpostal.dart';

/// 탭하면 다음(카카오) 우편번호 검색을 띄워 도로명주소를 선택·입력하는 필드.
/// 직접 타이핑 대신 검색해서 고른다. (읽기 전용 표시)
class AddressField extends StatelessWidget {
  const AddressField({
    super.key,
    required this.controller,
    this.label = '집 주소',
    this.hint = '주소 검색 (도로명)',
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  Future<void> _search(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(context).push<Kpostal>(
      MaterialPageRoute(builder: (_) => KpostalView()),
    );
    if (result != null) controller.text = result.address;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _search(context),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: const Icon(Icons.search_rounded),
      ),
    );
  }
}
