import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

/// main()에서 초기화된 인스턴스로 override 된다.
/// 테스트에서는 가짜 서비스로 override.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(
    'notificationServiceProvider must be overridden',
  ),
);
