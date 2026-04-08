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
  Future<void> cancelNotification(int id) async {
    await plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }
}
