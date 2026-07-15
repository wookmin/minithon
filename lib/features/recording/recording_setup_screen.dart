import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/ui/soft_card.dart';
import '../../core/notifications/notification_providers.dart';
import '../analysis/analysis_history_providers.dart';
import '../analysis/analysis_pipeline.dart';
import '../classification/classification_providers.dart';
import '../care/care_models.dart';
import '../../core/firebase/firebase_providers.dart';
import '../care/care_providers.dart';
import '../classification/need_classification_result.dart';
import 'audio_transcription_providers.dart';
import 'recording_candidate.dart';
import 'recording_import_service.dart';
import 'recording_repository.dart';

class RecordingSetupScreen extends ConsumerStatefulWidget {
  const RecordingSetupScreen({super.key});

  @override
  ConsumerState<RecordingSetupScreen> createState() =>
      _RecordingSetupScreenState();
}

class _RecordingSetupScreenState extends ConsumerState<RecordingSetupScreen> {
  var _candidates = <RecordingCandidate>[];
  bool _isPicking = false;
  bool _isScanning = false;
  String? _transcribingPath;

  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;
    await [
      Permission.phone,
      Permission.audio,
      Permission.storage,
      Permission.notification,
    ].request();
    // 삼성 등에서 절전으로 리시버가 죽지 않도록 배터리 최적화 예외를 요청(시스템 팝업).
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<void> _pickManual(List<CareRecipient> recipients) async {
    if (_isPicking || _isScanning) return;
    setState(() => _isPicking = true);
    final candidate = await ref
        .read(recordingImportServiceProvider)
        .pickManual(recipients: recipients);
    if (!mounted) return;
    setState(() {
      _isPicking = false;
      if (candidate != null) {
        _candidates = [candidate, ..._withoutPath(candidate.filePath)];
      }
    });
  }

