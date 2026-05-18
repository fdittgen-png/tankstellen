import 'dart:math' as math;

import 'harsh_event_detector.dart';

/// One OBD2 sample tick — captured by the polling loop and fed into
/// [TripRecorder] for metric accumulation.
class TripSample {
  final DateTime timestamp;
  final double speedKmh;
  final double rpm;
  final double? fuelRateLPerHour;

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

  const TripSample({
    required this.timestamp,
    required this.speedKmh,
    required this.rpm,
    this.fuelRateLPerHour,
    this.throttlePercent,
    this.engineLoadPercent,
    this.coolantTempC,
    this.latitude,
    this.longitude,
  });
}

/// Aggregated metrics for a single driving trip (#718).
class TripSummary {
  final double distanceKm;
  final double maxRpm;
  final double highRpmSeconds;
  final double idleSeconds;
  final int harshBrakes;
  final int harshAccelerations;
  /// Average fuel consumption in L/100 km. Null when the trip carried
  /// no fuel-rate samples (cars without PID 5E / MAF).
  final double? avgLPer100Km;
  /// Estimated fuel burned during the trip, in litres. Null when the
  /// trip carried no fuel-rate samples. This is what the "save as
  /// fill-up" flow pre-fills into the liters field (#726).
  final double? fuelLitersConsumed;
  final DateTime? startedAt;
  final DateTime? endedAt;

  /// Provenance flag for [distanceKm] (#800). Either `'real'` — the
  /// value came from the car's odometer (`odometerLatest -
  /// odometerStart`) — or `'virtual'` — the value is the trapezoidal
  /// integration of speed samples from [VirtualOdometer]. UI /
  /// analytics use this to decide whether to trust the km figure as a
  /// ground truth (fuel-reconciliation denominator) or flag it as an
  /// estimate. Defaults to `'virtual'` because the recorder
  /// integrates speed even when an odometer is available — legacy
  /// trips before this flag landed keep that honest label.
  final String distanceSource;

  /// Whether this trip likely paid a cold-start fuel surcharge
  /// (#1262 phase 2). Flipped true when the coolant temperature
  /// telemetry suggests the engine was warming up for a meaningful
  /// portion of the trip — short trips that never reached operating
  /// temperature, trips where the coolant max stayed below 70 °C, or
  /// trips that only crossed 70 °C in the second half. Cars without
  /// PID 0x05 produce no coolant samples, so the flag stays false to
  /// avoid false positives on absent data. UI surfaces (Phase 3)
  /// render a chip on the trip card based on this bit.
  final bool coldStartSurcharge;

  /// Seconds during the trip the engine was in a lower gear than
  /// optimal — heuristic: in-gear-N when N+1 would let RPM drop below
  /// `optimalRpmCeiling` (≈ 2200 RPM). Computed from
  /// `gear_inference.dart` outputs at trip end. Null = no inference
  /// (no centroids, EV, insufficient samples).
  final double? secondsBelowOptimalGear;

  /// Whether the fuel-rate samples that produced [fuelLitersConsumed]
  /// / [avgLPer100Km] tripped the cross-check sanity bounds at a
  /// meaningful rate during the trip (#1395). Set true at trip end
  /// when the breadcrumb collector reports
  /// `suspiciousSampleCount / totalSampleCount > 0.3` — i.e. more
  /// than 30 % of samples were either implausibly low (RPM > 1500
  /// AND L/h < 0.3) or showed > 50 % divergence between PID 5E and
  /// the MAF-derived rate. Stays false when no samples or no flagged
  /// samples were recorded; UI surfaces (#1395 phase 4) render a chip
  /// on the trip summary card based on this bit.
  final bool fuelRateSuspect;

  /// Fuel-weighted mean volumetric efficiency (η_v) the trip's fuel was
  /// integrated with (#1858), or null when the trip is **not**
  /// η_v-recalculable.
  ///
  /// Speed-density fuel scales linearly with η_v, so a stored trip can
  /// be retroactively recomputed for a corrected η_v by
  /// `fuelLitersConsumed × (newVe / volumetricEfficiencyUsed)` — but
  /// only when *every* litre was speed-density-derived. This field is
  /// non-null exactly then: it carries the fuel-weighted mean of the
  /// per-tick η_v actually applied. It is null when any fuel came from
  /// PID 5E or the MAF branch (neither uses η_v — rescaling would
  /// corrupt that portion), when the trip burned no fuel, and for
  /// legacy trips recorded before #1858. A null value means "not
  /// recalculable" and such trips are left untouched by a recompute.
  final double? volumetricEfficiencyUsed;

  const TripSummary({
    required this.distanceKm,
    required this.maxRpm,
    required this.highRpmSeconds,
    required this.idleSeconds,
    required this.harshBrakes,
    required this.harshAccelerations,
    this.avgLPer100Km,
    this.fuelLitersConsumed,
    this.startedAt,
    this.endedAt,
    this.distanceSource = 'virtual',
    this.coldStartSurcharge = false,
    this.secondsBelowOptimalGear,
    this.fuelRateSuspect = false,
    this.volumetricEfficiencyUsed,
  });

  /// Returns a copy with the given fields replaced (#1858). Used by the
  /// retroactive η_v recompute to rescale `fuelLitersConsumed` /
  /// `avgLPer100Km` and re-stamp `volumetricEfficiencyUsed`. A passed
  /// null keeps the existing value — the recompute never needs to
  /// *clear* a field, so the simple form is sufficient.
  TripSummary copyWith({
    double? distanceKm,
    double? maxRpm,
    double? highRpmSeconds,
    double? idleSeconds,
    int? harshBrakes,
    int? harshAccelerations,
    double? avgLPer100Km,
    double? fuelLitersConsumed,
    DateTime? startedAt,
    DateTime? endedAt,
    String? distanceSource,
    bool? coldStartSurcharge,
    double? secondsBelowOptimalGear,
    bool? fuelRateSuspect,
    double? volumetricEfficiencyUsed,
  }) =>
      TripSummary(
        distanceKm: distanceKm ?? this.distanceKm,
        maxRpm: maxRpm ?? this.maxRpm,
        highRpmSeconds: highRpmSeconds ?? this.highRpmSeconds,
        idleSeconds: idleSeconds ?? this.idleSeconds,
        harshBrakes: harshBrakes ?? this.harshBrakes,
        harshAccelerations: harshAccelerations ?? this.harshAccelerations,
        avgLPer100Km: avgLPer100Km ?? this.avgLPer100Km,
        fuelLitersConsumed: fuelLitersConsumed ?? this.fuelLitersConsumed,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        distanceSource: distanceSource ?? this.distanceSource,
        coldStartSurcharge: coldStartSurcharge ?? this.coldStartSurcharge,
        secondsBelowOptimalGear:
            secondsBelowOptimalGear ?? this.secondsBelowOptimalGear,
        fuelRateSuspect: fuelRateSuspect ?? this.fuelRateSuspect,
        volumetricEfficiencyUsed:
            volumetricEfficiencyUsed ?? this.volumetricEfficiencyUsed,
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
