// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'harsh_event_detector.dart';
import 'trip_summary.dart';

// TripSummary lives in its own file (#1927 — keeps this file under the
// 400-line guard) but is re-exported so importers of `trip_recorder.dart`
// still see it as one unit.
export 'trip_summary.dart';

/// One OBD2 sample tick — captured by the polling loop and fed into
/// [TripRecorder] for metric accumulation.
class TripSample {
  final DateTime timestamp;
  final double speedKmh;
  final double rpm;
  final double? fuelRateLPerHour;

  /// GPS-physics **estimated** fuel rate in L/h (#2431). Populated ONLY
  /// for OBD2/hybrid trips whose adapter+ECU supported none of the fuel
  /// PIDs (PID 5E / MAF 0110 / speed-density MAP 010B), so
  /// [fuelRateLPerHour] is null on every sample. It is the per-sample
  /// distribution of the trip's GPS-physics L/100 km estimate over the
  /// sample's speed (`L/100 km / 100 × speedKmh`), letting the
  /// trip-detail fuel-rate chart render a clearly-marked *estimated*
  /// series instead of "Keine Messwerte". Deliberately a SEPARATE field
  /// from [fuelRateLPerHour] so a measured value and an estimate are
  /// never confused — when a real fuel PID was seen this stays null and
  /// the chart shows the measured series. Null for legacy trips, for
  /// trips that DID get a real fuel signal, and at a standstill (no
  /// per-distance figure is meaningful at v ≈ 0).
  final double? estimatedFuelRateLPerHour;

  /// Throttle position in percent (PID 0x11), if available. Cars
  /// without PID 11 report null — the trip-detail throttle / RPM
  /// histogram falls back to the RPM axis only in that case (#1261).
  final double? throttlePercent;

  /// Calculated engine load in percent (PID 0x04). Null when the car
  /// doesn't surface the PID. Persisted so post-trip insights can
  /// distinguish "uphill at 60 km/h" (high load) from "flat at 60 km/h"
  /// (low load) instead of inferring from RPM alone (#1262).
  final double? engineLoadPercent;

  /// Engine coolant temperature in °C (PID 0x05). Null when the car
  /// doesn't surface the PID. Persisted so the cold-start surcharge
  /// heuristic (#1262 phase 2) can flag trips whose ECT never reached
  /// operating temperature — those burn proportionally more fuel for
  /// warm-up.
  final double? coolantTempC;

  /// GPS latitude in degrees (#1374 phase 1). Null when the
  /// `Feature.gpsTripPath` flag is disabled (default), when no fix has
  /// landed yet (cold-start indoors), or when the user revoked the
  /// location permission. Persisted so a future map overlay (Phase 2)
  /// and a per-segment heatmap (Phase 3) can render the recorded
  /// trip's path. Legacy samples from trips recorded before this PR
  /// deserialise with `latitude: null`.
  final double? latitude;

  /// GPS longitude in degrees (#1374 phase 1). Same null-semantics as
  /// [latitude]; the two fields are always written and read together
  /// — a half-set fix is meaningless on a map.
  final double? longitude;

  /// GPS altitude in metres (#1935 child A — epic #1935). Same
  /// null-semantics as [latitude]/[longitude]: null when the
  /// `Feature.gpsTripPath` flag is off, before the first fix, or when
  /// the platform reports no altitude. Captured so the road-grade
  /// calculator (#1941) can derive the trip's slope.
  final double? altitudeM;

  /// Reported horizontal accuracy of the GPS fix in metres (#2019).
  /// Lets downstream filters reject jittery fixes from urban-canyon
  /// readings before they feed the speed-derivative accel pipeline
  /// (#2022) or the post-trip map polyline. Null with the same
  /// semantics as [latitude] — no fix means no accuracy.
  final double? hAccuracyM;

