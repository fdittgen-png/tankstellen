import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

/// Default [NotificationService] implementation backed by
/// `flutter_local_notifications`.
///
/// Uses the Android `price_alerts` channel for high-priority price drop
/// notifications. On iOS the same plugin handles the UNUserNotificationCenter
/// setup (not yet active — iOS build is disabled).
class LocalNotificationService implements NotificationService {
  /// Visible for testing — allows injecting a fake plugin.
  final FlutterLocalNotificationsPlugin plugin;

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'price_alerts';
  static const _channelName = 'Price Alerts';
  static const _channelDescription =
      'Notifications when fuel prices drop below your target';

  /// #584 — separate channel for service reminders so the user can
  /// independently mute maintenance reminders without muting price
  /// drops (and vice versa). Default importance is lower than price
  /// alerts — a missed oil change is less time-sensitive than a
  /// short-lived price dip.
  static const _serviceChannelId = 'service_reminders';
  static const _serviceChannelName = 'Service reminders';
  static const _serviceChannelDescription =
      'Reminders when your odometer crosses a scheduled service interval';

  @override
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await plugin.initialize(settings: initSettings);
  }

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await plugin.show(
        id: id, title: title, body: body, notificationDetails: details);
  }

  @override
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _serviceChannelId,
        _serviceChannelName,
        channelDescription: _serviceChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await plugin.show(
        id: id, title: title, body: body, notificationDetails: details);
  }

  @override
  Future<void> cancelNotification(int id) async {
    await plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }
}
