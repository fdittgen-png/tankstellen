/// Abstract notification service interface.
///
/// Decouples notification logic from the concrete plugin so that
/// alternative backends (e.g. FCM, ntfy push relay) can be swapped in
/// without changing call sites. The default implementation is
/// [LocalNotificationService] which wraps `flutter_local_notifications`.
abstract class NotificationService {
  /// Initialize the notification subsystem (channels, permissions, etc.).
  Future<void> initialize();

  /// Display a price-alert notification.
  ///
  /// [id] should be stable per station so that re-triggers update
  /// the existing notification instead of creating duplicates.
  ///
  /// [payload] is forwarded to the underlying plugin so the tap
  /// listener can deep-link the user back into the app on the right
  /// screen (#1012 phase 3). Pure-string format — see
  /// [NotificationPayload.encode] for the JSON shape the radius
  /// alert runner emits.
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// Display a service-reminder notification (#584). Uses a distinct
  /// channel on Android so the user can mute price alerts without
  /// silencing maintenance reminders.
  ///
  /// [id] should be stable per reminder so repeated triggers (e.g.
  /// because the same fill-up is re-saved) update the existing
  /// notification instead of stacking.
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  });

  /// Cancel a specific notification by its [id].
  Future<void> cancelNotification(int id);

  /// Cancel all active notifications.
  Future<void> cancelAll();
}
