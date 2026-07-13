import 'dart:io';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/notifications/notification_providers.dart';
import '../../core/notifications/notification_service.dart';
import '../analysis/analysis_history_providers.dart';
import '../analysis/analysis_pipeline.dart';
import '../care/care_providers.dart';
import '../classification/classification_providers.dart';
import 'audio_transcription_providers.dart';
import 'recording_candidate.dart';
import 'recording_matcher.dart';

/// 백그라운드(앱 종료 포함)에서 통화 종료 시 네이티브 WorkManager가 헤드리스로 실행하는 진입점.
///
/// 네이티브는 최근 녹음을 임시파일로 저장한 뒤 이 엔진을 부팅한다.
/// 여기서 파일 정보를 받아 매칭 → 전사 → 분류 → 결과 알림까지 수행한다.
/// UI가 없으므로 [ProviderContainer]로 앱과 동일한 파이프라인([runNeedAnalysis])을 재사용한다.
@pragma('vm:entry-point')
Future<void> backgroundCallAnalysisMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  const channel = MethodChannel('senior_needs/bg_analysis');
  ProviderContainer? container;
  try {
    await Firebase.initializeApp();
    // 저장된 로그인 세션이 복원될 때까지 대기(없으면 null로 진행 → 대상자 없음 처리).
    await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => null);

    final prefs = await SharedPreferences.getInstance();
    final notification = NotificationService(FlutterLocalNotificationsPlugin());
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notification),
      ],
    );

    // 자동 분석 설정이 켜져 있을 때만 진행. 꺼져 있으면(또는 미설정) 녹음 조회·STT·분류를
    // 일절 하지 않는다. (사용자 동의 없이 통화 내용이 서버로 가지 않도록)
    final setup = await container.read(recordingSetupProvider.future);
    if (!setup.backgroundDetectionEnabled) return;

    // 네이티브가 최근 녹음 메타데이터(바이트 제외)를 넘긴다.
    final pending = await channel.invokeMapMethod<String, dynamic>('getPending');
    final rawList = (pending?['recordings'] as List?) ?? const [];
    if (rawList.isEmpty) return;

    final recipients = await container.read(careRecipientsProvider.future);
    if (recipients.isEmpty) return;

    // 등록된 대상자와 매칭되는 첫 녹음을 찾는다.
    const matcher = RecordingMatcher();
    String? matchedUri;
    ({String recipientName, String fileName, DateTime? createdAt})? matched;
    for (final item in rawList) {
      if (item is! Map) continue;
      final name = item['name'] as String? ?? '';
      final relativePath = item['relativePath'] as String? ?? '';
      final uri = item['uri'] as String? ?? '';
      final candidate = matcher.match(
        filePath: '$relativePath$name',
        displayName: name,
        contentUri: uri,
        sourceType: RecordingImportSourceType.background,
        recipients: recipients,
      );
      if (candidate.isMatched) {
        matchedUri = uri;
        matched = (
          recipientName: candidate.matchedRecipient!.name,
          fileName: name,
          createdAt: candidate.createdAt,
        );
        break;
      }
    }
    if (matchedUri == null || matched == null) return;

    // 중복 분석 방지: 같은 녹음(uri)을 이미 처리했으면 건너뛴다.
    // (중복 broadcast·재실행·탭 분석과의 겹침으로 인한 중복 STT/Gemini/기록 방지)
    const lastAnalyzedKey = 'lastAnalyzedRecordingUri';
    if (prefs.getString(lastAnalyzedKey) == matchedUri) return;

    // 매칭된 것만 바이트를 임시파일로 받아 읽는다.
    final tempPath = await channel.invokeMethod<String>('readBytes', {
      'uri': matchedUri,
    });
    if (tempPath == null || tempPath.isEmpty) return;
    final bytes = await File(tempPath).readAsBytes();
    if (bytes.isEmpty) return;

    // 알림 표시용 초기화. 탭 라우팅은 앱 재실행 시 main isolate의 initialRoute가 담당한다.
    await notification.init(onSelectRoute: (_) {});

    final stt = await container
        .read(audioTranscriptionServiceProvider)
        .transcribe(bytes: bytes, mimeType: _mimeForName(matched.fileName));
    if (!stt.isSuccess) return;

    await runNeedAnalysis(
      classifier: container.read(needClassifierProvider),
      history: container.read(analysisHistoryProvider.notifier),
      notifications: notification,
      text: stt.text!,
      recipientName: matched.recipientName,
      callTime: matched.createdAt,
    );
    await prefs.setString(lastAnalyzedKey, matchedUri);
  } on Object catch (error) {
    debugPrint('백그라운드 통화 분석 실패: $error');
  } finally {
    container?.dispose();
    // 네이티브가 임시파일 정리 + 엔진 종료하도록 완료 신호.
    try {
      await channel.invokeMethod('done');
    } on Object catch (_) {}
  }
}

String _mimeForName(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  switch (ext) {
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'aac':
      return 'audio/aac';
    case 'ogg':
      return 'audio/ogg';
    case 'flac':
      return 'audio/flac';
    case 'amr':
      return 'audio/amr';
    case 'm4a':
    default:
      return 'audio/mp4';
  }
}
