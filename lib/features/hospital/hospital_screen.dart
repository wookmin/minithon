import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/soft_card.dart';
import '../profile/profile_providers.dart';
import 'hospital.dart';
import 'hospital_repository.dart';

class HospitalScreen extends ConsumerWidget {
  const HospitalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(parentProfileProvider);
    final repository = ref.watch(hospitalRepositoryProvider);
    final accent = context.colors.health;

    return FutureBuilder<List<Hospital>>(
      future: repository.findNearby(profile.address),
      builder: (context, snapshot) {
        final hospitals = snapshot.data ?? const [];
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
                count: hospitals.length,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(label: '전체', selected: true, accent: accent),
                  _FilterChip(label: '정형외과', accent: accent),
                  _FilterChip(label: '내과', accent: accent),
                  _FilterChip(label: '통증', accent: accent),
                  _FilterChip(label: '재활', accent: accent),
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
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
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
    this.selected = false,
  });

  final String label;
  final Color accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
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
  final int age;
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
                      '$name 님 · $age세',
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
      onTap: () {},
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
                        const SizedBox(width: 8),
                        _OpenBadge(isOpen: hospital.isOpenNow),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(hospital.department, style: text.bodyMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
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
                          ' (${hospital.reviewCount}) · ${hospital.distance}',
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
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
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('${hospital.name} · ${hospital.phone}'),
                        ),
                      );
                  },
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
