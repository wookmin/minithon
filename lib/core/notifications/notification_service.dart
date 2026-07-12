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

  void _onTap(NotificationResponse response) {
    final route = response.payload;
    if (route != null && route.isNotEmpty) {
      onSelectRoute?.call(route);
    }
  }
}
