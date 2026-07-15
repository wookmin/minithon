import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/classification/need_category.dart';
import 'notification_payload.dart';

/// 로컬 알림 래퍼.
///
/// - [init]에서 채널 생성 + Android 13+ 권한 요청 + 탭 콜백 등록.
/// - [showNeedNotification]은 [NeedCategory.none]이면 아무것도 하지 않는다.
/// - 알림 payload에 목적지 라우트를 실어, 탭 시 [onSelectRoute]로 전달한다.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'need_alerts';
  static const _channelName = '니즈 알림';
  static const _channelDescription = '부모님 니즈가 발견되면 알려줍니다.';

  static const _reminderNotificationId = 9001;
  // 진행/실패 알림은 같은 id를 재사용해 "분석 중" → "실패"로 대체된다.
  static const _analysisNotificationId = 9002;

  /// 알림 탭 시 이동할 라우트를 전달받는 콜백. (main에서 라우터에 연결)
  void Function(String route)? onSelectRoute;

  Future<void> init({
    required void Function(String route) onSelectRoute,
  }) async {
    this.onSelectRoute = onSelectRoute;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTap,
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// 앱이 종료 상태에서 알림 탭으로 실행됐는지 확인해 초기 라우트를 반환.
  Future<String?> initialRoute() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }

  Future<void> showNeedNotification(NeedCategory category) async {
    final route = routeForCategory(category);
    final content = notificationContentFor(category);
    if (route == null || content == null) return; // none → 알림 없음

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    // iOS는 앱이 포그라운드일 때 이 옵션이 없으면 배너를 띄우지 않는다.
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    );

    await _plugin.show(
      id: category.index,
      title: content.title,
      body: content.body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: route,
    );
  }

  /// 자동 통화 분석이 꺼져 있음을 알리는 리마인더. 탭하면 녹음 연결 화면으로.
  Future<void> showAnalysisOffReminder() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    );

    await _plugin.show(
      id: _reminderNotificationId,
      title: '자동 통화 분석이 꺼져 있어요',
      body: '통화 후 부모님의 니즈를 놓칠 수 있어요. 탭해서 켜주세요.',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: '/recording-setup',
    );
  }

  /// 백그라운드 분석이 시작됐음을 알리는 진행 알림. (조용한 ongoing 알림)
  Future<void> showAnalyzing({String? recipientName}) async {
    final who = (recipientName != null && recipientName.trim().isNotEmpty)
        ? '$recipientName님과의 통화'
        : '통화';
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      showProgress: true,
      indeterminate: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentBanner: false,
      presentSound: false,
    );

    await _plugin.show(
      id: _analysisNotificationId,
      title: '통화 내용 분석 중',
      body: '$who 내용을 확인하고 있어요…',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  /// 진행 알림 제거. (분석이 니즈 알림/무니즈로 정상 종료됐을 때)
  Future<void> cancelAnalyzing() => _plugin.cancel(id: _analysisNotificationId);

  /// 분석이 실패했음을 사유와 함께 알린다. 진행 알림을 이 알림으로 대체한다.
  Future<void> showAnalysisFailed(String reason) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    );

    await _plugin.show(
      id: _analysisNotificationId,
      title: '통화 분석을 못 했어요',
      body: analysisFailureMessage(reason),
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: '/recording-setup',
    );
  }

  void _onTap(NotificationResponse response) {
    final route = response.payload;
    if (route != null && route.isNotEmpty) {
      onSelectRoute?.call(route);
    }
  }
}

/// 서버가 준 실패 사유를 사용자 친화 문구로 변환한다.
/// AI 사용량 한도(quota) 초과는 별도의 안내 문구로 바꾼다.
String analysisFailureMessage(String reason) {
  final lower = reason.toLowerCase();
  final isQuota = lower.contains('quota') ||
      lower.contains('resource_exhausted') ||
      lower.contains('exhausted') ||
      lower.contains('rate limit') ||
      lower.contains('429');
  if (isQuota) {
    return 'AI 사용량 한도를 초과했어요. 잠시 후 다시 시도해 주세요.';
  }
  return reason.trim().isEmpty ? '알 수 없는 오류로 분석에 실패했어요.' : reason.trim();
}
