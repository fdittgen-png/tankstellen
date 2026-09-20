// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4366 — the typed evidence contract. These pin the property the
// existing calculator outputs lack: a numerator that says WHAT it counts
// and a denominator that says over how much it was observable.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving_score/data/driving_dimensions_calculator.dart';
import 'package:tankstellen/features/driving_score/data/driving_pattern_measures.dart';
import 'package:tankstellen/features/driving_score/domain/driving_dimensions.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';

final _t0 = DateTime.utc(2026, 9, 15, 8);

TripSample _s(int sec, double kmh, {double? rpm, double? pedal}) => TripSample(
      timestamp: _t0.add(Duration(seconds: sec)),
      speedKmh: kmh,
      rpm: rpm,
      pedalPercent: pedal,
      hAccuracyM: 5,
    );

void main() {
  group('typed numerators cannot be conflated', () {
    // THE mutation check for #4366 acceptance 1. The legacy
    // `evidenceCount` of accelerationDemand is literally
    // `accelEvents + fullThrottleSeconds.round()`, so a minute of steady
    // full throttle at a constant speed reads as 60 units of "evidence".
    // Treated as an event count — which is what an events/km rate would
    // do — that minute becomes 60 hard accelerations.
    test('60 s of full throttle with zero accel events is never 60 events',
        () {
      // Constant 100 km/h, pedal pinned: no speed change, so the accel
      // gate confirms nothing, while full-throttle seconds accumulate.
      final samples = [
        for (var i = 0; i < 300; i++) _s(i, 100, rpm: 3000, pedal: 100),
      ];
      final dims = computeDrivingDimensions(samples);
      final totals = dims.totals;

      // The legacy composite: events and rounded seconds, added.
      final legacy = dims[DrivingDimensionKind.accelerationDemand]
          .evidenceCount;
      expect(legacy, greaterThanOrEqualTo(60),
          reason: 'the legacy field really does absorb the seconds');

      expect(totals.eventCount(DrivingEventCounter.hardAccelEvents), 0,
          reason: 'nothing accelerated hard');
      expect(
          totals.durationSeconds(DrivingDurationCounter.fullThrottleSeconds),
          greaterThan(60),
          reason: 'the seconds are kept, as seconds');

      final rate = measureValue(
          totals, measureSpec(DrivingMeasureId.hardAccelRate));
      expect(rate, 0.0,
          reason: 'full-throttle seconds may never become an event rate');
      final legacyRate = legacy /
          totals.exposureOf(DrivingExposureBasis.movingDistanceKm) *
          100;
      expect(legacyRate, greaterThan(0),
          reason: 'this is the wrong answer the typed contract prevents');
    });

    test('a measure declares events or seconds, never both and never neither',
        () {
      for (final spec in kDrivingMeasures) {
        expect((spec.eventNumerator == null) != (spec.durationNumerator == null),
            isTrue,
            reason: spec.id.name);
      }
    });
  });

  group('totals are additive', () {
    test('summing two trips sums each typed counter and each exposure', () {
      final a = DrivingPatternTotals(
        events: const {DrivingEventCounter.hardAccelEvents: 4},
        seconds: const {DrivingDurationCounter.fullThrottleSeconds: 10},
        exposure: const {DrivingExposureBasis.movingDistanceKm: 40},
      );
      final b = DrivingPatternTotals(
        events: const {DrivingEventCounter.hardAccelEvents: 6},
        seconds: const {DrivingDurationCounter.fullThrottleSeconds: 5},
        exposure: const {DrivingExposureBasis.movingDistanceKm: 60},
      );
      final sum = a + b;
      expect(sum.eventCount(DrivingEventCounter.hardAccelEvents), 10);
      expect(sum.durationSeconds(DrivingDurationCounter.fullThrottleSeconds),
          15);
      expect(sum.exposureOf(DrivingExposureBasis.movingDistanceKm), 100);
    });

    test('totals of different model versions refuse to be added', () {
      final a = DrivingPatternTotals(
          exposure: const {DrivingExposureBasis.movingDistanceKm: 10});
      final b = DrivingPatternTotals(
          modelVersion: kDrivingPatternModelVersion + 1,
          exposure: const {DrivingExposureBasis.movingDistanceKm: 10});
      expect(() => a + b, throwsArgumentError);
    });

    test('an empty total is no evidence, not a measured zero', () {
      expect(DrivingPatternTotals.empty.isEmpty, isTrue);
      expect(
          measureValue(DrivingPatternTotals.empty,
              measureSpec(DrivingMeasureId.hardAccelRate)),
          isNull);
    });
  });

  group('missing signals leave no exposure', () {
    test('a GPS-only trip accrues no engine or coolant exposure', () {
      final totals =
          computeDrivingDimensions([for (var i = 0; i < 400; i++) _s(i, 60)])
              .totals;
      expect(totals.exposureOf(DrivingExposureBasis.rpmKnownMovingSeconds), 0);
      expect(totals.exposureOf(DrivingExposureBasis.engineKnownSeconds), 0);
      expect(totals.exposureOf(DrivingExposureBasis.coolantKnownSeconds), 0);
      expect(totals.exposureOf(DrivingExposureBasis.movingDistanceKm),
          greaterThan(0),
          reason: 'GPS still supports the distance-denominated measures');
    });

    test('an OBD trip accrues engine exposure', () {
      final totals = computeDrivingDimensions(
              [for (var i = 0; i < 400; i++) _s(i, 60, rpm: 2000)])
          .totals;
      expect(totals.exposureOf(DrivingExposureBasis.rpmKnownMovingSeconds),
          greaterThan(0));
    });
  });
}
