// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3877 — the end-of-trip odometer is the latest READING plus the distance
// driven since it (the stop often comes with the engine already off, when
// the final re-read fails), and says whether it is a reading or an estimate.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/providers/recording_pipeline.dart';

TripSummary _summary(double km) => TripSummary(
      distanceKm: km,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
    );

void main() {
  test('latest reading + distance driven since = end km (estimate)', () {
    final r = StoppedTripResult(
      summary: _summary(42.0),
      odometerStartKm: 100000,
      odometerLatestKm: 100030, // read at km 30 of the trip
      distanceKmAtOdometerLatest: 30,
    );
    expect(r.endOdometerKm, closeTo(100042, 1e-9));
    expect(r.endOdometerIsReading, isFalse);
  });

  test('a reading taken at the very end IS the end km', () {
    final r = StoppedTripResult(
      summary: _summary(42.0),
      odometerStartKm: 100000,
      odometerLatestKm: 100042,
      distanceKmAtOdometerLatest: 42.0,
    );
    expect(r.endOdometerKm, 100042);
    expect(r.endOdometerIsReading, isTrue);
  });

  test('legacy result without the distance stamp keeps the old behaviour '
      '(latest reading as is)', () {
    const r = StoppedTripResult(
      summary: TripSummary(
          distanceKm: 42, maxRpm: 0, highRpmSeconds: 0, idleSeconds: 0,
          harshBrakes: 0, harshAccelerations: 0),
      odometerStartKm: 100000,
      odometerLatestKm: 100030,
    );
    expect(r.endOdometerKm, 100030);
  });

  test('no reading at all → start + distance; nothing → null', () {
    final r = StoppedTripResult(
        summary: _summary(10), odometerStartKm: 500, odometerLatestKm: null);
    expect(r.endOdometerKm, 510);
    expect(r.endOdometerIsReading, isFalse);
    expect(const StoppedTripResult.empty().endOdometerKm, isNull);
  });

  test('a distance that went backwards never subtracts', () {
    final r = StoppedTripResult(
      summary: _summary(5),
      odometerStartKm: 1,
      odometerLatestKm: 20,
      distanceKmAtOdometerLatest: 9, // > summary distance (rounding)
    );
    expect(r.endOdometerKm, 20);
  });
}
