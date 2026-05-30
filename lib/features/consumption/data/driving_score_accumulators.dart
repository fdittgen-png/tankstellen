// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Per-interval accumulator + inline Welford helper for the canonical
/// driving-style score (#2460).
///
/// Split out of `driving_score_calculator.dart` (a `part of` library) to
/// keep that orchestrator under the 400-line guard. Library-private — no
/// public API surface; the shared thresholds, caps, and `_clamp` /
/// `_seconds` / `_pedalOrThrottle` / `_luggingPenalty` helpers live in
/// the main file and resolve here through the shared library scope.
part of 'driving_score_calculator.dart';

/// Mutable per-interval accumulator — kept separate so [computeDrivingScore]
/// stays a thin orchestrator and the file stays under the line guard.
class _Accumulators {
  double idleSeconds = 0;
  double highRpmSeconds = 0;
  double fullThrottleSeconds = 0;
  double coastSeconds = 0;
  double highSpeedSeconds = 0;
  double lambdaEnrichSeconds = 0;
  int hardAccelEvents = 0;
  int hardBrakeEvents = 0;
  int hardShiftSpikes = 0;
  int revWhileStationaryBlips = 0;
  double maxPedalVelocity = 0;

  // Welford accumulators for the CONTINUOUS smoothness term.
  final _speedStats = _Welford();
  final _pedalStats = _Welford();

  double? _prevMovingPedal;
  DateTime? _prevMovingPedalTs;

  void accumulate({
    required TripSample prev,
    required TripSample cur,
    required double dt,
  }) {
    // Idle vs moving accounting (attribute the interval to its start).
    final stationary = prev.speedKmh <= _idleSpeedToleranceKmh;
    final pedal = _pedalOrThrottle(prev);
    if (stationary && prev.rpm > 0) {
      idleSeconds += dt;
      // Rev-while-stationary: blipping the pedal or revving in neutral.
      if ((pedal != null && pedal > _revWhileStationaryPedal) ||
          prev.rpm > _revWhileStationaryRpm) {
        revWhileStationaryBlips++;
      }
    } else if (!stationary) {
      _speedStats.add(prev.speedKmh);
      if (pedal != null) _pedalStats.add(pedal);
    }

    if (prev.rpm > kHighRpmThreshold) highRpmSeconds += dt;

    // Full-throttle time-share — NOW FIRES (#2460).
    if (pedal != null && pedal >= kFullThrottlePercent) {
      fullThrottleSeconds += dt;
    }

    // Pedal-velocity: max d(pedal)/dt over MOVING samples.
    if (!stationary && pedal != null) {
      final prevPedal = _prevMovingPedal;
      final prevTs = _prevMovingPedalTs;
      if (prevPedal != null && prevTs != null) {
        final pdt = _seconds(prevTs, prev.timestamp);
        if (pdt > 0) {
          final v = (pedal - prevPedal).abs() / pdt;
          if (v > maxPedalVelocity) maxPedalVelocity = v;
        }
      }
      _prevMovingPedal = pedal;
      _prevMovingPedalTs = prev.timestamp;
    }

    // Hard-shift: a big RPM spike within one interval (a sustained climb
    // is high-RPM time, not a shift spike).
    if (cur.rpm - prev.rpm >= _hardShiftRpmSpike) hardShiftSpikes++;

    // Hard accel / brake from the speed derivative.
    final accelMps2 = (cur.speedKmh - prev.speedKmh) / 3.6 / dt;
    if (accelMps2 >= kHardAccelThresholdMps2) {
      hardAccelEvents++;
    } else if (accelMps2 <= -kHardBrakeThresholdMps2) {
      hardBrakeEvents++;
    }

    // Speed efficiency: high-speed band.
    if (prev.speedKmh >= kHighSpeedThresholdKmh) highSpeedSeconds += dt;

    // λ-enrichment: commanded mixture richer than stoichiometric.
    final lambda = prev.lambda;
    if (lambda != null && lambda > 0 && lambda < 1.0) {
      lambdaEnrichSeconds += dt;
    }

    // Eco-credit: fuel-cut coasting (detected, now credited).
    final fuelRate = prev.fuelRateLPerHour;
    if (fuelRate != null &&
        fuelRate < _coastFuelRateLPerHour &&
        prev.speedKmh > _coastMinSpeedKmh) {
      coastSeconds += dt;
    }
  }

