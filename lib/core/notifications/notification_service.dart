// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Abstract notification service interface.
///
/// Decouples notification logic from the concrete plugin so an
/// alternative backend can be swapped in without changing call sites.
/// The default implementation is [LocalNotificationService] which
/// wraps `flutter_local_notifications`.
abstract class NotificationService {
  /// Initialize the notification subsystem (registers channels + the
  /// tap callback). Does NOT request the runtime permission — call
  /// [requestPermission] from a foreground/user-intent moment.
  Future<void> initialize();

  /// Request the OS runtime notification permission (Android 13+
  /// `POST_NOTIFICATIONS`, iOS authorization). Returns whether it is
  /// granted. #2209 — without this, `show()` silently no-ops on
  /// Android 13+ and no alert ever appears.
  Future<bool> requestPermission();

  /// Whether the OS currently allows this app to post notifications.
  /// Used to surface a "notifications are off" recovery banner when the
  /// user has alerts but has denied/disabled the permission.
  Future<bool> areNotificationsEnabled();

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
