import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/address_field.dart';
import '../../core/ui/favorite_hospital_field.dart';
import '../../core/ui/phone_number_field.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/soft_card.dart';
import '../auth/auth_providers.dart';
import '../care/care_models.dart';
import '../care/care_providers.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipients = ref.watch(careRecipientsProvider);
    final myProfile = ref.watch(myProfileProvider);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const ScreenHeader(
          eyebrow: '마이',
          title: '내 정보',
          subtitle: '대상자 정보와 분석 설정을 관리합니다.',
          accent: Color(0xFF2E6B4F),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: myProfile.when(
            data: (profile) => SoftCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      color: scheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          profile.phoneNumber.isEmpty
                              ? '전화번호 미등록'
                              : profile.phoneNumber,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showMyProfileSheet(context, profile),
                    child: const Text('관리'),
                  ),
                ],
              ),
            ),
            loading: () => const SoftCard(
              child: SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, _) => SoftCard(
              child: Row(
                children: [
                  const Expanded(child: Text('내 정보를 불러오지 못했습니다.')),
                  TextButton(
                    onPressed: () => _showMyProfileSheet(
                      context,
                      const MyProfile(name: '', phoneNumber: ''),
                    ),
                    child: const Text('관리'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '돌봄 대상자',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showRecipientSheet(context, ref),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('추가'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        recipients.when(
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _EmptyRecipientsCard(
                    onAdd: () => _showRecipientSheet(context, ref),
                  ),
                )
              : Column(
                  children: [
                    for (final recipient in items)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: _RecipientCard(
                          recipient: recipient,
                          onEdit: () =>
                              _showRecipientSheet(context, ref, recipient),
                        ),
                      ),
                  ],
                ),
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Padding(
            padding: EdgeInsets.all(20),
            child: Text('대상자 정보를 불러오지 못했습니다.'),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton.icon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('로그아웃'),
          ),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    // 게이트(authState 구독)가 로그아웃을 감지해 자동으로 로그인 화면으로 보낸다.
  }

  void _showRecipientSheet(
    BuildContext context,
    WidgetRef ref, [
    CareRecipient? recipient,
  ]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _RecipientFormSheet(recipient: recipient),
    );
  }

  void _showMyProfileSheet(BuildContext context, MyProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _MyProfileFormSheet(profile: profile),
    );
  }
}

class _MyProfileFormSheet extends ConsumerStatefulWidget {
  const _MyProfileFormSheet({required this.profile});

  final MyProfile profile;

  @override
  ConsumerState<_MyProfileFormSheet> createState() =>
      _MyProfileFormSheetState();
}

class _MyProfileFormSheetState extends ConsumerState<_MyProfileFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if ([name, phone].any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('모든 정보를 입력해주세요.')));
      return;
    }

    await ref
        .read(myProfileProvider.notifier)
        .save(MyProfile(name: name, phoneNumber: phone));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: context.colors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('내 정보 수정', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _Field(controller: _nameController, label: '이름'),
          PhoneNumberField(
            controller: _phoneController,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: _save, child: const Text('저장하기')),
        ],
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.recipient, required this.onEdit});

  final CareRecipient recipient;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${recipient.name} · ${recipient.relationship}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(onPressed: onEdit, child: const Text('관리')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _StateChip(label: '자동 분석 켜짐'),
              _StateChip(label: '최근 통화 오늘'),
            ],
          ),
          const SizedBox(height: 8),
          _InfoLine(icon: Icons.call_outlined, text: recipient.phoneNumber),
          _InfoLine(icon: Icons.home_outlined, text: recipient.address),
          if (recipient.favoriteHospital.isNotEmpty)
            _InfoLine(
              icon: Icons.local_hospital_outlined,
              text: recipient.favoriteHospital,
            ),
        ],
      ),
    );
  }
}

class _EmptyRecipientsCard extends StatelessWidget {
  const _EmptyRecipientsCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      onTap: onAdd,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.surface),
            ),
            child: Icon(Icons.person_add_alt_1_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '돌봄 대상자를 추가해주세요',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '등록된 사람의 통화와 요청만 분석 대상으로 사용해요.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textSecondary),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: c.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: c.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientFormSheet extends ConsumerStatefulWidget {
  const _RecipientFormSheet({this.recipient});

  final CareRecipient? recipient;

  @override
  ConsumerState<_RecipientFormSheet> createState() =>
      _RecipientFormSheetState();
}

class _RecipientFormSheetState extends ConsumerState<_RecipientFormSheet> {
  static const _relationshipOptions = ['어머니', '아버지', '배우자', '조부모', '기타'];

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _hospitalController;
  late final TextEditingController _customRelationshipController;
  late String _relationship;

  @override
  void initState() {
    super.initState();
    final recipient = widget.recipient;
    _nameController = TextEditingController(text: recipient?.name ?? '');
    _phoneController = TextEditingController(
      text: recipient?.phoneNumber ?? '',
    );
    _addressController = TextEditingController(text: recipient?.address ?? '');
    _hospitalController = TextEditingController(
      text: recipient?.favoriteHospital ?? '',
    );
    final savedRelationship = recipient?.relationship;
    if (savedRelationship != null &&
        savedRelationship.isNotEmpty &&
        !_relationshipOptions.contains(savedRelationship)) {
      _relationship = '기타';
      _customRelationshipController = TextEditingController(
        text: savedRelationship,
      );
    } else {
      _relationship = savedRelationship ?? _relationshipOptions.first;
      _customRelationshipController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _hospitalController.dispose();
    _customRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final hospital = _hospitalController.text.trim();
    final relationship = _resolvedRelationship;
    if ([name, phone, address].any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('이름, 전화번호, 주소를 입력해주세요.')));
      return;
    }
    if (relationship.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('관계를 입력해주세요.')));
      return;
    }

    final recipient = CareRecipient(
      id:
          widget.recipient?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      phoneNumber: phone,
      relationship: relationship,
      address: address,
      favoriteHospital: hospital,
    );
    await ref.read(careRecipientsProvider.notifier).save(recipient);
    if (mounted) Navigator.of(context).pop();
  }

  String get _resolvedRelationship {
    if (_relationship != '기타') return _relationship;
    return _customRelationshipController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: context.colors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.recipient == null ? '대상자 추가' : '대상자 수정',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _Field(controller: _nameController, label: '이름'),
          PhoneNumberField(
            controller: _phoneController,
            textInputAction: TextInputAction.next,
          ),
          DropdownButtonFormField<String>(
            initialValue: _relationship,
            decoration: const InputDecoration(labelText: '나와의 관계'),
            items: [
              for (final option in _relationshipOptions)
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _relationship = value);
            },
          ),
          const SizedBox(height: 10),
          if (_relationship == '기타') ...[
            _Field(
              controller: _customRelationshipController,
              label: '관계 직접 입력',
            ),
            const SizedBox(height: 2),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AddressField(controller: _addressController),
          ),
          FavoriteHospitalField(controller: _hospitalController),
          const SizedBox(height: 14),
          FilledButton(onPressed: _save, child: const Text('저장하기')),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