  Future<void> _scanRecordings(List<CareRecipient> recipients) async {
    if (_isPicking || _isScanning) return;
    setState(() => _isScanning = true);
    final candidates = await ref
        .read(recordingImportServiceProvider)
        .scanRecordings(recipients: recipients);
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _candidates = candidates;
    });
    if (candidates.isEmpty) {
      _showMessage('읽을 수 있는 최근 녹음을 찾지 못했어요');
    }
  }

  Future<void> _transcribe(RecordingCandidate candidate) async {
    if (!candidate.isMatched) {
      _showMessage('등록된 돌봄자와 매칭된 녹음만 분석해요');
      return;
    }
    setState(() => _transcribingPath = candidate.filePath);
    try {
      final uri = candidate.contentUri;
      final bytes = uri != null
          ? await ref.read(recordingRepositoryProvider).readBytes(uri)
          : await File(candidate.filePath).readAsBytes();
      if (bytes == null) {
        if (mounted) _showMessage('녹음 파일을 읽지 못했어요');
        return;
      }
      final result = await ref
          .read(audioTranscriptionServiceProvider)
          .transcribe(bytes: bytes, mimeType: _mimeType(candidate.fileName));
      if (!mounted) return;
      if (!result.isSuccess) {
        _showMessage(result.error ?? '전사에 실패했어요');
        return;
      }
      // 전사 → 분류 → 기록 저장 → (니즈 있으면) 알림 + 부모 지역 구인글 초안.
      final me = ref.read(myProfileProvider).asData?.value;
      final analysis = await runNeedAnalysis(
        classifier: ref.read(needClassifierProvider),
        history: ref.read(analysisHistoryProvider.notifier),
        notifications: ref.read(notificationServiceProvider),
        text: result.text!,
        recipientName: candidate.matchedRecipient?.name ?? '알 수 없음',
        callTime: candidate.createdAt,
        recipientRegion: candidate.matchedRecipient?.address ?? '',
        requesterUid: ref.read(currentUidProvider) ?? '',
        requesterName: me?.name ?? '',
        onErrandDraft: (draft) =>
            ref.read(errandRequestsProvider.notifier).add(draft),
      );
      if (!mounted) return;
      if (analysis.failed) {
        _showMessage(analysis.reason);
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => _TranscriptSheet(
          candidate: candidate,
          transcript: result.text!,
          result: analysis,
        ),
      );
    } on Object catch (error) {
      if (mounted) _showMessage('파일을 읽지 못했어요: $error');
    } finally {
      if (mounted) setState(() => _transcribingPath = null);
    }
  }

  List<RecordingCandidate> _withoutPath(String path) {
    return _candidates
        .where((candidate) => candidate.filePath != path)
        .toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _mimeType(String fileName) {
    switch (fileName.split('.').last.toLowerCase()) {
      case 'mp3':
        return 'audio/mp3';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'amr':
        return 'audio/amr';
      case 'flac':
        return 'audio/flac';
      case 'ogg':
        return 'audio/ogg';
      case '3gp':
        return 'audio/3gpp';
      case 'm4a':
      case 'caf':
      default:
        return 'audio/mp4';
    }
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(recordingSetupProvider).asData?.value;
    final recipients =
        ref.watch(careRecipientsProvider).asData?.value ?? const [];
    final completed = setup?.isCompleted ?? false;
    final backgroundEnabled = setup?.backgroundDetectionEnabled ?? false;
    final text = Theme.of(context).textTheme;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('녹음 연결')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            completed ? '녹음 분석이 준비됐어요' : '녹음이 들어오는 길을 연결해요',
            style: text.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '등록된 돌봄자의 전화번호나 이름과 매칭된 녹음만 STT와 니즈 분류로 넘깁니다.',
            style: text.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          const _SetupStep(
            number: '1',
            title: 'Android 통화 자동녹음 켜기',
            description: '전화 앱에서 통화 자동녹음을 켜두면 통화 종료 알림 흐름과 연결됩니다.',
          ),
          const SizedBox(height: 10),
          const _SetupStep(
            number: '2',
            title: '등록된 돌봄자와 매칭',
            description: '파일명 속 전화번호를 우선 확인하고, 없으면 이름으로 한 번 더 확인합니다.',
          ),
          const SizedBox(height: 10),
          const _SetupStep(
            number: '3',
            title: 'STT와 Gemini 분류로 전달',
            description: '매칭된 녹음만 전사하고, 우리 앱이 도울 수 있는 니즈가 있을 때만 알림을 보냅니다.',
          ),
          const SizedBox(height: 22),
          SoftCard(
            child: Row(
              children: [
                IconTile(
                  icon: Icons.notifications_active_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  background: Theme.of(context).colorScheme.primaryContainer,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('통화 종료 자동 감지', style: text.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        backgroundEnabled ? '켜짐 · 백그라운드 알림 준비됨' : '꺼짐',
                        style: text.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: backgroundEnabled,
                  onChanged: completed
                      ? (value) => ref
                            .read(recordingSetupProvider.notifier)
                            .setBackgroundDetectionEnabled(value)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: completed
                ? () => context.pop()
                : () async {
                    await _requestPermissions();
                    await ref.read(recordingSetupProvider.notifier).complete();
                    if (mounted) _showMessage('자동 감지 설정을 저장했어요');
                  },
            icon: Icon(completed ? Icons.check_rounded : Icons.flag_rounded),
            label: Text(completed ? '설정 완료됨' : '1회 등록 완료하기'),
          ),
          const SizedBox(height: 28),
          Text('녹음 파일 가져오기', style: text.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ImportActionCard(
                  icon: Icons.upload_file_rounded,
                  title: '파일 직접 선택',
                  subtitle: 'iOS 시뮬레이터와 실기기 테스트용',
                  isBusy: _isPicking,
                  onTap: () => _pickManual(recipients),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImportActionCard(
                  icon: Icons.folder_open_rounded,
                  title: '최근 녹음 불러오기',
                  subtitle: Platform.isAndroid
                      ? 'Android 최근 녹음 목록'
                      : 'Android 전용',
                  isBusy: _isScanning,
                  onTap: Platform.isAndroid
                      ? () => _scanRecordings(recipients)
                      : () => _showMessage('최근 녹음 불러오기는 Android에서만 지원해요'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_candidates.isEmpty)
            SoftCard(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                '아직 가져온 녹음 후보가 없어요. 샘플 파일명에 등록된 번호나 이름을 넣으면 매칭 흐름을 확인하기 좋아요.',
                style: text.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            )
          else ...[
            Text('녹음 후보 ${_candidates.length}개', style: text.titleMedium),
            const SizedBox(height: 10),
            for (final candidate in _candidates) ...[
              _RecordingCandidateCard(
                candidate: candidate,
                isTranscribing: _transcribingPath == candidate.filePath,
                onTranscribe: () => _transcribe(candidate),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _ImportActionCard extends StatelessWidget {
  const _ImportActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isBusy,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SoftCard(
      onTap: isBusy ? null : onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isBusy
              ? const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RecordingCandidateCard extends StatelessWidget {
  const _RecordingCandidateCard({
    required this.candidate,
    required this.isTranscribing,
    required this.onTranscribe,
  });

  final RecordingCandidate candidate;
  final bool isTranscribing;
  final VoidCallback onTranscribe;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final matched = candidate.isMatched;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                icon: matched
                    ? Icons.verified_rounded
                    : Icons.info_outline_rounded,
                color: matched ? scheme.primary : colors.textSecondary,
                background: matched
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        candidate.sourceLabel,
                        candidate.matchLabel,
                        if (candidate.createdAt != null)
                          _formatDate(candidate.createdAt!),
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            matched
                ? '${candidate.matchedRecipient!.name} (${candidate.matchedRecipient!.relationship}) 녹음으로 확인됐어요'
                : '등록된 전화번호나 이름과 맞지 않아 자동 분석하지 않아요',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: matched && !isTranscribing ? onTranscribe : null,
              icon: isTranscribing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.graphic_eq_rounded),
              label: Text(isTranscribing ? '전사 중' : 'STT 확인'),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day} ${two(dateTime.hour)}:${two(dateTime.minute)}';
  }
}

class _TranscriptSheet extends StatelessWidget {
  const _TranscriptSheet({
    required this.candidate,
    required this.transcript,
    required this.result,
  });

  final RecordingCandidate candidate;
  final String transcript;
  final NeedClassificationResult result;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final actionable = result.hasActionableNeed;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('분석 결과', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            candidate.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: actionable
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionable ? '니즈를 감지했어요' : '특별한 니즈가 없어요',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  actionable
                      ? '${result.labels} · 알림을 보냈어요'
                      : '알림을 보내지 않았어요',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('통화 내용', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SingleChildScrollView(
              child: Text(
                transcript,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.45,
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
