// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../../trips/api.dart';
import '../domain/driving_dimensions.dart';
import 'avoidable_idle.dart';
import 'driving_score_calculator.dart'
    show kFullThrottlePercent, kHighRpmThreshold, kHighSpeedThresholdKmh;

/// Sustained exposure: a run at high speed must last this long to count.
const Duration kSustainedHighSpeed = Duration(seconds: 60);

/// A hard brake that ends in a stop this soon is traffic, not late braking.
const Duration kBrakeToStopWindow = Duration(seconds: 10);

/// Confident grade bands for the hill dimension.
const double kClimbGradeFraction = 0.03;
const double kFlatGradeFraction = 0.01;

double _clamp01(double v) => v.clamp(0.0, 1.0).toDouble();

DimensionConfidence _byEvidence(int n, {int medium = 3, int high = 10}) =>
    n >= high
        ? DimensionConfidence.high
        : n >= medium
            ? DimensionConfidence.medium
            : DimensionConfidence.low;

/// #4205 — the behaviour dimensions of a trip, from its samples and the
/// shared road-load track (#4203). Pure and deterministic: a historical trip
/// replays to the same dimensions. Heuristics v1 — each formula is documented
/// at its dimension and uses only evidence the samples actually carry.
DrivingDimensions computeDrivingDimensions(
  List<TripSample> samples, {
  double? secondsBelowOptimalGear,
  RoadLoadTrack? track,
}) {
  if (samples.length < 2) return const DrivingDimensions({});
  final sorted = [...samples]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final road = track ?? RoadLoadTrack.from(sorted);
  final points = road.points;

  var movingSec = 0.0, distanceKm = 0.0;
  var demandSec = 0.0, fullThrottleSec = 0.0;
  var rpmSec = 0.0, highRpmSec = 0.0;
  var climbSec = 0.0, climbFullSec = 0.0, flatSec = 0.0, flatFullSec = 0.0;
  var fuelRateDecelSec = 0.0, fuelCutSec = 0.0;
  var highRunSec = 0.0, sustainedHighSec = 0.0;
  final cruiseSpeeds = <double>[];
  final idle = AvoidableIdle(fallbackRateLPerHour: 0);
  var engineKnown = false;
  // #4366 — eligible exposure: seconds in which the signal was PRESENT,
  // moving or not. A GPS-only trip accrues none of these, so the
  // measures they denominate come back unavailable rather than zero.
  var engineKnownSec = 0.0, coolantKnownSec = 0.0;
  var avoidableBrakes = 0, judgedCurves = 0, lateCurves = 0;

  for (var i = 1; i < sorted.length && i < points.length; i++) {
    final prev = sorted[i - 1];
    final dt = sorted[i].timestamp.difference(prev.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt <= 0) continue;
    final moving = prev.speedKmh > 1.8;
    if (prev.rpm != null) {
      engineKnown = true;
      engineKnownSec += dt;
    }
    if (prev.coolantTempC != null) coolantKnownSec += dt;
    if (!moving && (prev.rpm ?? 0) > 0) {
      idle.addIdle(dt, prev.fuelRateLPerHour);
    } else {
      idle.endRun();
    }
    if (!moving) continue;
    movingSec += dt;
    distanceKm += prev.speedKmh / 3600 * dt;

    final demand = prev.pedalPercent ?? prev.throttlePercent;
    final full = demand != null && demand >= kFullThrottlePercent;
    if (demand != null) demandSec += dt;
    if (full) fullThrottleSec += dt;

    if (prev.rpm != null) {
      rpmSec += dt;
      if (prev.rpm! > kHighRpmThreshold) highRpmSec += dt;
    }

    final grade = points[i - 1].grade;
    if (grade.confident && demand != null) {
      if (grade.gradeFraction >= kClimbGradeFraction) {
        climbSec += dt;
        if (full) climbFullSec += dt;
      } else if (grade.gradeFraction.abs() <= kFlatGradeFraction) {
        flatSec += dt;
        if (full) flatFullSec += dt;
      }
    }

    final accel = points[i - 1].accelMps2;
    if (accel != null && accel < -0.3 && prev.fuelRateLPerHour != null) {
      fuelRateDecelSec += dt;
      if (prev.fuelRateLPerHour! < 0.1 && prev.speedKmh > 20) fuelCutSec += dt;
    }

    if (prev.speedKmh >= kHighSpeedThresholdKmh) {
      highRunSec += dt;
    } else {
      if (highRunSec >= kSustainedHighSpeed.inSeconds) {
        sustainedHighSec += highRunSec;
      }
      highRunSec = 0;
    }
    if (prev.speedKmh >= 50) cruiseSpeeds.add(prev.speedKmh);
  }
  idle.endRun();
  if (highRunSec >= kSustainedHighSpeed.inSeconds) sustainedHighSec += highRunSec;

  final dims = <DrivingDimensionKind, DrivingDimension>{};
  void put(DrivingDimension d) => dims[d.kind] = d;

  // Acceleration demand: hard pulls per km + full-demand share.
  final accel = countAccelEvents([
    for (final s in sorted)
      AccelSamplePoint(
          timestamp: s.timestamp, speedKmh: s.speedKmh, hAccuracyM: s.hAccuracyM),
  ]);
  if (movingSec <= 0) {
    put(const DrivingDimension.unknown(DrivingDimensionKind.accelerationDemand,
        context: 'no movement'));
  } else {
    final perKm = distanceKm > 0 ? accel.accelEvents / distanceKm : 0.0;
    final fullShare = demandSec > 0 ? fullThrottleSec / demandSec : 0.0;
    put(DrivingDimension(
      kind: DrivingDimensionKind.accelerationDemand,
      value: _clamp01(1 - perKm * 0.5 - fullShare * 2),
      confidence: demandSec > 0
          ? DimensionConfidence.high
          : DimensionConfidence.medium,
      evidenceCount: accel.accelEvents + fullThrottleSec.round(),
      context: demandSec > 0 ? 'pedal/throttle + events' : 'events only',
    ));
  }

  // Braking anticipation: hard brakes that do not end in a stop and fall in
  // an oscillation or a late-brake curve are the avoidable ones.
  final brakes = _hardBrakeMoments(points);
  if (brakes.isEmpty) {
    put(DrivingDimension(
      kind: DrivingDimensionKind.brakingAnticipation,
      value: 1,
      confidence: movingSec >= 300
          ? DimensionConfidence.medium
          : DimensionConfidence.low,
      evidenceCount: 0,
      context: 'no hard braking',
    ));
  } else {
    avoidableBrakes = brakes.where((t) {
      final endsInStop = road.stops.any((s) =>
          !s.start.isBefore(t) && s.start.difference(t) <= kBrakeToStopWindow);
      if (endsInStop) return false;
      final inOscillation = road.oscillations.any(
          (o) => !t.isBefore(o.start) && !t.isAfter(o.end));
      final lateCurve = road.curves.any((c) =>
          c.approach == CurveApproach.lateBrakeHardExit &&
          !t.isAfter(c.end) &&
          c.start.difference(t) <= kCurveLateBrakeWindow);
      return inOscillation || lateCurve;
    }).length;
    put(DrivingDimension(
      kind: DrivingDimensionKind.brakingAnticipation,
      value: _clamp01(1 - avoidableBrakes / brakes.length),
      confidence: _byEvidence(brakes.length),
      evidenceCount: brakes.length,
      context: '$avoidableBrakes of ${brakes.length} avoidable',
    ));
  }

  // Speed stability: sustained high-speed exposure + cruise speed variation.
  if (movingSec < 60) {
    put(const DrivingDimension.unknown(DrivingDimensionKind.speedStability,
        context: 'too little driving'));
  } else {
    final share = sustainedHighSec / movingSec;
    var cv = 0.0;
    if (cruiseSpeeds.length >= 10) {
      final mean = cruiseSpeeds.reduce((a, b) => a + b) / cruiseSpeeds.length;
      final variance = cruiseSpeeds
              .map((v) => (v - mean) * (v - mean))
              .reduce((a, b) => a + b) /
          cruiseSpeeds.length;
      cv = math.sqrt(variance) / mean;
    }
    put(DrivingDimension(
      kind: DrivingDimensionKind.speedStability,
      value: _clamp01(1 - share * 1.5 - cv),
      confidence: movingSec >= 300
          ? DimensionConfidence.high
          : DimensionConfidence.medium,
      evidenceCount: movingSec.round(),
      context: 'sustained>110: ${sustainedHighSec.round()} s',
    ));
  }

  // Avoidable idle: only unbroken long idles, only when the engine is known.
  if (!engineKnown) {
    put(const DrivingDimension.unknown(DrivingDimensionKind.avoidableIdle,
        context: 'engine state unknown (GPS-only)'));
  } else {
    final base = math.max(movingSec, 1.0);
    put(DrivingDimension(
      kind: DrivingDimensionKind.avoidableIdle,
      value: _clamp01(1 - idle.seconds / base * 5),
      confidence: DimensionConfidence.high,
      evidenceCount: idle.seconds.round(),
      context: '${idle.episodes} long idle(s)',
    ));
  }

  // Curve approach: smooth vs late brake + hard exit.
  final judged =
      road.curves.where((c) => c.approach != CurveApproach.unknown).toList();
  if (judged.isEmpty) {
    put(DrivingDimension.unknown(DrivingDimensionKind.curveApproach,
        context: road.curvatureConfidenceShare < 0.5
            ? 'bearing not trustworthy'
            : 'no curves'));
  } else {
    lateCurves = judged
        .where((c) => c.approach == CurveApproach.lateBrakeHardExit)
        .length;
    judgedCurves = judged.length;
    put(DrivingDimension(
      kind: DrivingDimensionKind.curveApproach,
      value: 1 - lateCurves / judgedCurves,
      confidence: _byEvidence(judgedCurves, medium: 2, high: 6),
      evidenceCount: judgedCurves,
      context: '$lateCurves late of $judgedCurves',
    ));
  }

  // Hill behaviour: full demand on climbs BEYOND the driver's own flat-road
  // habit — the climb itself is never the penalty.
  if (climbSec < 60) {
    put(const DrivingDimension.unknown(DrivingDimensionKind.hillBehaviour,
        context: 'no confident climb'));
  } else {
    final climbShare = climbFullSec / climbSec;
    final flatShare = flatSec > 0 ? flatFullSec / flatSec : 0.0;
    put(DrivingDimension(
      kind: DrivingDimensionKind.hillBehaviour,
      value: _clamp01(1 - (climbShare - flatShare) * 3),
      confidence: climbSec >= 180
          ? DimensionConfidence.high
          : DimensionConfidence.medium,
      evidenceCount: climbSec.round(),
      context: 'full demand climbing ${(climbShare * 100).round()} % vs '
          'flat ${(flatShare * 100).round()} %',
    ));
  }

  // Powertrain operation: high RPM + lugging, only with engine data.
  if (rpmSec <= 0) {
    put(const DrivingDimension.unknown(
        DrivingDimensionKind.powertrainOperation,
        context: 'no engine data'));
  } else {
    final lugShare = (secondsBelowOptimalGear ?? 0) / math.max(movingSec, 1.0);
    put(DrivingDimension(
      kind: DrivingDimensionKind.powertrainOperation,
      value: _clamp01(1 - (highRpmSec / rpmSec) * 2 - lugShare),
      confidence: secondsBelowOptimalGear == null
          ? DimensionConfidence.medium
          : DimensionConfidence.high,
      evidenceCount: rpmSec.round(),
      context: 'high RPM ${highRpmSec.round()} s',
    ));
  }

  // Energy oscillation: accelerate → brake → accelerate episodes per 10 km.
  if (distanceKm < 1) {
    put(const DrivingDimension.unknown(DrivingDimensionKind.energyOscillation,
        context: 'too short'));
  } else {
    final per10Km = road.oscillations.length / distanceKm * 10;
    put(DrivingDimension(
      kind: DrivingDimensionKind.energyOscillation,
      value: _clamp01(1 - per10Km * 0.25),
      confidence: distanceKm >= 5
          ? DimensionConfidence.medium
          : DimensionConfidence.low,
      evidenceCount: road.oscillations.length,
      context: '${road.oscillations.length} episode(s)',
    ));
  }

  // Coasting: decelerations taken as fuel cut — needs a fuel-rate signal.
  if (fuelRateDecelSec < 10) {
    put(const DrivingDimension.unknown(DrivingDimensionKind.coasting,
        context: 'no fuel-rate signal while slowing'));
  } else {
    put(DrivingDimension(
      kind: DrivingDimensionKind.coasting,
      value: _clamp01(fuelCutSec / fuelRateDecelSec),
      confidence: _byEvidence(fuelRateDecelSec.round(), medium: 30, high: 120),
      evidenceCount: fuelRateDecelSec.round(),
      context: 'fuel cut ${fuelCutSec.round()} s',
    ));
  }

  return DrivingDimensions(
    dims,
    rawTotals: DrivingPatternTotals(
      events: {
        DrivingEventCounter.hardAccelEvents: accel.accelEvents,
        DrivingEventCounter.hardBrakeEvents: brakes.length,
        DrivingEventCounter.avoidableHardBrakeEvents: avoidableBrakes,
        DrivingEventCounter.energyOscillationEpisodes: road.oscillations.length,
        DrivingEventCounter.judgedCurves: judgedCurves,
        DrivingEventCounter.lateBrakeCurves: lateCurves,
        DrivingEventCounter.longIdleEpisodes: idle.episodes,
      },
      seconds: {
        DrivingDurationCounter.fullThrottleSeconds: fullThrottleSec,
        DrivingDurationCounter.longIdleSeconds: idle.seconds,
        DrivingDurationCounter.highRpmSeconds: highRpmSec,
        DrivingDurationCounter.sustainedHighSpeedSeconds: sustainedHighSec,
        DrivingDurationCounter.fuelCutSeconds: fuelCutSec,
        DrivingDurationCounter.climbFullThrottleSeconds: climbFullSec,
        DrivingDurationCounter.flatFullThrottleSeconds: flatFullSec,
      },
      exposure: {
        DrivingExposureBasis.movingDistanceKm: distanceKm,
        DrivingExposureBasis.movingSeconds: movingSec,
        DrivingExposureBasis.pedalKnownSeconds: demandSec,
        DrivingExposureBasis.engineKnownSeconds: engineKnownSec,
        DrivingExposureBasis.rpmKnownMovingSeconds: rpmSec,
        DrivingExposureBasis.hardBrakeEvents: brakes.length.toDouble(),
        DrivingExposureBasis.judgedCurves: judgedCurves.toDouble(),
        DrivingExposureBasis.decelWithFuelRateSeconds: fuelRateDecelSec,
        DrivingExposureBasis.confidentClimbSeconds: climbSec,
        DrivingExposureBasis.confidentFlatSeconds: flatSec,
        DrivingExposureBasis.coolantKnownSeconds: coolantKnownSec,
      },
    ),
  );
}

/// Start moments of hard-brake runs on the track.
List<DateTime> _hardBrakeMoments(List<RoadLoadPoint> points) {
  final out = <DateTime>[];
  var inRun = false;
  for (final p in points) {
    final hard = (p.accelMps2 ?? 0) <= -kHardBrakeThresholdMps2;
    if (hard && !inRun) out.add(p.timestamp);
    inRun = hard;
  }
  return out;
}