  /// Bearing in degrees from true north (#2019). Populated when the
  /// platform supplies it; null otherwise. The trip-detail map can
  /// render directional arrowheads off this, and the gear-inference
  /// heuristic (#2023) uses bearing-stability to gate "is this
  /// straight-line cruise" decisions.
  final double? bearingDeg;

  /// Acceleration magnitude in g (#2019). Populated by the
  /// speed-derivative low-pass pipeline (#2022) when no real
  /// accelerometer feed is wired up; future hardware integrations may
  /// overwrite this from raw sensor data. Null on legacy samples and
  /// when the speed series is too short to differentiate.
  final double? accelG;

  const TripSample({
    required this.timestamp,
    required this.speedKmh,
    required this.rpm,
    this.fuelRateLPerHour,
    this.estimatedFuelRateLPerHour,
    this.throttlePercent,
    this.engineLoadPercent,
    this.coolantTempC,
    this.latitude,
    this.longitude,
    this.altitudeM,
    this.hAccuracyM,
    this.bearingDeg,
    this.accelG,
  });

  /// Return a copy with [estimatedFuelRateLPerHour] replaced (#2431).
  /// The OBD2 GPS-estimate fallback uses it to stamp the per-sample
  /// estimated fuel-rate series onto an already-captured sample without
  /// disturbing its measured speed / RPM / GPS fields. Only the one
  /// field is overridable because that is the sole post-capture mutation
  /// the fallback performs.
  TripSample copyWithEstimatedFuelRate(double? estimatedFuelRateLPerHour) =>
      TripSample(
        timestamp: timestamp,
        speedKmh: speedKmh,
        rpm: rpm,
        fuelRateLPerHour: fuelRateLPerHour,
        estimatedFuelRateLPerHour: estimatedFuelRateLPerHour,
        throttlePercent: throttlePercent,
        engineLoadPercent: engineLoadPercent,
        coolantTempC: coolantTempC,
        latitude: latitude,
        longitude: longitude,
        altitudeM: altitudeM,
        hAccuracyM: hAccuracyM,
        bearingDeg: bearingDeg,
        accelG: accelG,
      );
}

/// Pure-logic accumulator that turns a stream of OBD2 [TripSample]s
/// into a [TripSummary]. The Bluetooth polling loop feeds samples in
/// via [onSample] at whatever cadence it can sustain (~1-2 Hz); the
/// recorder is cadence-agnostic — every metric is integrated over
/// Δt between consecutive samples, not over sample count.
///
/// Thresholds are configurable at construction; defaults match common
/// telematics cutoffs so the derived "aggressive driving" signal maps
/// to something a typical user would recognise.
class TripRecorder {
  /// RPM value above which the recorder clocks "high-RPM" time.
  final double highRpmThreshold;

  /// Maximum Δt (seconds) between two samples that is still integrated
  /// (#1927). A gap longer than this is a connection dropout or a
  /// pause, not a measurement interval — integrating `avgSpeed × dt`
  /// or `avgFuelRate × dt` across it fabricates distance and fuel.
  /// Intervals beyond this gap are skipped entirely. Defaults to
  /// [double.infinity] (no cap); the trip-recording path opts into a
  /// finite value.
  final double maxIntegrationGapSeconds;

  /// Detects harsh braking / acceleration from the speed stream. Kept
  /// in its own class (#1922) so the speed derivative is re-sampled at
  /// ~1 Hz — feeding it the raw 250 ms emit cadence used to inflate
  /// the count ~4x.
  final HarshEventDetector _harshDetector;

  TripSample? _previous;
  double _distanceKm = 0;
  double _maxRpm = 0;
  double _highRpmSeconds = 0;
  double _idleSeconds = 0;
  double _fuelLiters = 0;
  bool _hadFuelRate = false;
  DateTime? _startedAt;
  DateTime? _endedAt;

