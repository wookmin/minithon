import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/notifications/notification_providers.dart';
import 'core/notifications/notification_service.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/auth_repository.dart';
import 'features/care/care_providers.dart';
// 백그라운드 통화 분석 진입점(backgroundCallAnalysisMain)을 앱 스냅샷에 포함시키기 위한 import.
// 네이티브 WorkManager가 함수명으로 실행하므로, 이 라이브러리가 컴파일에 포함돼야 한다.
// ignore: unused_import
import 'features/recording/background_call_analysis.dart';
import 'features/recording/recording_repository.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } on Object catch (error) {
    debugPrint('.env 로드 실패 (기능 일부 비활성): $error');
  }

  try {
    await Firebase.initializeApp();
  } on Object catch (error) {
    // flutterfire configure 전이면 초기화 실패 → 로그인 액션에서 안내.
    debugPrint('Firebase 초기화 실패 (flutterfire configure 필요): $error');
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  final notificationService = NotificationService(
    FlutterLocalNotificationsPlugin(),
  );

  final authRepository = FirebaseAuthRepository();
  final router = createRouter(authRepository: authRepository);

  try {
    await notificationService.init(onSelectRoute: (route) => router.go(route));

    // 앱이 알림 탭으로 실행됐다면 해당 화면으로 진입.
    final launchRoute = await notificationService.initialRoute();
    if (launchRoute != null) {
      router.go(launchRoute);
    }
  } on Object catch (error) {
    debugPrint('알림 초기화 실패: $error');
  }

  // 안드로이드: 통화 종료 알림으로 실행/재개된 경우 최근 녹음 분석 화면으로.
  if (Platform.isAndroid) {
    final recordingRepository = RecordingRepository();
    recordingRepository.setAnalyzeListener(
      () => router.go('/call-analysis?auto=1'),
    );
    if (await recordingRepository.consumePendingAnalyze()) {
      router.go('/call-analysis?auto=1');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        notificationServiceProvider.overrideWithValue(notificationService),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: SeniorNeedsApp(router: router),
    ),
  );
}
