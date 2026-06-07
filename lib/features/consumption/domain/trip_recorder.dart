// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../data/obd2/trip_distance_source.dart'
    show kDistanceSourceGps, kDistanceSourceVirtual;
import 'harsh_event_detector.dart';
import 'services/trip_consumption_reliability.dart';
import 'trip_sample.dart';
import 'trip_summary.dart';

// TripSummary (#1927) and TripSample (#2459) live in their own files to
// keep this one under the 400-line guard, but are re-exported so
// importers of `trip_recorder.dart` still see them as one unit.
export 'trip_sample.dart';
export 'trip_summary.dart';

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
  // #2835 — fuel-integration cadence bookkeeping. A sparse-sampled trip
  // (e.g. 58.8 km / 126 samples ≈ 1/min in the field backup) integrates
  // fuel across intervals too wide to assume a constant rate, collapsing
  // the litres toward zero and reporting ~0 L/100 km. We track how many
  // intervals actually contributed litres and their summed Δt so
  // [buildSummary] can mark the figure unavailable rather than report
  // the near-zero artefact (see [isTripConsumptionReliable]).
  int _fuelIntervalCount = 0;
  double _fuelIntegratedSeconds = 0;
  // #2692 C4-E — last non-null fuel-rate reading, carried forward across a
  // single transient null PID. The pre-fix "both endpoints non-null" gate
  // zeroed the whole interval on any single null read (~11 % of intervals
  // in the 77-trip backup), under-counting consumption. The existing
  // `maxIntegrationGapSeconds` skip still bounds how far it carries.
  double? _lastKnownFuelRate;
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
    void Function(HarshEvent event)? onHarshEvent,
  }) : _harshDetector = HarshEventDetector(
          brakeThresholdMps2: harshBrakeThresholdMps2,
          accelThresholdMps2: harshAccelThresholdMps2,
          onEvent: onHarshEvent,
        );

  /// Feed one sample. Safe to call with arbitrary cadence; the
  /// recorder derives Δt internally.
  ///
  /// [distanceSource] is the trip's live distance provenance
  /// (`kDistanceSourceReal` / `kDistanceSourceGps` /
  /// `kDistanceSourceVirtual`, #2653). Harsh scoring is suppressed for
  /// the sample when its speed signal is unfit for differentiation:
  ///
  ///   * `kDistanceSourceVirtual` (dead-reckoning odometer, #2653) — a
  ///     1 km/h-quantised integrated speed produces median 4.78 / peak
  ///     43.4 phantom events/km in the field backup.
  ///   * `kDistanceSourceGps` (#2895 / #3029) — GPS Doppler ground speed
  ///     is ~1 Hz, noisy, and differentiating it manufactures impossible
  ///     >1 g spikes (the #2895 Peugeot 107: a live IMU counted 0 harsh
  ///     while the GPS derivative counted 16, maxAccelG 1.086). #2895 made
  ///     a live IMU *veto* that over-count, but a GPS-sourced trip with no
  ///     IMU (no inertial hardware / OBD2-from-the-start, no speed PID) had
  ///     nothing to veto it, so the clamped-GPS count still drove the
  ///     score — a hard-accel/brake penalty with no visible source
  ///     (#3029). GPS-derived speed is therefore unfit for harsh
  ///     differentiation full stop: harsh events may come ONLY from a
  ///     trustworthy source — a live IMU, or a real OBD2 speed PID.
  ///
  /// `kDistanceSourceReal` (direct OBD2 speed PID) and `null` (legacy /
  /// test call sites and the canonical OBD speed path) leave harsh scoring
  /// ENABLED — those speed signals are direct, not derived.
  void onSample(TripSample sample, {String? distanceSource}) {
    _startedAt ??= sample.timestamp;
    _endedAt = sample.timestamp;
    // #2692 C4-G — GPS-only samples carry rpm null (no engine signal); treat
    // as 0 so they neither raise maxRpm nor count high-RPM / idle time.
    _maxRpm = math.max(_maxRpm, sample.rpm ?? 0);

    // Harsh brake / accel — delegated to the detector, which
    // re-samples speed at ~1 Hz so the 250 ms emit cadence cannot
    // inflate the count (#1922), then de-noises with a sustained-window
    // + accuracy + min-speed + source-aware gate (#2653). Fed every
    // sample, including the first, so its anchor is seeded from trip
    // start. On any DERIVED-speed source (the `virtual` dead-reckoning
    // odometer, #2653; and `gps` Doppler ground speed, #2895 / #3029) the
    // detector suppresses scoring entirely — both manufacture phantom
    // events the score has no trustworthy way to distinguish from real
    // manoeuvres. Direct speed (`real` OBD2 PID, or null legacy/OBD path)
    // stays scored.
    _harshDetector.onSample(
      sample.speedKmh,
      sample.timestamp,
      hAccuracyM: sample.hAccuracyM,
      suppress: distanceSource == kDistanceSourceVirtual ||
          distanceSource == kDistanceSourceGps,
    );

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
      // #2692 C4-E — seed the carry-forward latch from the first sample so a
      // transient null on the very next sample still resolves a rate.
      _lastKnownFuelRate = sample.fuelRateLPerHour ?? _lastKnownFuelRate;
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
    // metric monotone). #2692 C4-G — GPS-only rpm null reads as 0.
    final prevRpm = previous.rpm ?? 0;
    if (prevRpm >= highRpmThreshold) {
      _highRpmSeconds += dt;
    }

    // Idle time: engine on, car stationary for the whole interval.
    if (previous.speedKmh <= 0.5 && prevRpm > 0) {
      _idleSeconds += dt;
    }

    // Fuel: integrate fuel rate across the interval. #2692 C4-E — resolve
    // each endpoint to its own reading or, failing that, the last non-null
    // rate carried forward (a single transient null PID no longer zeroes the
    // interval). Both ends must resolve before we integrate; the
    // `maxIntegrationGapSeconds` skip above bounds how far a stale rate rides.
    final pRate = previous.fuelRateLPerHour ?? _lastKnownFuelRate;
    final cRate = sample.fuelRateLPerHour ?? _lastKnownFuelRate;
    if (pRate != null && cRate != null) {
      final avgRate = (pRate + cRate) / 2.0;
      _fuelLiters += avgRate * dt / 3600.0;
      _hadFuelRate = true;
      // #2835 — cadence bookkeeping for the sparse-sample reliability gate.
      _fuelIntervalCount++;
      _fuelIntegratedSeconds += dt;
    }
    _lastKnownFuelRate = sample.fuelRateLPerHour ?? _lastKnownFuelRate;

    _previous = sample;
  }

  /// Build a [TripSummary] snapshot from the samples fed so far. Safe
  /// to call at any time — the recorder keeps accumulating.
  TripSummary buildSummary() {
    // #2835 — two independent reliability gates, applied separately so
    // each failure mode is handled honestly:
    //
    //  * Sparse cadence (failure mode 2): fuel integrated across a mean
    //    interval too wide to trust (the field backup's ~1/min sampling
    //    collapsed the integral toward 0 L). When this fails the LITRES
    //    are themselves untrustworthy, so BOTH fuelLitersConsumed and
    //    avgLPer100Km are nulled — never a fabricated zero.
    //
    //  * Tiny distance (failure mode 1): a sub-km denominator amplifies
    //    one warm-up burst into an absurd ratio (0.4 km → 306 L/100 km).
    //    The litres are still a real measured quantity, so we keep
    //    fuelLitersConsumed but suppress only avgLPer100Km — the figure
    //    that blows up and would poison the rolling average.
    final fuelCadenceReliable = _hadFuelRate &&
        isFuelCadenceReliable(
          fuelIntervalCount: _fuelIntervalCount,
          fuelIntegratedSeconds: _fuelIntegratedSeconds,
        );
    double? avgLPer100Km;
    if (fuelCadenceReliable && isDistanceReliableForRatio(_distanceKm)) {
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
      // #2835 — null the litres only on the sparse-cadence failure (the
      // integral itself is untrustworthy). A tiny-distance trip keeps its
      // real measured litres; only its blow-up-prone avgLPer100Km above
      // was suppressed.
      fuelLitersConsumed: fuelCadenceReliable ? _fuelLiters : null,
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
    _fuelIntervalCount = 0;
    _fuelIntegratedSeconds = 0;
    _lastKnownFuelRate = null;
    _startedAt = null;
    _endedAt = null;
    _minCoolantTempC = null;
    _maxCoolantTempC = null;
    _coolantSampleCount = 0;
    _firstCoolantWarmAt = null;
  }
}
