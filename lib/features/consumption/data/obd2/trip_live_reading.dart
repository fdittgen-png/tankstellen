import 'package:flutter/foundation.dart';

/// Live read-out from the currently-recording trip (#726).
///
/// Emitted on every debounced tick so the recording screen can show the
/// user speed / RPM / distance / estimated fuel without having to
/// ask the recorder for a full summary each time.
///
/// Extracted from `trip_recording_controller.dart` as part of the
/// #563 controller-split refactor. The controller still re-exports
/// this type so existing imports keep working.
@immutable
class TripLiveReading {
  final double? speedKmh;
  final double? rpm;
  final double? fuelRateLPerHour;
  final double? fuelLevelPercent;
  final double? engineLoadPercent;

  /// Absolute throttle position, 0–100 %. Subscribed to the 5 Hz tier
  /// of the PidScheduler (#814) so the eco-feedback UI and the
  /// future coasting-detection logic have a direct signal instead of
  /// the engine-load proxy. Null when the adapter hasn't surfaced PID
  /// 11 or the first tick hasn't landed yet.
  final double? throttlePercent;

  /// Engine coolant temperature in °C (PID 0x05). Null when the car
  /// doesn't surface the PID or the first tick hasn't landed. Persists
  /// onto [TripSample] so the cold-start surcharge heuristic (#1262
  /// phase 2) can read it post-trip — engines that never reach
  /// operating temperature burn proportionally more fuel for warm-up.
  final double? coolantTempC;
  final double distanceKmSoFar;
  final double? fuelLitersSoFar;
  final Duration elapsed;
  final double? odometerStartKm;
  final double? odometerNowKm;

  const TripLiveReading({
    this.speedKmh,
    this.rpm,
    this.fuelRateLPerHour,
    this.fuelLevelPercent,
    this.engineLoadPercent,
    this.throttlePercent,
    this.coolantTempC,
    required this.distanceKmSoFar,
    this.fuelLitersSoFar,
    required this.elapsed,
    this.odometerStartKm,
    this.odometerNowKm,
  });

  /// Live L/100 km estimate — uses trip-so-far totals, so early
  /// samples are noisy and converge as the trip progresses. Returns
  /// null when the car doesn't surface a fuel-rate PID.
  double? get liveAvgLPer100Km {
    if (fuelLitersSoFar == null || distanceKmSoFar < 0.01) return null;
    return fuelLitersSoFar! / distanceKmSoFar * 100.0;
  }
}
