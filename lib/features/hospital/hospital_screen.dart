import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/action_sheet.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/soft_card.dart';
import '../profile/profile_providers.dart';
import 'hospital.dart';
import 'hospital_repository.dart';

Future<void> _call(BuildContext context, String phone) async {
  final confirmed = await showActionConfirmSheet(
    context,
    title: phone,
    message: '이 번호로 전화를 연결할까요?',
    icon: Icons.call_rounded,
    confirmLabel: '전화 걸기',
  );
  if (!confirmed || !context.mounted) return;
  final uri = Uri(scheme: 'tel', path: phone.replaceAll('-', ''));
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    _showLaunchError(context, '전화 앱을 열지 못했어요.');
  }
}

void _openMap(BuildContext context, Hospital hospital) {
  context.push('/hospital-map', extra: hospital);
}

void _showLaunchError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class HospitalScreen extends ConsumerStatefulWidget {
  const HospitalScreen({super.key});

  @override
  ConsumerState<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends ConsumerState<HospitalScreen> {
  static const _filters = ['전체', '정형외과', '내과', '통증', '재활'];
  String _filter = '전체';

  // 필터 변경 setState로 재조회되지 않도록 주소별로 Future를 캐시한다.
  Future<List<Hospital>>? _future;
  String? _futureAddress;

  Future<List<Hospital>> _hospitals(HospitalRepository repo, String address) {
    if (_future == null || _futureAddress != address) {
      _futureAddress = address;
      _future = repo.findNearby(address);
    }
    return _future!;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(parentProfileProvider);
    final repository = ref.watch(hospitalRepositoryProvider);
    final accent = context.colors.health;

    if (profile == null) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          ScreenHeader(
            eyebrow: '건강',
            title: '가까운 병원 찾기',
            subtitle: '부모님 주소를 기준으로 자주 갈 병원을 확인하세요.',
            accent: accent,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _RegisterParentPrompt(accent: accent),
          ),
        ],
      );
    }

    return FutureBuilder<List<Hospital>>(
      future: _hospitals(repository, profile.address),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <Hospital>[];
        final hospitals = _filter == '전체'
            ? all
            : all.where((h) => h.department.contains(_filter)).toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            ScreenHeader(
              eyebrow: '건강',
              title: '가까운 병원 찾기',
              subtitle: '부모님 주소를 기준으로 자주 갈 병원을 확인하세요.',
              accent: accent,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ProfileHero(
                name: profile.name,
                age: profile.age,
                address: profile.address,
                count: all.length,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final f in _filters)
                    _FilterChip(
                      label: f,
                      accent: accent,
                      selected: f == _filter,
                      onTap: () => setState(() => _filter = f),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '주변 병원 ${hospitals.length}곳',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 10),
            if (!snapshot.hasData)
              for (var i = 0; i < 3; i++)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _HospitalSkeleton(),
                )
            else if (hospitals.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                child: Text(
                  "'$_filter' 진료과 병원이 아직 없어요",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              )
            else
              for (final h in hospitals)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _HospitalCard(hospital: h, accent: accent),
                ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.accent,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? accent : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? accent : context.colors.hairline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : context.colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterParentPrompt extends StatelessWidget {
  const _RegisterParentPrompt({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SoftCard(
      onTap: () => context.push('/onboarding'),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: c.healthSoft,
              borderRadius: BorderRadius.circular(AppRadius.surface),
            ),
            child: Icon(Icons.person_add_alt_1_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '부모님을 먼저 등록해주세요',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '주소를 등록하면 주변 병원을 찾아드려요.',
                  style: Theme.of(context).textTheme.bodyMedium,
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.age,
    required this.address,
    required this.count,
  });

  final String name;
  final int? age;
  final String address;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: c.healthSoft,
                child: Text(
                  name.characters.first,
                  style: TextStyle(
                    color: c.health,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      age == null ? '$name 님' : '$name 님 · $age세',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 15,
                          color: c.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            address,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.surface),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: c.health),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '주소 기준 병원 $count곳을 찾았어요',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  const _HospitalCard({required this.hospital, required this.accent});

  final Hospital hospital;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MapThumb(accent: accent, soft: c.healthSoft),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(hospital.name, style: text.titleMedium),
                        ),
                        if (hospital.hours.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _OpenBadge(isOpen: hospital.isOpenNow),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(hospital.department, style: text.bodyMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (hospital.rating > 0) ...[
                          Icon(Icons.star_rounded, size: 15, color: accent),
                          const SizedBox(width: 2),
                          Text(
                            hospital.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            ' (${hospital.reviewCount}) · ',
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: c.textSecondary,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          hospital.distance,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hospital.hours.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 15, color: c.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hospital.hours,
                    style: TextStyle(color: c.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openMap(context, hospital),
                  icon: const Icon(Icons.place_outlined, size: 18),
                  label: const Text('길찾기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: hospital.phone.isEmpty
                      ? null
                      : () => _call(context, hospital.phone),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: const Text('전화'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HospitalSkeleton extends StatelessWidget {
  const _HospitalSkeleton();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Skeleton(width: 54, height: 54, radius: AppRadius.surface),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 140, height: 15, radius: AppRadius.pill),
                    SizedBox(height: 8),
                    Skeleton(width: 90, height: 12, radius: AppRadius.pill),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Skeleton(
            width: double.infinity,
            height: 44,
            radius: AppRadius.control,
          ),
        ],
      ),
    );
  }
}

/// 지도 대신 쓰는 스타일 썸네일 (핀 아이콘 + 소프트 배경).
class _MapThumb extends StatelessWidget {
  const _MapThumb({required this.accent, required this.soft});

  final Color accent;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadius.surface),
      ),
      child: Icon(Icons.location_on_rounded, color: accent, size: 26),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = isOpen ? const Color(0xFF2E8B57) : c.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? '진료중' : '마감',
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
