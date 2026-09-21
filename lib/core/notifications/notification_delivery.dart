// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// What became of one attempt to notify the user (#4162, #4335).
///
/// `OpportunityDispatcher` used to reduce this to a bool — "`show` did not
/// throw" — and everything downstream trusted the bool: the budget slot,
/// the detectors' cooldowns, `PriceAlert.lastTriggeredAt`, the journal's
/// `alertsFired`. The OS, however, lets `show` return normally when it
/// will display nothing (a revoked permission, a disabled channel).
///
/// [posted] means the platform accepted the post. It is not proof a person
/// saw it — a notification can be swiped away unread — and nothing here
/// claims more.
///
/// ## Single owner
///
/// The dispatcher's `_notify` is the one producer for price alerts; the
/// dispatch outcome, the scan journal and the detectors' deferred records
/// observe it.
enum NotificationDelivery {
  /// The platform accepted the post.
  posted,

  /// Not posted: the app may not post notifications at all.
  suppressedPermission,

  /// Not posted: the notification's channel is disabled.
  suppressedChannel,

  /// Not posted: the platform refused or the post threw.
  failed,
}

/// Convenience readings of a [NotificationDelivery].
extension NotificationDeliveryReading on NotificationDelivery {
  /// Whether the platform accepted the post.
  bool get wasPosted => this == NotificationDelivery.posted;

  /// Whether the OS settings, not a fault, kept it from being posted.
  bool get wasSuppressed =>
      this == NotificationDelivery.suppressedPermission ||
      this == NotificationDelivery.suppressedChannel;
}

/// The notification channels a delivery can be refused on (#4335).
enum NotificationChannelKind {
  /// Price alerts — `price_alerts` on Android.
  priceAlerts,

  /// Service reminders — `service_reminders` on Android.
  serviceReminders,
}

/// Asks the OS whether a notification can reach the user right now
/// (#4335).
///
/// A separate interface rather than more members on `NotificationService`,
/// which a dozen test doubles implement: a notifier that cannot answer is
/// simply not a probe, and callers treat it as clear to post. The
/// production notifier, `LocalNotificationService`, always is one.
abstract interface class NotificationDeliveryProbe {
  /// Null when a post on [channel] can reach the user; otherwise the
  /// delivery it would be — [NotificationDelivery.suppressedPermission],
  /// [NotificationDelivery.suppressedChannel], or
  /// [NotificationDelivery.failed] when the platform cannot say.
  ///
  /// Fails closed: an unreadable answer is not "enabled".
  Future<NotificationDelivery?> blockedDelivery(NotificationChannelKind channel);

  /// Open the OS notification settings for this app. Returns whether a
  /// settings screen could be opened.
  Future<bool> openNotificationSettings();
}
