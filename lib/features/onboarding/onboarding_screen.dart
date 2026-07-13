import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/address_field.dart';
import '../../core/ui/favorite_hospital_field.dart';
import '../../core/ui/phone_number_field.dart';
import '../care/care_models.dart';
import '../care/care_providers.dart';

/// 이번 세션에 온보딩을 이미 자동으로 띄웠는지. (중복 유도 방지)
class OnboardingPromptedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markPrompted() => state = true;
}

final onboardingPromptedProvider =
    NotifierProvider<OnboardingPromptedNotifier, bool>(
      OnboardingPromptedNotifier.new,
    );

/// 가입 직후 1회: 돌봄 대상(부모님) 정보를 등록한다.
/// 이름·관계·전화번호·주소는 필수(통화 매칭·병원 검색에 사용), 병원은 선택.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _relationships = ['어머니', '아버지', '할머니', '할아버지', '기타'];

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _hospital = TextEditingController();
  final _customRelationship = TextEditingController();
  String _relationship = '어머니';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _hospital.dispose();
    _customRelationship.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_busy) return;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final address = _address.text.trim();
    final relationship = _resolvedRelationship;
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      _snack('이름, 전화번호, 주소를 입력해주세요.');
      return;
    }
    if (relationship.isEmpty) {
      _snack('관계를 입력해주세요.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(careRecipientsProvider.notifier)
          .save(
            CareRecipient(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: name,
              phoneNumber: phone,
              relationship: relationship,
              address: address,
              favoriteHospital: _hospital.text.trim(),
            ),
          );
      if (mounted) context.go('/home');
    } on Object catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        debugPrint('대상자 저장 실패: $error');
        _snack('저장에 실패했어요. 네트워크 상태를 확인하고 다시 시도해주세요.');
      }
    }
  }

  String get _resolvedRelationship {
    if (_relationship != '기타') return _relationship;
    return _customRelationship.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _busy ? null : () => context.go('/home'),
            child: const Text('건너뛰기'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              '누구를 돌보고 계신가요?',
              style: text.headlineMedium?.copyWith(
                fontSize: 26,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '부모님 정보로 통화를 분석하고,\n주변 병원과 도움을 연결해드려요.',
              style: text.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 26),
            Text('관계', style: text.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _relationships)
                  _RelationChip(
                    label: r,
                    selected: r == _relationship,
                    onTap: () => setState(() => _relationship = r),
                  ),
              ],
            ),
            if (_relationship == '기타') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customRelationship,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '관계 직접 입력',
                  hintText: '예: 이모, 삼촌, 보호 대상자',
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '이름',
                hintText: '예: 홍길동',
              ),
            ),
            const SizedBox(height: 12),
            PhoneNumberField(
              controller: _phone,
              textInputAction: TextInputAction.next,
              hint: '통화 녹음 매칭에 사용해요',
            ),
            const SizedBox(height: 12),
            AddressField(controller: _address, hint: '주소 검색 (주변 병원에 사용)'),
            const SizedBox(height: 12),
            FavoriteHospitalField(
              controller: _hospital,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('등록하고 시작하기'),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '나중에 마이페이지에서 추가·수정할 수 있어요.',
                style: TextStyle(color: c.textSecondary, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelationChip extends StatelessWidget {
  const _RelationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? scheme.primary : c.hairline),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : c.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
