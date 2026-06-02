// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/services/gps_live_estimate_folder.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart'
    show TripSample;

/// #2654 — the folder is the single choke point that previously fed the
/// estimator ONLY speed/prevSpeed/dt, never a grade, so the existing
/// `m·g·gradeFraction` term in [GpsLiveFuelEstimator] was permanently
/// zeroed (gradeConfident defaulted false). These tests drive a whole trip
/// through [GpsLiveEstimateFolder.fold] and assert the wiring now feeds a
/// confident road grade derived from the per-fix altitude, biasing a
/// climbing GPS-only estimate UP relative to the identical speed profile on
/// flat ground — and that a no-altitude trip never gains a grade (and never
/// crashes).

/// Drive a trip through the folder at a constant [speedMps], one fix per
/// second, with the altitude at fix `i` produced by [altitudeAt]. Returns
/// the final fold's running litres (the integral the live "~ estimated"
/// figure is built from). A null [altitudeAt] (or one returning null) feeds
/// no altitude at all — the GPS-altitude-absent path.
GpsLiveEstimate _runTrip({
  required double speedMps,
  required int ticks,
  double? Function(int i)? altitudeAt,
}) {
  final folder = GpsLiveEstimateFolder.forVehicle(null, null);
  final start = DateTime(2026, 6, 2, 8);
  var last = GpsLiveEstimate.none;
  for (var i = 0; i < ticks; i++) {
    last = folder.fold(TripSample(
      timestamp: start.add(Duration(seconds: i)),
      speedKmh: speedMps * 3.6,
      rpm: 0, // GPS-only: no engine data
      altitudeM: altitudeAt?.call(i),
    ));
  }
  return last;
}

void main() {
  group('GpsLiveEstimateFolder — grade wiring (#2654)', () {
    test('a confident climbing trip burns MORE than the same flat profile',
        () {
      // 20 m/s, 1 s fixes → 20 m per fix. Over 30 fixes the trip covers
      // ~580 m — many full 150 m windows, each with ≥5 dense altitude
      // samples, so the RoadGradeCalculator reaches confidence well before
      // the end. The climbing trip rises 1.2 m per fix = 6 % grade; the
      // flat trip holds a constant altitude (confident grade ≈ 0).
      const speedMps = 20.0;
      const ticks = 30;

      // Read the FINAL running-litres integral off the live estimate so we
      // compare the same whole-trip fuel both pipelines would publish.
      final climbing = _runTrip(
        speedMps: speedMps,
        ticks: ticks,
        altitudeAt: (i) => 100.0 + i * 1.2, // +6 % climb
      );
      final flat = _runTrip(
        speedMps: speedMps,
        ticks: ticks,
        altitudeAt: (i) => 100.0, // dead level
      );

      expect(climbing.fuelLitersSoFar, isNotNull);
      expect(flat.fuelLitersSoFar, isNotNull);
      // BEFORE the fix both reads were identical (grade always zeroed) —
      // this assertion is RED on master. The climbing extra is first-order
      // (web: 0→6 % grade well north of +50 % tractive fuel), so a strict
      // greater-than with margin is safe.
      expect(
        climbing.fuelLitersSoFar!,
        greaterThan(flat.fuelLitersSoFar! * 1.05),
      );
      // The instantaneous figure must also be lifted by the live grade.
      expect(
        climbing.instantLPer100Km!,
        greaterThan(flat.instantLPer100Km!),
      );
    });

    test('a downhill trip burns no MORE than flat — negative grade is a '
        'credit, never a penalty', () {
      // A confident downhill (negative grade) reduces tractive force; the
      // estimator floors power at 0, so it can only ever read ≤ flat.
      const speedMps = 20.0;
      const ticks = 30;
      final downhill = _runTrip(
        speedMps: speedMps,
        ticks: ticks,
        altitudeAt: (i) => 100.0 - i * 1.2,
      );
      final flat = _runTrip(
        speedMps: speedMps,
        ticks: ticks,
        altitudeAt: (i) => 100.0,
      );
      expect(downhill.fuelLitersSoFar, isNotNull);
      expect(
        downhill.fuelLitersSoFar!,
        lessThanOrEqualTo(flat.fuelLitersSoFar!),
      );
    });

    test('a GPS-altitude-absent trip never gains a grade and never crashes',
        () {
      // Every fix carries a null altitude — the calculator adds no points,
      // confidence stays false, the grade term stays gated off, and the
      // read must equal the no-grade flat baseline EXACTLY (not merely be
      // finite). Mirrors the estimator's `gradeConfident: false` test.
      const speedMps = 20.0;
      const ticks = 30;
      final noAltitude = _runTrip(
        speedMps: speedMps,
        ticks: ticks,
        altitudeAt: (i) => null, // platform reports no altitude
      );
      // Same speed profile with a CONFIDENT flat (0 %) grade — both must
      // produce the identical integral because a zero grade contributes
      // nothing, proving the null path is gated off rather than injecting
      // garbage.
      final flat = _runTrip(
        speedMps: speedMps,
        ticks: ticks,
        altitudeAt: (i) => 100.0,
      );
      expect(noAltitude.fuelLitersSoFar, isNotNull);
      expect(
        noAltitude.fuelLitersSoFar!,
        closeTo(flat.fuelLitersSoFar!, 1e-9),
      );
      expect(noAltitude.instantLPer100Km, isNotNull);
    });

    test('overlay() carries the same grade wiring as fold()', () {
      // The OBD2 live path enters through overlay(); assert it folds the
      // altitude through too (a climbing overlay reads higher than flat).
      final climber = GpsLiveEstimateFolder.forVehicle(null, null);
      final flatter = GpsLiveEstimateFolder.forVehicle(null, null);
      final start = DateTime(2026, 6, 2, 8);
      const base = TripLiveReading(distanceKmSoFar: 0, elapsed: Duration.zero);
      var climbInstant = 0.0;
      var flatInstant = 0.0;
      for (var i = 0; i < 30; i++) {
        final climb = climber.overlay(
          base: base,
          now: start.add(Duration(seconds: i)),
          effectiveSpeedKmh: 72, // 20 m/s
          rpm: null,
          altitudeM: 100.0 + i * 1.2,
        );
        final level = flatter.overlay(
          base: base,
          now: start.add(Duration(seconds: i)),
          effectiveSpeedKmh: 72,
          rpm: null,
          altitudeM: 100.0,
        );
        climbInstant = climb.reading.gpsEstimatedLPer100Km ?? climbInstant;
        flatInstant = level.reading.gpsEstimatedLPer100Km ?? flatInstant;
      }
      expect(climbInstant, greaterThan(flatInstant));
    });
  });
}
