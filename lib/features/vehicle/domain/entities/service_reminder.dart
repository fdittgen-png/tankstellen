import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_reminder.freezed.dart';
part 'service_reminder.g.dart';

/// Odometer-triggered maintenance reminder for a [VehicleProfile]
/// (#584).
///
/// Stored in the `service_reminders` Hive box keyed by [id]. Each
/// reminder carries the last-service odometer value; the trigger
/// fires when the current odometer crosses
/// `lastServiceOdometerKm + intervalKm`. Marking the reminder done
/// sets [lastServiceOdometerKm] to the current odometer so the next
/// cycle starts from there.
///
/// [pendingAcknowledgment] goes `true` when a fill-up crosses the
/// threshold and the local notification has been fired; it clears
/// back to `false` when the user hits "mark as done" so the UI badge
/// disappears.
@freezed
abstract class ServiceReminder with _$ServiceReminder {
  const factory ServiceReminder({
    required String id,

    /// The vehicle this reminder belongs to. Fills-ups are checked
    /// only against reminders that match the fill-up's vehicleId.
    required String vehicleId,

    /// Short label — "Oil change", "Tires", "Inspection". Stored
    /// verbatim; localisation happens in the UI if the label matches
    /// a known preset.
    required String label,

    /// Service interval in km between occurrences.
    required double intervalKm,

    /// Odometer reading at the last service. Null when the user
    /// added the reminder but hasn't yet recorded a completion — the
    /// first fill-up that brings the odometer above `intervalKm`
    /// will trip the alert.
    double? lastServiceOdometerKm,

    /// Toggle for pausing a reminder without deleting it — the
    /// trigger skips inactive reminders. Defaults to `true` so a new
    /// reminder is armed immediately.
    @Default(true) bool isActive,

    /// Set to `true` after the trigger fires and the notification
    /// has been shown; reset by `markDone`. The vehicle edit row
    /// shows a badge when this is `true` so the user can confirm
    /// completion.
    @Default(false) bool pendingAcknowledgment,
  }) = _ServiceReminder;

  const ServiceReminder._();

  factory ServiceReminder.fromJson(Map<String, dynamic> json) =>
      _$ServiceReminderFromJson(json);

  /// Odometer value at which the next reminder should fire.
  double get nextDueOdometerKm =>
      (lastServiceOdometerKm ?? 0) + intervalKm;

  /// True when [currentOdometerKm] has crossed the due threshold.
  bool isDue(double currentOdometerKm) =>
      currentOdometerKm >= nextDueOdometerKm;

  /// Kilometres past the due threshold at [currentOdometerKm]. Returns
  /// a non-negative value — 0 when the reminder is exactly at the
  /// threshold, the positive overrun otherwise. Used for the "{kmOver}
  /// km past due" line in the notification body.
  double kmOverdue(double currentOdometerKm) {
    final over = currentOdometerKm - nextDueOdometerKm;
    return over < 0 ? 0 : over;
  }

  /// Returns a new reminder rebased to [currentOdometerKm] — the next
  /// due cycle starts from here, and the pending-ack flag clears.
  ServiceReminder markDone(double currentOdometerKm) => copyWith(
        lastServiceOdometerKm: currentOdometerKm,
        pendingAcknowledgment: false,
      );
}
