import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/category_visual.dart';
import '../../core/ui/soft_card.dart';
import '../analysis/analysis_pipeline.dart';
import '../care/care_models.dart';
import '../care/care_providers.dart';
import '../classification/need_category.dart';
import '../classification/need_classification_result.dart';
import '../recording/audio_transcription_providers.dart';
import '../recording/recording_candidate.dart';
import '../recording/recording_matcher.dart';
import '../recording/recording_repository.dart';
import '../recording/shared_audio_providers.dart';
import '../stt/stt_providers.dart';

/// 통화 분석 화면. 텍스트·음성·녹음 파일을 니즈 분류에 태운다.
///
/// 텍스트 입력 → 분류 → 니즈가 있으면 알림 표시. 알림 탭 시 해당 탭으로 이동.
class CallAnalysisScreen extends ConsumerStatefulWidget {
  const CallAnalysisScreen({
    super.key,
    this.autoAnalyzeLatest = false,
    this.analyzeSharedAudio = false,
  });

  /// 통화 종료 알림을 탭해 진입한 경우 true — 최근 녹음을 자동 분석한다.
  final bool autoAnalyzeLatest;

  /// 공유 시트로 오디오가 들어와 진입한 경우 true — 공유된 파일을 자동 분석한다.
  final bool analyzeSharedAudio;

  @override
  ConsumerState<CallAnalysisScreen> createState() => _CallAnalysisScreenState();
}

