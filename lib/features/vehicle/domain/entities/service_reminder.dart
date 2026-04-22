import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_reminder.freezed.dart';
part 'service_reminder.g.dart';

/// Odometer-triggered maintenance reminder (#584 phase 1).
///
/// Each reminder belongs to a single [VehicleProfile] (by
/// [vehicleId]) and carries the last-service odometer reading plus
/// the km interval between services. The companion
/// `ServiceReminderChecker` fires when
/// `currentOdometerKm - lastServiceOdometerKm >= intervalKm`.
///
/// Values are stored as integers because every persisted odometer
/// the app sees comes from the user's manual fill-up entry (a whole
/// km on the dashboard) or OBD2's `distance since codes cleared`
/// PID, both of which are already km-integers. Using `int` avoids
/// the floating-point-equality pitfalls the phase-0 sketch ran into
/// on its `isDue` boundary test.
///
/// Disabled reminders ([enabled] false) never fire — the user can
/// pause a reminder without losing its history.
@freezed
abstract class ServiceReminder with _$ServiceReminder {
  const factory ServiceReminder({
    required String id,
    required String vehicleId,

    /// Short label — "Oil change", "Tires", "Inspection",
    /// "Brake fluid". Stored verbatim in the user's chosen language;
    /// the UI layer may map known preset strings to localised
    /// display labels.
    required String label,

    /// Service interval in whole kilometres between occurrences.
    required int intervalKm,

    /// Odometer reading at the last completed service. Zero is a
    /// legitimate value — it means "due at the next interval from
    /// the odometer's zero" — so the field is non-nullable. Callers
    /// creating a fresh reminder typically pass the vehicle's current
    /// odometer so the first due threshold sits one [intervalKm]
    /// ahead.
    required int lastServiceOdometerKm,
    required DateTime createdAt,
    @Default(true) bool enabled,
  }) = _ServiceReminder;

  factory ServiceReminder.fromJson(Map<String, dynamic> json) =>
      _$ServiceReminderFromJson(json);
}
