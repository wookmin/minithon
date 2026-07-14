import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/action_sheet.dart';
import '../../core/ui/soft_card.dart';
import 'hospital.dart';

class HospitalMapScreen extends StatelessWidget {
  const HospitalMapScreen({super.key, required this.hospital});

  final Hospital hospital;

  Future<void> _call(BuildContext context) async {
    final confirmed = await showActionConfirmSheet(
      context,
      title: hospital.phone,
      message: '이 번호로 전화를 연결할까요?',
      icon: Icons.call_rounded,
      confirmLabel: '전화 걸기',
    );
    if (!confirmed || !context.mounted) return;
    final uri = Uri(scheme: 'tel', path: hospital.phone.replaceAll('-', ''));
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showSnackBar(context, '전화 앱을 열지 못했어요.');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('병원 위치'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: !hospital.hasLocation
                ? _NoLocation(address: hospital.address)
                : _MapView(hospital: hospital),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            child: SoftCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: c.healthSoft,
                          borderRadius: BorderRadius.circular(
                            AppRadius.surface,
                          ),
                        ),
                        child: Icon(
                          Icons.local_hospital_rounded,
                          color: c.health,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hospital.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hospital.department,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: c.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hospital.address.isEmpty
                              ? '주소 정보 없음'
                              : hospital.address,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.list_rounded, size: 18),
                          label: const Text('목록'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: hospital.phone.isEmpty
                              ? null
                              : () => _call(context),
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: const Text('전화'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// OSM 타일 기반 인터랙티브 지도. 병원 좌표에 마커를 찍는다. (API 키 불필요)
class _MapView extends StatelessWidget {
  const _MapView({required this.hospital});

  final Hospital hospital;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final point = LatLng(hospital.latitude!, hospital.longitude!);

    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: 16,
        minZoom: 5,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.flingAnimation,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.minihackathon.senior_needs',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 56,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  color: c.health,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: c.health.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
        // OSM 타일 사용 시 저작자 표시 필요.
        const Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(top: 8, right: 8),
            child: _Attribution(),
          ),
        ),
      ],
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '© OpenStreetMap',
          style: TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ),
    );
  }
}

class _NoLocation extends StatelessWidget {
  const _NoLocation({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 48, color: c.textSecondary),
            const SizedBox(height: 14),
            Text('지도 좌표가 없어요', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              address.isEmpty ? '병원 주소를 확인한 뒤 다시 시도해주세요.' : address,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
