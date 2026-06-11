// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/gps_live_fuel_estimator.dart';
import 'package:tankstellen/features/consumption/domain/services/physics_scale_calibrator.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/core/domain/gps_calibration_matrix.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';

const _vehicle = VehicleProfile(
  id: 'v1',
  name: 'test',
  curbWeightKg: 1500,
  preferredFuelType: 'petrol',
);

final _epoch = DateTime.utc(2026, 1, 1, 8);

/// A steady-cruise GPS sample stream: [ticks] samples at constant
/// [speedKmh], 1 s apart. Long enough + far enough to clear the
/// calibrator's signal gates by default.
List<TripSample> _cruiseSamples({
  double speedKmh = 90,
  int ticks = 200,
}) =>
    List<TripSample>.generate(
      ticks,
      (i) => TripSample(
        timestamp: _epoch.add(Duration(seconds: i)),
        speedKmh: speedKmh,
        rpm: 2000,
        // OBD2 trips carry a fuel rate on their samples; the value is
        // irrelevant to the replay (the physics model ignores it) but
        // its presence is the "this was a dongle trip" marker.
        fuelRateLPerHour: 5,
      ),
    );

/// A gpsPlusObd2 [TripSummary] over [samples] with a measured
/// [avgLPer100Km], distance + duration derived from the sample span so
/// the signal gates pass.
TripSummary _summary({
  required List<TripSample> samples,
  required double? avgLPer100Km,
  TripKind kind = TripKind.gpsPlusObd2,
  bool fuelRateSuspect = false,
  double? distanceKm,
}) {
  final start = samples.first.timestamp;
  final end = samples.last.timestamp;
  final seconds = end.difference(start).inSeconds.toDouble();
  // distance from the constant cruise speed unless overridden.
  final km = distanceKm ?? samples.first.speedKmh / 3.6 * seconds / 1000.0;
  return TripSummary(
    distanceKm: km,
    maxRpm: 2000,
    highRpmSeconds: 0,
    idleSeconds: 0,
    harshBrakes: 0,
    harshAccelerations: 0,
    avgLPer100Km: avgLPer100Km,
    startedAt: start,
    endedAt: end,
    fuelRateSuspect: fuelRateSuspect,
    kind: kind,
  );
}

/// The raw (scale-1.0) physics prediction the calibrator replays — used
/// to build expectations independent of the calibrator's internals.
double _rawPredicted(List<TripSample> samples) {
  final e = GpsLiveFuelEstimator.forVehicle(_vehicle, null);
  for (var i = 1; i < samples.length; i++) {
    final dt = samples[i]
            .timestamp
            .difference(samples[i - 1].timestamp)
            .inMilliseconds /
        1000.0;
    e.onSample(
      speedMps: samples[i].speedKmh / 3.6,
      prevSpeedMps: samples[i - 1].speedKmh / 3.6,
      dtSeconds: dt,
    );
  }
  return e.runningAvgLPer100Km!;
}

