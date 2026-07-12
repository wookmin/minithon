import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/ui/soft_card.dart';
import '../care/care_providers.dart';

class RecordingSetupScreen extends ConsumerWidget {
  const RecordingSetupScreen({super.key});

  /// 백그라운드 통화 감지·녹음 분석에 필요한 권한을 한 번에 요청. (Android)
  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;
    await [Permission.phone, Permission.audio, Permission.notification]
        .request();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingSetupProvider).asData?.value;
    final completed = state?.isCompleted ?? false;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('자동녹음 등록')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            completed ? '등록이 완료됐어요' : '한 번만 설정하면 돼요',
            style: text.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '통화가 끝난 뒤 분석 알림을 받을 수 있도록 설정 상태를 저장합니다.',
            style: text.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 22),
          const _SetupStep(
            number: '1',
            title: '휴대폰 통화 자동녹음 켜기',
            description: 'Android 전화 앱에서 통화 자동녹음을 켜두는 과정을 안내합니다.',
          ),
          const SizedBox(height: 10),
          const _SetupStep(
            number: '2',
            title: '권한 허용 (전화 상태·오디오·알림)',
            description: '통화 종료를 감지하고 최신 녹음 파일을 읽기 위해 권한을 한 번 허용합니다.',
          ),
          const SizedBox(height: 10),
          const _SetupStep(
            number: '3',
            title: '통화 끝나면 자동 안내',
            description: '통화가 끝나면 알림이 오고, 탭하면 최근 녹음을 분석해 니즈를 골라냅니다.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: completed
                ? () => context.pop()
                : () async {
                    await _requestPermissions();
                    await ref.read(recordingSetupProvider.notifier).complete();
                    if (context.mounted) context.pop();
                  },
            icon: Icon(completed ? Icons.check_rounded : Icons.flag_rounded),
            label: Text(completed ? '홈으로 돌아가기' : '등록 완료하기'),
          ),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