  // Cold-start surcharge accumulators (#1262 phase 2). Coolant temp
  // is per-sample (PID 0x05); the recorder tracks the lifetime
  // min / max plus the first warm-up timestamp so [buildSummary] can
  // evaluate three cold-start patterns in one pass.
  double? _minCoolantTempC;
  double? _maxCoolantTempC;
  int _coolantSampleCount = 0;
  DateTime? _firstCoolantWarmAt;

  /// Coolant temperature (°C) at which the engine is considered to
  /// have reached operating range. 70 °C matches the canonical
  /// thermostat-open threshold for typical petrol engines and is the
  /// value the issue body cites for the cold-start heuristic.
  static const double _coolantWarmThresholdC = 70.0;

  TripRecorder({
    this.highRpmThreshold = 3500,
    this.maxIntegrationGapSeconds = double.infinity,
    double harshBrakeThresholdMps2 = 3.5,
    double harshAccelThresholdMps2 = 3.0,
  }) : _harshDetector = HarshEventDetector(
          brakeThresholdMps2: harshBrakeThresholdMps2,
          accelThresholdMps2: harshAccelThresholdMps2,
        );

  /// Feed one sample. Safe to call with arbitrary cadence; the
  /// recorder derives Δt internally.
  void onSample(TripSample sample) {
    _startedAt ??= sample.timestamp;
    _endedAt = sample.timestamp;
    _maxRpm = math.max(_maxRpm, sample.rpm);

    // Harsh brake / accel — delegated to the detector, which
    // re-samples speed at ~1 Hz so the 250 ms emit cadence cannot
    // inflate the count (#1922). Fed every sample, including the
    // first, so its anchor is seeded from trip start.
    _harshDetector.onSample(sample.speedKmh, sample.timestamp);

    // Track coolant samples for the cold-start surcharge heuristic
    // (#1262 phase 2). Cars without PID 0x05 carry coolantTempC ==
    // null on every sample; the heuristic falls back to "false" in
    // that case so we never accuse a sensor-less car of a cold start.
    final coolant = sample.coolantTempC;
    if (coolant != null) {
      _coolantSampleCount++;
      final currentMin = _minCoolantTempC;
      _minCoolantTempC =
          currentMin == null ? coolant : math.min(currentMin, coolant);
      final currentMax = _maxCoolantTempC;
      _maxCoolantTempC =
          currentMax == null ? coolant : math.max(currentMax, coolant);
      if (_firstCoolantWarmAt == null && coolant >= _coolantWarmThresholdC) {
        _firstCoolantWarmAt = sample.timestamp;
      }
    }

    final previous = _previous;
    if (previous == null) {
      _previous = sample;
      return;
    }
    final dt = sample.timestamp.difference(previous.timestamp).inMicroseconds
        / Duration.microsecondsPerSecond;
    if (dt <= 0) {
      // Out-of-order or duplicate timestamp — skip.
      _previous = sample;
      return;
    }
    if (dt > maxIntegrationGapSeconds) {
      // #1927 — a gap far longer than the poll cadence is a connection
      // dropout or a pause, not a measurement interval. Integrating
      // distance / fuel / idle / high-RPM time across it would
      // fabricate a chunk of metric (a 20-minute hole added ~10 km of
      // phantom distance in a real backup). Skip every dt-based
      // accumulator; the trip honestly under-counts the lost stretch.
      // `_previous` still advances so the next interval integrates.
      _previous = sample;
      return;
    }

    // Distance: integrate average speed across the interval.
    final avgSpeedKmh = (previous.speedKmh + sample.speedKmh) / 2.0;
    _distanceKm += avgSpeedKmh * dt / 3600.0;

    // High-RPM time: count the whole interval when the START sample is
    // above threshold (the polling cadence is short relative to typical
    // gear shifts, so this is a reasonable approximation and keeps the
    // metric monotone).
    if (previous.rpm >= highRpmThreshold) {
      _highRpmSeconds += dt;
    }

    // Idle time: engine on, car stationary for the whole interval.
    if (previous.speedKmh <= 0.5 && previous.rpm > 0) {
      _idleSeconds += dt;
    }

    // Fuel: integrate fuel rate across the interval. Only counts when
    // BOTH endpoints carry a fuel-rate reading (average the two).
    if (previous.fuelRateLPerHour != null && sample.fuelRateLPerHour != null) {
      final avgRate =
          (previous.fuelRateLPerHour! + sample.fuelRateLPerHour!) / 2.0;
      _fuelLiters += avgRate * dt / 3600.0;
      _hadFuelRate = true;
    }

    _previous = sample;
  }

