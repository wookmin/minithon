import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/notifications/notification_providers.dart';
import 'core/notifications/notification_service.dart';
import 'features/care/care_providers.dart';
import 'features/recording/recording_repository.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final sharedPreferences = await SharedPreferences.getInstance();

  final notificationService = NotificationService(
    FlutterLocalNotificationsPlugin(),
  );

  final router = createRouter();

  await notificationService.init(onSelectRoute: (route) => router.go(route));

  // 앱이 알림 탭으로 실행됐다면 해당 화면으로 진입.
  final launchRoute = await notificationService.initialRoute();
  if (launchRoute != null) {
    router.go(launchRoute);
  }

  // 안드로이드: 통화 종료 알림으로 실행/재개된 경우 최근 녹음 분석 화면으로.
  if (Platform.isAndroid) {
    final recordingRepository = RecordingRepository();
    recordingRepository.setAnalyzeListener(
      () => router.go('/dev-input?auto=1'),
    );
    if (await recordingRepository.consumePendingAnalyze()) {
      router.go('/dev-input?auto=1');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: SeniorNeedsApp(router: router),
    ),
  );
}
