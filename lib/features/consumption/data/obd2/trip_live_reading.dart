// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

  /// Exact tank fuel level in litres from an OEM-specific PID
  /// (#1615). Non-null only when the `experimentalOemPids` flag is on
  /// AND the connected adapter is OEM-PID-capable AND a manufacturer
  /// table resolved for the vehicle's VIN — otherwise null, and
  /// consumers fall back to the coarse `fuelLevelPercent × capacity`
  /// conversion. Independent of [fuelLevelPercent]: the standard PID
  /// `0x2F` percentage keeps flowing regardless.
  final double? fuelLevelLitres;

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

  /// Live GPS-only fuel estimate in L/100 km (Epic #2385 / #2389),
  /// produced by the calibrated physics road-load `GpsLiveFuelEstimator`
  /// on trajets that have **no** OBD2 fuel-rate signal. Non-null only on
  /// GPS-only recordings, and only once the vehicle is actually moving
  /// (the estimator returns null at a standstill and before its accel
  /// low-pass has warmed up). Already clamped to the estimator's
  /// plausibility band.
  ///
  /// On OBD2 trips this stays null — the real measured fuel-rate /
  /// [fuelLitersSoFar] is the source of truth and is never overwritten by
  /// the estimate. The PiP / banner render this instantaneous figure
  /// (with a leading "~" and a confidence signal) per #2390; the
  /// recording-screen Avg card (#2391) uses the *running-average*
  /// companion [gpsEstimatedAvgLPer100Km] instead.
  final double? gpsEstimatedLPer100Km;

  /// Live GPS-estimated **running-average** L/100 km (#2391 / Epic
  /// #2385) — litres-so-far ÷ distance-so-far, as produced by the
  /// physics estimator's `runningAvgLPer100Km`. Smoother than the
  /// per-tick [gpsEstimatedLPer100Km]; this is what the recording
  /// screen's Avg card renders (with a leading "~" + the calibration-
  /// maturity badge). Null on OBD2 trips (the measured
  /// [liveAvgLPer100Km] wins) and before the vehicle has covered
  /// distance.
  final double? gpsEstimatedAvgLPer100Km;

  /// Live GPS-estimated litres burned so far (#2391) — the estimator's
  /// running `litersSoFar` integral. Fills the recording screen's
  /// Fuel-used card for GPS-only trips, which would otherwise show `—`
  /// the whole drive (there is no measured [fuelLitersSoFar]). Rendered
  /// with a leading "~". Null on OBD2 trips + before the first moving
  /// sample.
  final double? gpsEstimatedFuelLitersSoFar;

  const TripLiveReading({
    this.speedKmh,
    this.rpm,
    this.fuelRateLPerHour,
    this.fuelLevelPercent,
    this.fuelLevelLitres,
    this.engineLoadPercent,
    this.throttlePercent,
    this.coolantTempC,
    required this.distanceKmSoFar,
    this.fuelLitersSoFar,
    required this.elapsed,
    this.odometerStartKm,
    this.odometerNowKm,
    this.gpsEstimatedLPer100Km,
    this.gpsEstimatedAvgLPer100Km,
    this.gpsEstimatedFuelLitersSoFar,
  });

  /// Overlay one or more fields onto a copy of this reading (#2506).
  ///
  /// Convention: a null argument **keeps** the existing value. The OBD2
  /// live path uses this to fold the GPS-physics estimate
  /// (`gpsEstimatedLPer100Km/Avg/FuelLitersSoFar`) and the GPS-track
  /// speed/distance fallback onto the freshly-built measured reading when
  /// no fuel-rate PID is measurable, without re-listing every measured
  /// field. Because every overlay site only ever passes non-null values
  /// it actually wants to set, the keep-on-null contract is unambiguous
  /// here.
  TripLiveReading copyWith({
    double? speedKmh,
    double? rpm,
    double? fuelRateLPerHour,
    double? fuelLevelPercent,
    double? fuelLevelLitres,
    double? engineLoadPercent,
    double? throttlePercent,
    double? coolantTempC,
    double? distanceKmSoFar,
    double? fuelLitersSoFar,
    Duration? elapsed,
    double? odometerStartKm,
    double? odometerNowKm,
    double? gpsEstimatedLPer100Km,
    double? gpsEstimatedAvgLPer100Km,
    double? gpsEstimatedFuelLitersSoFar,
  }) {
    return TripLiveReading(
      speedKmh: speedKmh ?? this.speedKmh,
      rpm: rpm ?? this.rpm,
      fuelRateLPerHour: fuelRateLPerHour ?? this.fuelRateLPerHour,
      fuelLevelPercent: fuelLevelPercent ?? this.fuelLevelPercent,
      fuelLevelLitres: fuelLevelLitres ?? this.fuelLevelLitres,
      engineLoadPercent: engineLoadPercent ?? this.engineLoadPercent,
      throttlePercent: throttlePercent ?? this.throttlePercent,
      coolantTempC: coolantTempC ?? this.coolantTempC,
      distanceKmSoFar: distanceKmSoFar ?? this.distanceKmSoFar,
      fuelLitersSoFar: fuelLitersSoFar ?? this.fuelLitersSoFar,
      elapsed: elapsed ?? this.elapsed,
      odometerStartKm: odometerStartKm ?? this.odometerStartKm,
      odometerNowKm: odometerNowKm ?? this.odometerNowKm,
      gpsEstimatedLPer100Km:
          gpsEstimatedLPer100Km ?? this.gpsEstimatedLPer100Km,
      gpsEstimatedAvgLPer100Km:
          gpsEstimatedAvgLPer100Km ?? this.gpsEstimatedAvgLPer100Km,
      gpsEstimatedFuelLitersSoFar:
          gpsEstimatedFuelLitersSoFar ?? this.gpsEstimatedFuelLitersSoFar,
    );
  }

  /// Live L/100 km estimate — uses trip-so-far totals, so early
  /// samples are noisy and converge as the trip progresses. Returns
  /// null when the car doesn't surface a fuel-rate PID.
  double? get liveAvgLPer100Km {
    if (fuelLitersSoFar == null || distanceKmSoFar < 0.01) return null;
    return fuelLitersSoFar! / distanceKmSoFar * 100.0;
  }
}