void main() {
  group('PhysicsScaleCalibrator.calibrate — direction', () {
    test('measured < predicted lowers physicsScale toward the ratio', () {
      final samples = _cruiseSamples();
      final predicted = _rawPredicted(samples); // scale 1.0
      // Measure clearly below the physics prediction.
      final measured = predicted * 0.7;
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: const GpsCalibrationMatrix(physicsScale: 1.0),
        summary: _summary(samples: samples, avgLPer100Km: measured),
        samples: samples,
      );

      // One EWMA step toward ratio 0.7 with alpha 0.3:
      // 1.0 * (1 + 0.3*(0.7 - 1)) = 0.91.
      const ratio = 0.7;
      const expected = 1.0 * (1 + PhysicsScaleCalibrator.alpha * (ratio - 1));
      expect(updated.physicsScale, closeTo(expected, 1e-9));
      expect(updated.physicsScale, lessThan(1.0));
    });

    test('measured > predicted raises physicsScale toward the ratio', () {
      final samples = _cruiseSamples();
      final predicted = _rawPredicted(samples);
      final measured = predicted * 1.4;
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: const GpsCalibrationMatrix(physicsScale: 1.0),
        summary: _summary(samples: samples, avgLPer100Km: measured),
        samples: samples,
      );
      const ratio = 1.4;
      const expected = 1.0 * (1 + PhysicsScaleCalibrator.alpha * (ratio - 1));
      expect(updated.physicsScale, closeTo(expected, 1e-9));
      expect(updated.physicsScale, greaterThan(1.0));
    });

    test('a perfectly-matching trip leaves physicsScale unchanged', () {
      final samples = _cruiseSamples();
      final predicted = _rawPredicted(samples);
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: const GpsCalibrationMatrix(physicsScale: 1.0),
        summary: _summary(samples: samples, avgLPer100Km: predicted),
        samples: samples,
      );
      expect(updated.physicsScale, closeTo(1.0, 1e-9));
    });
  });

  group('PhysicsScaleCalibrator.calibrate — clamp band', () {
    test('a wildly-low measured trip cannot push scale below the floor', () {
      final samples = _cruiseSamples();
      // Start already near the floor; a tiny measured value would push
      // below 0.5 without the clamp.
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: const GpsCalibrationMatrix(
            physicsScale: GpsCalibrationMatrix.physicsScaleMin),
        summary: _summary(samples: samples, avgLPer100Km: 0.5),
        samples: samples,
      );
      expect(updated.physicsScale,
          greaterThanOrEqualTo(GpsCalibrationMatrix.physicsScaleMin));
    });

    test('a wildly-high measured trip cannot push scale above the ceiling',
        () {
      final samples = _cruiseSamples();
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: const GpsCalibrationMatrix(
            physicsScale: GpsCalibrationMatrix.physicsScaleMax),
        summary: _summary(samples: samples, avgLPer100Km: 30),
        samples: samples,
      );
      expect(updated.physicsScale,
          lessThanOrEqualTo(GpsCalibrationMatrix.physicsScaleMax));
    });
  });

  group('PhysicsScaleCalibrator.calibrate — gating (no-op trips)', () {
    const matrix = GpsCalibrationMatrix(physicsScale: 1.2);
    final samples = _cruiseSamples();
    final predicted = _rawPredicted(samples);

    test('GPS-only trip (no ground truth) does not change the scale', () {
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: matrix,
        summary: _summary(
          samples: samples,
          avgLPer100Km: predicted * 0.5,
          kind: TripKind.gpsOnly,
        ),
        samples: samples,
      );
      expect(updated.physicsScale, matrix.physicsScale);
      expect(updated, matrix);
    });

    test('a suspect fuel-rate trip does not change the scale', () {
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: matrix,
        summary: _summary(
          samples: samples,
          avgLPer100Km: predicted * 0.5,
          fuelRateSuspect: true,
        ),
        samples: samples,
      );
      expect(updated, matrix);
    });

    test('a null measured average does not change the scale', () {
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: matrix,
        summary: _summary(samples: samples, avgLPer100Km: null),
        samples: samples,
      );
      expect(updated, matrix);
    });

    test('a too-short trip (below the distance gate) does not change scale',
        () {
      final shortSamples = _cruiseSamples(ticks: 30); // ~0.75 km @ 90 km/h
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: matrix,
        summary: _summary(
          samples: shortSamples,
          avgLPer100Km: 5,
          distanceKm: 1.0, // below minDistanceKm (2.0)
        ),
        samples: shortSamples,
      );
      expect(updated, matrix);
    });

    test('a brief trip (below the duration gate) does not change scale', () {
      final brief = _cruiseSamples(ticks: 8); // 7 s span, < minSamples too
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: matrix,
        summary: _summary(
          samples: brief,
          avgLPer100Km: 5,
          distanceKm: 10, // distance fine, but duration/samples too small
        ),
        samples: brief,
      );
      expect(updated, matrix);
    });

    test('no samples does not change the scale', () {
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: matrix,
        summary: TripSummary(
          distanceKm: 10,
          maxRpm: 2000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
          avgLPer100Km: 5,
          startedAt: _epoch,
          endedAt: _epoch.add(const Duration(minutes: 10)),
        ),
        samples: const [],
      );
      expect(updated, matrix);
    });
  });

  group('PhysicsScaleCalibrator.calibrate — convergence', () {
    test('repeated consistent trips converge toward the true ratio', () {
      final samples = _cruiseSamples();
      final predicted = _rawPredicted(samples); // raw, scale 1.0
      // The vehicle truly burns 1.3x what the raw physics predicts; every
      // trip measures that consistently. The scale should converge toward
      // 1.3 (the ratio of measured / rawPredicted).
      const trueRatio = 1.3;
      final measured = predicted * trueRatio;

      GpsCalibrationMatrix matrix =
          const GpsCalibrationMatrix(physicsScale: 1.0);
      for (var trip = 0; trip < 25; trip++) {
        matrix = PhysicsScaleCalibrator.calibrate(
          vehicle: _vehicle,
          matrix: matrix,
          summary: _summary(samples: samples, avgLPer100Km: measured),
          samples: samples,
        );
      }
      expect(matrix.physicsScale, closeTo(trueRatio, 0.02));
    });

    test('converges from a stale over-estimate back down to the true ratio',
        () {
      final samples = _cruiseSamples();
      final predicted = _rawPredicted(samples);
      const trueRatio = 0.85;
      final measured = predicted * trueRatio;

      // Start from a bad, too-high scale (e.g. a prior mis-calibration).
      GpsCalibrationMatrix matrix =
          const GpsCalibrationMatrix(physicsScale: 1.8);
      for (var trip = 0; trip < 30; trip++) {
        matrix = PhysicsScaleCalibrator.calibrate(
          vehicle: _vehicle,
          matrix: matrix,
          summary: _summary(samples: samples, avgLPer100Km: measured),
          samples: samples,
        );
      }
      expect(matrix.physicsScale, closeTo(trueRatio, 0.02));
    });
  });

  group('PhysicsScaleCalibrator.calibrate — cold start', () {
    test('a null matrix seeds from coldStart and still steps the scale', () {
      final samples = _cruiseSamples();
      final predicted = _rawPredicted(samples);
      final updated = PhysicsScaleCalibrator.calibrate(
        vehicle: _vehicle,
        matrix: null,
        summary: _summary(samples: samples, avgLPer100Km: predicted * 0.7),
        samples: samples,
      );
      // coldStart scale is 1.0 → one step toward 0.7.
      const expected = 1.0 * (1 + PhysicsScaleCalibrator.alpha * (0.7 - 1));
      expect(updated.physicsScale, closeTo(expected, 1e-9));
    });
  });
}
