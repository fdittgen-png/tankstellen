import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_reminder.freezed.dart';
part 'service_reminder.g.dart';

/// Odometer-triggered maintenance reminder for a [VehicleProfile]
/// (#584).
///
/// Stored as a list field on VehicleProfile. Each reminder carries
/// the last-service odometer value; the trigger fires when the
/// current odometer crosses `lastServiceOdometerKm + intervalKm`.
/// Marking the reminder done resets `lastServiceOdometerKm` to the
/// current odometer so the next cycle starts from there.
@freezed
abstract class ServiceReminder with _$ServiceReminder {
  const factory ServiceReminder({
    required String id,
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
}