class _CallAnalysisScreenState extends ConsumerState<CallAnalysisScreen> {
  final _controller = TextEditingController();
  NeedClassificationResult? _lastResult;
  bool _isAnalyzing = false;
  bool _isListening = false;
  bool _isTranscribing = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoAnalyzeLatest) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _analyzeLatestRecording(),
      );
    } else if (widget.analyzeSharedAudio) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _analyzeSharedAudio(),
      );
    }
  }

  List<CareRecipient> _recipientList() =>
      ref.read(careRecipientsProvider).asData?.value ?? const [];

  Future<void> _analyzeSharedAudio() async {
    if (_isAnalyzing || _isTranscribing) return;

    final path = ref.read(sharedAudioPathProvider);
    ref.read(sharedAudioPathProvider.notifier).set(null); // 소비
    if (path == null || path.isEmpty) return;

    final recipients = _recipientList();
    if (recipients.isEmpty) {
      _showMessage('먼저 부모님을 등록해주세요');
      return;
    }

    setState(() => _isTranscribing = true);
    final Uint8List bytes;
    try {
      bytes = await File(path).readAsBytes();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _isTranscribing = false);
      _showMessage('공유된 파일을 읽지 못했어요: $error');
      return;
    }
    if (!mounted) return;

    final candidate = const RecordingMatcher().match(
      filePath: path,
      displayName: path.split('/').last,
      sourceType: RecordingImportSourceType.background,
      recipients: recipients,
    );
    await _transcribeAndAnalyze(
      bytes,
      _mimeForExtension(path.split('.').last),
      recipient: candidate.matchedRecipient ?? recipients.first,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAndTranscribe() async {
    if (_isAnalyzing || _isTranscribing) return;

    final recipients = _recipientList();
    if (recipients.isEmpty) {
      _showMessage('먼저 부모님을 등록해주세요');
      return;
    }

    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'm4a',
        'mp3',
        'wav',
        'aac',
        'aiff',
        'flac',
        'ogg',
        'caf',
      ],
      withData: true,
    );
    if (selection == null) return;

    final file = selection.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      _showMessage('파일을 읽지 못했어요');
      return;
    }

    final candidate = const RecordingMatcher().match(
      filePath: file.name,
      displayName: file.name,
      sourceType: RecordingImportSourceType.manual,
      recipients: recipients,
    );
    await _transcribeAndAnalyze(
      bytes,
      _mimeForExtension(file.extension),
      recipient: candidate.matchedRecipient ?? recipients.first,
    );
  }

  Future<void> _analyzeLatestRecording() async {
    if (_isAnalyzing || _isTranscribing) return;

    final recipients = _recipientList();
    if (recipients.isEmpty) {
      _showMessage('먼저 부모님을 등록해주세요');
      return;
    }

    final granted = await _ensureAudioPermission();
    if (!mounted) return;
    if (!granted) {
      _showMessage('녹음 파일을 읽으려면 오디오 접근 권한이 필요해요');
      return;
    }

    setState(() => _isTranscribing = true);
    RecordingCandidate? matched;
    Uint8List? bytes;
    try {
      final repository = ref.read(recordingRepositoryProvider);
      final recordings = await repository.recent(limit: 10);
      const matcher = RecordingMatcher();
      for (final recording in recordings) {
        final candidate = matcher.match(
          filePath: '${recording.relativePath}${recording.name}',
          displayName: recording.name,
          contentUri: recording.uri,
          sourceType: RecordingImportSourceType.folderScan,
          recipients: recipients,
          createdAt: recording.dateAdded,
        );
        if (candidate.isMatched) {
          matched = candidate;
          break;
        }
      }
      if (matched == null) {
        if (!mounted) return;
        setState(() => _isTranscribing = false);
        _showMessage('최근 녹음 중 등록된 부모님과 매칭되는 통화가 없어요');
        return;
      }
      bytes = await repository.readBytes(matched.contentUri!);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _isTranscribing = false);
      _showMessage('녹음을 불러오지 못했어요: $error');
      return;
    }
    if (!mounted) return;

    if (bytes == null) {
      setState(() => _isTranscribing = false);
      _showMessage('녹음 파일을 읽지 못했어요');
      return;
    }

    await _transcribeAndAnalyze(
      bytes,
      _mimeForExtension(matched.fileName.split('.').last),
      recipient: matched.matchedRecipient,
      callTime: matched.createdAt,
    );
  }

  Future<bool> _ensureAudioPermission() async {
    final status = await Permission.audio.request();
    if (status.isGranted) return true;
    // 구형 안드로이드는 저장소 권한으로 폴백.
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<void> _transcribeAndAnalyze(
    Uint8List bytes,
    String mimeType, {
    CareRecipient? recipient,
    DateTime? callTime,
  }) async {
    setState(() => _isTranscribing = true);
    final service = ref.read(audioTranscriptionServiceProvider);
    final result = await service.transcribe(bytes: bytes, mimeType: mimeType);
    if (!mounted) return;
    setState(() => _isTranscribing = false);

    if (!result.isSuccess) {
      _showMessage(result.error ?? '전사에 실패했어요');
      return;
    }

    _controller.text = result.text!;
    await _analyze(recipient: recipient, callTime: callTime);
  }

  String _mimeForExtension(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'mp3':
        return 'audio/mp3';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'aiff':
        return 'audio/aiff';
      case 'flac':
        return 'audio/flac';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
      case 'caf':
      default:
        return 'audio/mp4';
    }
  }

  Future<void> _analyze({CareRecipient? recipient, DateTime? callTime}) async {
    if (_isAnalyzing) return;

    setState(() => _isAnalyzing = true);
    final input = _controller.text.trim();
    final recipientName =
        recipient?.name ??
        ref.read(careRecipientsProvider).asData?.value.firstOrNull?.name ??
        '알 수 없음';

    final result = await runNeedAnalysis(
      ref,
      text: input,
      recipientName: recipientName,
      callTime: callTime,
    );

    if (!mounted) return;
    setState(() {
      _lastResult = result;
      _isAnalyzing = false;
    });

    _showMessage(
      result.hasActionableNeed ? '분석을 완료했어요.' : '확인이 필요한 내용은 없었어요.',
    );
  }

  Future<void> _toggleListening() async {
    final stt = ref.read(speechTranscriptionServiceProvider);

    if (_isListening || stt.isListening) {
      await stt.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    await stt.listen(
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _controller.text = text;
          _controller.selection = TextSelection.collapsed(offset: text.length);
          if (isFinal) _isListening = false;
        });
      },
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(status)));
      },
    );

    if (!stt.isListening && mounted) {
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('통화 분석')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.surface),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: scheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '부모님 통화 내용',
                  style: text.headlineMedium?.copyWith(fontSize: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '텍스트·음성·녹음 파일 중 편한 방법으로 넣으면, 도움이 필요한 말만 골라 알려드려요.',
            style: text.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 18),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '예: 허리가 아프다 / 전등을 고쳐야 한다',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_isAnalyzing || _isTranscribing)
                            ? null
                            : _toggleListening,
                        icon: Icon(
                          _isListening
                              ? Icons.stop_rounded
                              : Icons.mic_none_rounded,
                          size: 20,
                        ),
                        label: Text(_isListening ? '중지' : '음성 입력'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: (_isAnalyzing || _isTranscribing)
                            ? null
                            : _analyze,
                        icon: _isAnalyzing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search_rounded, size: 20),
                        label: Text(_isAnalyzing ? '분석 중' : '분석하기'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: (_isAnalyzing || _isTranscribing)
                      ? null
                      : _pickAndTranscribe,
                  icon: _isTranscribing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.graphic_eq_rounded, size: 20),
                  label: Text(_isTranscribing ? '녹음 파일 분석 중' : '녹음 파일 올리기'),
                ),
                if (Platform.isAndroid) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: (_isAnalyzing || _isTranscribing)
                        ? null
                        : _analyzeLatestRecording,
                    icon: const Icon(Icons.history_rounded, size: 20),
                    label: const Text('최근 통화 녹음 분석'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '이렇게 말해보세요',
            style: text.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sample in const [
                '허리가 아프다',
                '전등을 고쳐야 한다',
                '밥은 먹었니, 날씨가 춥다',
                '허리도 아프고 전등도 나갔어',
              ])
                _SampleChip(
                  label: sample,
                  onTap: () {
                    _controller.text = sample;
                    _analyze();
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          if (_lastResult != null) _ResultCard(result: _lastResult!),
        ],
      ),
    );
  }
}

class _SampleChip extends StatelessWidget {
  const _SampleChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: context.colors.hairline),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final NeedClassificationResult result;

  @override
  Widget build(BuildContext context) {
    final actionable = result.hasActionableNeed;
    final visual = categoryVisual(context, result.primaryCategory);
    final accent = actionable ? visual.color : context.colors.textSecondary;
    final soft = actionable ? visual.soft : context.colors.hairline;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(AppRadius.surface),
                ),
                child: Icon(
                  actionable ? visual.icon : Icons.check_circle_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actionable ? '니즈를 감지했어요' : '특별한 니즈가 없어요',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      actionable ? '알림을 보냈어요 · 탭하면 이동' : '알림을 보내지 않았어요',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actionable) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in result.categories)
                  _CategoryChip(category: category),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.surface),
            ),
            child: Text(
              result.reason,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final NeedCategory category;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(context, category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: visual.soft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 15, color: visual.color),
          const SizedBox(width: 5),
          Text(
            visual.label,
            style: TextStyle(
              color: visual.color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
