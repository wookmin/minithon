import 'package:flutter/material.dart';

import '../theme/app_colors_x.dart';
import '../theme/app_shape.dart';

class FavoriteHospitalField extends StatelessWidget {
  const FavoriteHospitalField({
    super.key,
    required this.controller,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: '자주 가는 병원',
        hintText: '없으면 비워둬도 돼요',
        helperText: '부모님 정보로 저장해 두면 도움 요청에 참고할 수 있어요.',
        prefixIcon: Icon(Icons.local_hospital_outlined, color: c.health),
        constraints: const BoxConstraints(minHeight: 60),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.surface),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
