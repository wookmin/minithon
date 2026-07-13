import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_payload.dart';
import '../../core/theme/app_colors_x.dart';
import '../../core/theme/app_shape.dart';
import '../../core/ui/category_visual.dart';
import '../../core/ui/soft_card.dart';
import 'analysis_history_providers.dart';
import 'analysis_record.dart';

class AnalysisHistoryScreen extends ConsumerWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(analysisHistoryProvider);
    final records = history.asData?.value ?? const <AnalysisRecord>[];
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('통화 분석 기록')),
      body: records.isEmpty
          ? _Empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _RecordCard(record: records[index], now: now),
            ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.now});

  final AnalysisRecord record;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final actionable = record.hasActionableNeed;
    final visual = categoryVisual(context, record.primaryCategory);
    final route = routeForCategory(record.primaryCategory);
    final accent = actionable ? visual.color : c.textSecondary;
    final soft = actionable ? visual.soft : c.hairline;

    return SoftCard(
      onTap: actionable && route != null ? () => context.go(route) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(AppRadius.surface),
                ),
                child: Icon(
                  actionable ? visual.icon : Icons.check_circle_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  actionable ? visual.label : '특별한 니즈 없음',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                record.relativeTime(now),
                style: TextStyle(color: c.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (record.reason.isNotEmpty)
            Text(
              record.reason,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (record.snippet.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.surface),
              ),
              child: Text(
                '"${record.snippet}"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 44, color: c.textSecondary),
            const SizedBox(height: 14),
            Text(
              '아직 분석한 통화가 없어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '통화를 분석하면 여기에 기록으로 쌓여요.',
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
