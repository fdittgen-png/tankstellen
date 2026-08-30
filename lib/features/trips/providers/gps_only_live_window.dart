// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../obd2/api.dart' show RollingConsumptionWindow, TripLiveReading;
import '../domain/trip_recorder.dart' show TripSample;

/// #3883 — the GPS-only pipeline's rolling "last N s" consumption: fed
/// with the physics estimate (L/100 km × speed → L/h) per fix, stamped
/// onto the live reading. Split out of `gps_only_recording_pipeline.dart`
/// (400-line cap).
class GpsOnlyLiveWindow {
  final RollingConsumptionWindow _window = RollingConsumptionWindow();

  TripLiveReading stamp(
    TripLiveReading reading, {
    required TripSample sample,
    required double? instantLPer100Km,
    required int windowSeconds,
  }) {
    _window.add(
      now: sample.timestamp,
      fuelRateLPerHour: (instantLPer100Km != null && sample.speedKmh > 0)
          ? instantLPer100Km / 100.0 * sample.speedKmh
          : null,
      speedKmh: sample.speedKmh,
    );
    final w = _window.read(Duration(seconds: windowSeconds));
    if (w == null) return reading;
    return reading.copyWith(
      windowLPer100Km: w.lPer100Km,
      windowLPerHour: w.lPerHour,
      windowIsIdle: w.isIdle,
      windowSeconds: windowSeconds,
    );
  }
}
