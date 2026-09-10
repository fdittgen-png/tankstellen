// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../domain/trip_recorder.dart';

/// One sample of the trip recording profile (#890).
///
/// Mirrors the fields of `TripSample` in the domain layer but lives in
/// the presentation layer so the detail screen stays decoupled from
/// the recorder — #890 displays samples when the caller provides them
/// and shows the empty-state caption when it doesn't. Future PRs will
/// persist these samples alongside [TripHistoryEntry] so the screen
/// can render charts for any historical trip; until then this class
/// is the test-only injection point and keeps the contract ready.
@immutable
class TripDetailSample {
  /// Timestamp of the sample. Samples are ordered chronologically by
  /// the chart painters — unsorted input is sorted before plotting.
  final DateTime timestamp;

  /// Vehicle speed in km/h. Non-null for every sample — the recorder
  /// only emits a [TripDetailSample] once speed has been read.
  final double speedKmh;

  /// Engine RPM. May be null when the car's PID cache reports RPM as
  /// unsupported; the [TripDetailRpmChart] hides itself when every
  /// sample carries a null RPM.
  final double? rpm;

  /// Fuel rate in L/h. May be null when neither PID 5E nor the MAF /
  /// speed-density fallback chain from #874 yields a reading; the
  /// fuel-rate chart renders its empty caption when every sample is
  /// null.
  final double? fuelRateLPerHour;

  /// GPS-physics **estimated** fuel rate in L/h (#2431). Populated only
  /// for OBD2/hybrid trips whose adapter+ECU supported no fuel PID, so
  /// [fuelRateLPerHour] is null on every sample. When the measured series
  /// is all-null but this one isn't, [TripDetailFuelRateChart] renders
  /// THIS series with a "geschätzt" (estimated) badge instead of the
  /// empty caption. Null for measured trips and at a standstill.
  final double? estimatedFuelRateLPerHour;

  /// Throttle position % (PID 0x11). Null when the car's PID cache
  /// flagged 0x11 as unsupported, or when persisted by a build before
  /// #1261 (legacy trips). Drives the throttle axis of the throttle /
  /// RPM histogram on the trip-detail screen.
  final double? throttlePercent;

  /// Calculated engine load % (PID 0x04). Null when the car's PID
  /// cache flagged 0x04 as unsupported, or when persisted by a build
  /// before #1262 (legacy trips). Surfaced by the load-aware coaching
  /// chart in phase 3 of #1262 — distinguishes "uphill at 60 km/h"
  /// (high load) from "flat at 60 km/h" (low load).
  final double? engineLoadPercent;

  /// Engine coolant temperature in °C (PID 0x05). Null when the car
  /// doesn't surface the PID, or when persisted by a build before
  /// #1262 (legacy trips). Drives the cold-start surcharge chip in
  /// phase 3 of #1262.
  final double? coolantTempC;

  /// GPS latitude in degrees (#1374 phase 2). Null when the
  /// `Feature.gpsTripPath` flag was disabled at recording time, when
  /// no fix had landed yet, when location permission was revoked, or
  /// when the trip was persisted by a build before #1374 phase 1.
  /// Mirrors `TripSample.latitude` in the domain layer; the
  /// trip-detail GPS-path overlay reads non-null pairs to draw the
  /// recorded route.
  final double? latitude;

  /// GPS longitude in degrees (#1374 phase 2). Same null-semantics as
  /// [latitude]; the two fields are always written and read together.
  final double? longitude;

  /// Accelerator-pedal position % (PIDs 0x49-0x4B, #2461). Driver
  /// intent. Null when the car exposes no pedal PID or for trips
  /// persisted before #2459. Drives the Throttle/Pedal chart together
  /// with [throttlePercent] (pedal preferred when present).
  final double? pedalPercent;

  /// Commanded equivalence ratio / λ (PID 0x44, #2461). Null when the
  /// car doesn't expose PID 0x44 or for legacy trips. Drives the
  /// optional λ chart and the λ-enrichment eco-insight.
  final double? lambda;

  /// GPS altitude in metres (#2461 / #1935). Null when GPS path was
  /// off, before the first fix, or for legacy trips. Drives the
  /// optional altitude chart.
  final double? altitudeM;

  /// Short-term fuel trim bank 1 in percent (PID 0x06, #2931). Null on
  /// cars that don't expose the PID, for legacy trips, and on trips
  /// recorded without diagnostic capture (the trim is read for the
  /// fuel-rate correction but only persisted onto samples under the
  /// diagnostic-capture flag). Carried through so the combustion-health
  /// heuristic (`CombustionHealthRule`) can read the sustained mixture
  /// trim when it IS present.
  final double? stft;

  /// Long-term fuel trim bank 1 in percent (PID 0x07, #2931). Same
  /// null-semantics as [stft]; the two are read together by the
  /// combustion-health heuristic (total trim = STFT + LTFT).
  final double? ltft;

  // ---- #3692 — turbo/thermal signals, read through [origin] ---------
  // The lossless origin round-trip (#3594) means new always-persisted
  // TripSample signals need no converter plumbing (read via [domain]):
  // null for hand-built instances and legacy trips → charts self-hide.

  /// Intake air temperature °C (PID 0x0F, #3692).
  double? get iatC => domain?.iatC;

  /// Ignition timing advance °CA (PID 0x0E, #3692).
  double? get timingAdvanceDeg => domain?.timingAdvanceDeg;

  /// Boost = MAP − ambient baro in kPa (#3692) — positive under boost,
  /// negative at vacuum. Null unless BOTH pressures were recorded.
  double? get boostKpa {
    final map = domain?.mapKpa;
    final baro = domain?.baroKpa;
    if (map == null || baro == null) return null;
    return map - baro;
  }

  /// Reported horizontal GPS accuracy in metres (#2963). Carried through
  /// from `TripSample.hAccuracyM` so the canonical accel-event gate's
  /// bad-fix guard (`countAccelEvents`, kAccelEventAccuracyGateM) can fire
  /// on the saved-trip score path. Both converters used to drop it, so the
  /// gate — which treats a null accuracy as "accept" — never rejected a
  /// jittery GPS-derived accel sample once a trip was persisted and
  /// reopened. Null on legacy trips, on non-GPS trips, and before the first
  /// fix (same semantics as [latitude]).
  final double? hAccuracyM;

  /// The originating domain [TripSample] when this instance was produced
  /// by `toDetailSample` (#3594). The reverse converter returns it
  /// VERBATIM, making the persisted-trip round-trip lossless by
  /// construction — no more field-by-field carrying (this pair dropped
  /// fields five separate times: #2460, #2790, #2931, #2963, #3594).
  /// Null only for hand-built instances (tests); those fall back to the
  /// explicit field copy in `tripDetailToTripSample`.
  final TripSample? domain;

  const TripDetailSample({
    required this.timestamp,
    required this.speedKmh,
    this.rpm,
    this.fuelRateLPerHour,
    this.estimatedFuelRateLPerHour,
    this.throttlePercent,
    this.engineLoadPercent,
    this.coolantTempC,
    this.latitude,
    this.longitude,
    this.pedalPercent,
    this.lambda,
    this.altitudeM,
    this.stft,
    this.ltft,
    this.hAccuracyM,
    this.domain,
  });
}