  DrivingScore build({
    required double totalDt,
    required double? secondsBelowOptimalGear,
  }) {
    final idlingPenalty =
        _clamp(idleSeconds / totalDt * _idlingCap, 0, _idlingCap);
    final highRpmPenalty =
        _clamp(highRpmSeconds / totalDt * _highRpmCap, 0, _highRpmCap);
    final hardAccelPenalty =
        _clamp(hardAccelEvents * _hardAccelPerEvent, 0, _hardAccelCap);
    final hardBrakePenalty =
        _clamp(hardBrakeEvents * _hardBrakePerEvent, 0, _hardBrakeCap);
    final fullThrottlePenalty = _clamp(
      fullThrottleSeconds / totalDt * _fullThrottleCap,
      0,
      _fullThrottleCap,
    );
    final pedalVelocityPenalty = _clamp(
      maxPedalVelocity / _pedalVelocitySaturation * _pedalVelocityCap,
      0,
      _pedalVelocityCap,
    );
    final luggingPenalty = _luggingPenalty(secondsBelowOptimalGear, totalDt);
    final hardShiftPenalty =
        _clamp(hardShiftSpikes * _hardShiftPerSpike, 0, _hardShiftCap);
    final revWhileStationaryPenalty = _clamp(
      revWhileStationaryBlips * _revWhileStationaryPerBlip,
      0,
      _revWhileStationaryCap,
    );
    final smoothnessPenalty = _smoothnessPenalty();
    final speedEfficiencyPenalty = _clamp(
      highSpeedSeconds / totalDt * _speedEfficiencyCap,
      0,
      _speedEfficiencyCap,
    );
    final lambdaEnrichmentPenalty = _clamp(
      lambdaEnrichSeconds / totalDt * _lambdaEnrichmentCap,
      0,
      _lambdaEnrichmentCap,
    );
    final ecoCreditCoast =
        _clamp(coastSeconds / totalDt * _ecoCreditCap, 0, _ecoCreditCap);

    final raw = 100.0 -
        idlingPenalty -
        highRpmPenalty -
        hardAccelPenalty -
        hardBrakePenalty -
        fullThrottlePenalty -
        pedalVelocityPenalty -
        luggingPenalty -
        hardShiftPenalty -
        revWhileStationaryPenalty -
        smoothnessPenalty -
        speedEfficiencyPenalty -
        lambdaEnrichmentPenalty +
        ecoCreditCoast;

    return DrivingScore(
      score: _clamp(raw, 0, 100).round(),
      idlingPenalty: idlingPenalty,
      hardAccelPenalty: hardAccelPenalty,
      hardBrakePenalty: hardBrakePenalty,
      highRpmPenalty: highRpmPenalty,
      fullThrottlePenalty: fullThrottlePenalty,
      pedalVelocityPenalty: pedalVelocityPenalty,
      luggingPenalty: luggingPenalty,
      hardShiftPenalty: hardShiftPenalty,
      revWhileStationaryPenalty: revWhileStationaryPenalty,
      smoothnessPenalty: smoothnessPenalty,
      speedEfficiencyPenalty: speedEfficiencyPenalty,
      lambdaEnrichmentPenalty: lambdaEnrichmentPenalty,
      ecoCreditCoast: ecoCreditCoast,
    );
  }

  /// CONTINUOUS smoothness: blend the normalised speed std-dev with the
  /// normalised pedal/throttle variance. Either term alone can drive the
  /// penalty; together they saturate the cap. Replaces the old binary
  /// gate (#2460).
  double _smoothnessPenalty() {
    final speedTerm = _speedStats.count >= 2
        ? _clamp(_speedStats.stddev / _smoothnessSpeedStdDevSaturation, 0, 1)
        : 0.0;
    final pedalTerm = _pedalStats.count >= 2
        ? _clamp(_pedalStats.variance / _smoothnessPedalVarSaturation, 0, 1)
        : 0.0;
    // Weight speed std-dev 0.6, pedal variance 0.4 — speed is always
    // present, pedal is optional.
    final blended =
        pedalTerm > 0 ? 0.6 * speedTerm + 0.4 * pedalTerm : speedTerm;
    return _clamp(blended * _smoothnessCap, 0, _smoothnessCap);
  }
}

/// Tiny inline Welford accumulator for the smoothness term — avoids a
/// second pass and stays numerically stable. (The standalone
/// `welford.dart` is JSON-serialisable for baselines; here we only need
/// the in-pass mean/variance.)
class _Welford {
  int count = 0;
  double _mean = 0;
  double _m2 = 0;

  void add(double x) {
    count++;
    final delta = x - _mean;
    _mean += delta / count;
    _m2 += delta * (x - _mean);
  }

  double get variance => count < 2 ? 0 : _m2 / (count - 1);
  double get stddev => math.sqrt(variance);
}
