import 'entities/service_reminder.dart';

/// Pure-Dart threshold calculator for [ServiceReminder] (#584
/// phase 1).
///
/// Zero Riverpod / Hive imports — mirrors the
/// [RadiusAlertEvaluator] split so the phase-2 background worker
/// can run these checks from a WorkManager isolate without pulling
/// the app's DI graph in.
class ServiceReminderChecker {
  const ServiceReminderChecker();

  /// True iff the reminder is [ServiceReminder.enabled] AND the
  /// vehicle has driven at least [ServiceReminder.intervalKm] since
  /// the last service reading. A negative or zero current odometer
  /// never triggers.
  bool isDue(ServiceReminder reminder, int currentOdometerKm) {
    if (!reminder.enabled) return false;
    return currentOdometerKm - reminder.lastServiceOdometerKm >=
        reminder.intervalKm;
  }

  /// Kilometres remaining until [reminder] is due. Returns a
  /// negative value once the interval has been exceeded — the sign
  /// is the caller's cue to phrase the UI as "2 500 km overdue".
  ///
  /// Independent of [ServiceReminder.enabled] so the UI can still
  /// show the countdown on a paused reminder.
  int kmUntilDue(ServiceReminder reminder, int currentOdometerKm) {
    final nextDue = reminder.lastServiceOdometerKm + reminder.intervalKm;
    return nextDue - currentOdometerKm;
  }

  /// Returns a copy of [reminder] with
  /// [ServiceReminder.lastServiceOdometerKm] snapped to
  /// [currentOdometerKm], so the next cycle starts from the moment
  /// the service was performed.
  ///
  /// Idempotent: calling markServiced twice with the same odometer
  /// value produces the same reminder. The caller is responsible
  /// for persisting the returned copy — the checker is stateless.
  ServiceReminder markServiced(
    ServiceReminder reminder,
    int currentOdometerKm,
  ) {
    return reminder.copyWith(lastServiceOdometerKm: currentOdometerKm);
  }
}
