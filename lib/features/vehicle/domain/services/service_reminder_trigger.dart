import '../entities/service_reminder.dart';

/// Pure domain helper that decides which reminders an odometer
/// reading trips (#584).
///
/// Kept free of repositories and platform channels so the unit tests
/// can drive it with plain data. The notification layer composes it
/// with [ServiceReminderRepository] and [NotificationService].
class ServiceReminderTrigger {
  const ServiceReminderTrigger();

  /// Returns the subset of [reminders] that fire when the vehicle's
  /// odometer reads [currentOdometerKm].
  ///
  /// Rules:
  /// - Only reminders attached to [vehicleId] are considered.
  /// - Inactive reminders (`isActive == false`) are skipped.
  /// - Reminders already flagged `pendingAcknowledgment` are skipped —
  ///   the notification has already been shown and the user has not
  ///   acknowledged it yet. We do not re-notify until they mark it
  ///   done.
  /// - A reminder fires when `currentOdometerKm` is at or past the
  ///   reminder's `nextDueOdometerKm`.
  List<ServiceReminder> findTriggered({
    required String vehicleId,
    required double currentOdometerKm,
    required List<ServiceReminder> reminders,
  }) {
    return reminders
        .where((r) =>
            r.vehicleId == vehicleId &&
            r.isActive &&
            !r.pendingAcknowledgment &&
            r.isDue(currentOdometerKm))
        .toList();
  }
}
