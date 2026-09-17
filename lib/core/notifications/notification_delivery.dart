// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
