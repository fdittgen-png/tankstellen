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
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
  });

  /// Cancel a specific notification by its [id].
  Future<void> cancelNotification(int id);

  /// Cancel all active notifications.
  Future<void> cancelAll();
}