  /// Build a [TripSummary] snapshot from the samples fed so far. Safe
  /// to call at any time — the recorder keeps accumulating.
  TripSummary buildSummary() {
    double? avgLPer100Km;
    if (_hadFuelRate && _distanceKm > 0.001) {
      avgLPer100Km = _fuelLiters / _distanceKm * 100.0;
    }

    // Cold-start surcharge heuristic (#1262 phase 2). Three rules
    // flip the same bit; we OR them so any pattern triggers the
    // chip. Skipped entirely when no coolant sample was ever read —
    // a car without PID 0x05 must NOT be flagged as "cold-started"
    // every trip; the false-positive rate would make the chip
    // useless.
    var coldStartSurcharge = false;
    if (_coolantSampleCount > 0 && _startedAt != null && _endedAt != null) {
      final durationSec =
          _endedAt!.difference(_startedAt!).inMicroseconds / 1e6;
      final minC = _minCoolantTempC ?? 0.0;
      final maxC = _maxCoolantTempC ?? 0.0;
      // Rule A: trip < 10 min AND coolant minimum below operating
      // temp (the canonical "short cold trip"). Even if it warmed
      // up by the end, a sub-10-minute trip that started cold paid
      // the surcharge.
      final shortColdTrip =
          durationSec < 600 && minC < _coolantWarmThresholdC;
      // Rule B: any duration, but engine never reached operating
      // temp at all. Realistic on very cold ambient + low-load
      // cruising — the engine burns enrichment fuel for the entire
      // trip. The issue body's "(< 10 min) OR (didn't cross in 2nd
      // half)" misses this case.
      final neverWarmed = maxC < _coolantWarmThresholdC;
      // Rule C: coolant didn't cross 70 °C until the second half of
      // the trip. The first half ran rich — the surcharge applies.
      var warmedLate = false;
      final warmAt = _firstCoolantWarmAt;
      if (warmAt != null) {
        final warmOffsetSec =
            warmAt.difference(_startedAt!).inMicroseconds / 1e6;
        warmedLate = durationSec > 0 && warmOffsetSec > durationSec / 2;
      }
      coldStartSurcharge = shortColdTrip || neverWarmed || warmedLate;
    }

    return TripSummary(
      distanceKm: _distanceKm,
      maxRpm: _maxRpm,
      highRpmSeconds: _highRpmSeconds,
      idleSeconds: _idleSeconds,
      harshBrakes: _harshDetector.brakes,
      harshAccelerations: _harshDetector.accelerations,
      avgLPer100Km: avgLPer100Km,
      fuelLitersConsumed: _hadFuelRate ? _fuelLiters : null,
      startedAt: _startedAt,
      endedAt: _endedAt,
      coldStartSurcharge: coldStartSurcharge,
      harshEvents: _harshDetector.events,
    );
  }

  /// Reset the accumulator. Useful before starting a fresh trip
  /// without destroying the recorder instance.
  void reset() {
    _previous = null;
    _distanceKm = 0;
    _maxRpm = 0;
    _highRpmSeconds = 0;
    _idleSeconds = 0;
    _harshDetector.reset();
    _fuelLiters = 0;
    _hadFuelRate = false;
    _startedAt = null;
    _endedAt = null;
    _minCoolantTempC = null;
    _maxCoolantTempC = null;
    _coolantSampleCount = 0;
    _firstCoolantWarmAt = null;
  }
}
