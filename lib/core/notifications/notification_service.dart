import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);
  }

  static Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'price_alerts',
        'Price Alerts',
        channelDescription:
            'Notifications when fuel prices drop below your target',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(id: id, title: title, body: body, notificationDetails: details);
  }
}
