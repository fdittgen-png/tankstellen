import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'local_notification_service.dart';
import 'notification_service.dart';

part 'notification_providers.g.dart';

/// Provides the app-wide [NotificationService] instance.
///
/// Kept alive for the entire app lifetime because the notification subsystem
/// is initialized once in `main()` and reused by background tasks and UI.
/// Defaults to [LocalNotificationService]; override in tests or when
/// adding FCM support.
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return LocalNotificationService();
}
