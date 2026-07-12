import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_providers.dart';
import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/category_visual.dart';
import '../../core/ui/soft_card.dart';
import '../classification/classification_providers.dart';
import '../classification/need_category.dart';
import '../classification/need_classification_result.dart';
import '../stt/stt_providers.dart';

/// 통화 텍스트 분석 화면. (실제 통화 분석 결과 주입 대체)
///
/// 텍스트 입력 → 분류 → 니즈가 있으면 알림 표시. 알림 탭 시 해당 탭으로 이동.
class DevInputScreen extends ConsumerStatefulWidget {
  const DevInputScreen({super.key});

  @override
  ConsumerState<DevInputScreen> createState() => _DevInputScreenState();
}

class _DevInputScreenState extends ConsumerState<DevInputScreen> {
  final _controller = TextEditingController();
  NeedClassificationResult? _lastResult;
  bool _isAnalyzing = false;
  bool _isListening = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_isAnalyzing) return;

    setState(() => _isAnalyzing = true);
    final classifier = ref.read(needClassifierProvider);
    final result = await classifier.classify(_controller.text);

    if (result.hasActionableNeed) {
      await ref
          .read(notificationServiceProvider)
          .showNeedNotification(result.primaryCategory);
    }

    if (!mounted) return;
    setState(() {
      _lastResult = result;
      _isAnalyzing = false;
    });

    final message = !result.hasActionableNeed
        ? '해당하는 니즈 없음 → 알림 없음'
        : '분류: ${result.labels} → 알림 발송됨';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
      appBar: AppBar(title: const Text('통화 텍스트 분석')),
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
            '텍스트를 입력하거나 마이크로 말하면, 도움이 필요한 말만 골라 알려드려요.',
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
                        onPressed: _isAnalyzing ? null : _toggleListening,
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
                        onPressed: _isAnalyzing ? null : _analyze,
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '예시 문장',
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
