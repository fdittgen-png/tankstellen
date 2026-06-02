// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../domain/trip_sample.dart';

/// #2565 — builds the GPS-only [TripSample] the [TripRecordingController]
/// feeds its recorder while in the `degradedGpsOnly` phase (OBD2 dropped
/// mid-trip but GPS is alive), and answers the "is a real GPS fix recent
/// enough to keep recording?" question the degrade decision turns on.
///
/// Extracted as a small pure collaborator so the conflict-magnet
/// god-class `TripRecordingController` (at its grandfathered file-length
/// snapshot with zero headroom) does not grow when it gains the
/// GPS-only sample path — mirroring the dependency-light collaborator
/// style of `TripDistanceResolver` (#2187) and `LiveSampleSnapshot`
/// (#1679). No `package:geolocator` coupling: the controller already
/// keeps the GPS speed latch + the last-fix timestamp, so this builder
/// works on those raw values + the injected clock.
class GpsOnlySampleBuilder {
  /// Build a GPS-only [TripSample] equivalent to
  /// `GpsOnlyRecordingPipeline._onPosition`: speed from the GPS latch,
  /// `rpm: 0`, lat/lon/alt from the latest snapshot, `fuelRateLPerHour`
  /// left null so the GPS-physics estimate + coaching overlay runs.
  static TripSample build({
    required DateTime timestamp,
    required double speedKmh,
    double? latitude,
    double? longitude,
    double? altitudeM,
    double? hAccuracyM,
    double? bearingDeg,
  }) {
    return TripSample(
      timestamp: timestamp,
      speedKmh: speedKmh,
      rpm: 0,
      latitude: latitude,
      longitude: longitude,
      altitudeM: altitudeM,
      // #2648 — the degraded GPS-only path used to drop horizontal
      // accuracy + bearing too; stamp them so a trip that degrades to
      // GPS-only still feeds the cornering analytic + accuracy-gate.
      hAccuracyM: hAccuracyM,
      bearingDeg: bearingDeg,
    );
  }

  /// Whether a real GPS fix landed within [window] of [now] — the
  /// degrade decision's "GPS is alive" test. [lastGpsFixAt] is the
  /// controller's `_gpsEndedAt` latch (the timestamp of the most recent
  /// real fix; null until the first fix). Returns false when no fix has
  /// ever arrived so a dead-GPS drop keeps the classic pause path.
  static bool gpsAlive({
    required DateTime? lastGpsFixAt,
    required DateTime now,
    required Duration window,
  }) {
    if (lastGpsFixAt == null) return false;
    return now.difference(lastGpsFixAt) <= window;
  }
}
