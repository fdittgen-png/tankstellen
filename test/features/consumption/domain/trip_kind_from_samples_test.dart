// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

// #2692 C4-G — GPS-only samples now carry rpm null (no engine signal),
// formerly the `rpm: 0` placeholder. `TripKind.fromSamples` maps null → 0
// (`?? 0`), so the gpsOnly classification is unchanged.
TripSample _gpsOnlySample(DateTime t, double speedKmh) => TripSample(
      timestamp: t,
      speedKmh: speedKmh,
      rpm: null,
    );

TripSample _obd2Sample(
  DateTime t, {
  double speedKmh = 50,
  double rpm = 2000,
  double? fuelRateLPerHour,
}) =>
    TripSample(
      timestamp: t,
      speedKmh: speedKmh,
      rpm: rpm,
      fuelRateLPerHour: fuelRateLPerHour,
    );

void main() {
  group('TripKind.fromSamples (#2025 mid-trip upgrade)', () {
    final t0 = DateTime.utc(2026, 5, 25, 10);

    test('empty samples → gpsPlusObd2 (preserves the historical default)',
        () {
      expect(TripKind.fromSamples(const <TripSample>[]),
          TripKind.gpsPlusObd2);
    });

    test('all GPS-only samples (rpm=null, fuelRate=null) → gpsOnly', () {
      final samples = [
        for (int i = 0; i < 5; i++)
          _gpsOnlySample(t0.add(Duration(seconds: i)), 50.0 + i),
      ];
      // Regression for #2692 C4-G — the null-rpm GPS-only stream must still
      // classify as gpsOnly (it must NOT flip to gpsPlusObd2).
      expect(TripKind.fromSamples(samples), TripKind.gpsOnly);
    });

    test('any sample with rpm > 0 flips the trip to gpsPlusObd2', () {
      final samples = [
        _gpsOnlySample(t0, 50),
        _gpsOnlySample(t0.add(const Duration(seconds: 1)), 52),
        // mid-trip OBD2 sample
        _obd2Sample(t0.add(const Duration(seconds: 2)), rpm: 1800),
        _gpsOnlySample(t0.add(const Duration(seconds: 3)), 55),
      ];
      expect(TripKind.fromSamples(samples), TripKind.gpsPlusObd2);
    });

    test('any sample with non-null fuelRate flips to gpsPlusObd2', () {
      final samples = [
        _gpsOnlySample(t0, 50),
        // OBD2 reports speed + fuel rate but rpm == 0 (idle case)
        _obd2Sample(
          t0.add(const Duration(seconds: 1)),
          rpm: 0,
          fuelRateLPerHour: 0.6,
        ),
      ];
      expect(TripKind.fromSamples(samples), TripKind.gpsPlusObd2);
    });

    test('all OBD2 samples → gpsPlusObd2', () {
      final samples = [
        for (int i = 0; i < 5; i++)
          _obd2Sample(t0.add(Duration(seconds: i))),
      ];
      expect(TripKind.fromSamples(samples), TripKind.gpsPlusObd2);
    });

    test('iterable input — works with sequences that are not Lists', () {
      Iterable<TripSample> gen() sync* {
        yield _gpsOnlySample(t0, 50);
        yield _obd2Sample(t0.add(const Duration(seconds: 1)));
      }

      expect(TripKind.fromSamples(gen()), TripKind.gpsPlusObd2);
    });
  });
}
