// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3599 — a towed/flatbed/train trip (ECU answering, engine off, GPS
// distance real) must be detected and excluded from fuel aggregates.
// Field shape: 76.5 km at ~93 km/h with the engine running ~2% of it,
// recorded as 3.69 L/100km 'veryGood'.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/engine_off_transport.dart';
import 'package:tankstellen/features/consumption/domain/services/trip_consumed_liters.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

void main() {
  final t0 = DateTime(2026, 7, 25, 14);

  TripSummary mk({
    double distanceKm = 76.5,
    double? engineRunningSeconds,
    int durationSec = 2956,
    TripKind kind = TripKind.gpsPlusObd2,
    double? avg,
  }) =>
      TripSummary(
        distanceKm: distanceKm,
        maxRpm: 1000,
        highRpmSeconds: 0,
        idleSeconds: 10,
        harshBrakes: 0,
        harshAccelerations: 0,
        avgLPer100Km: avg,
        startedAt: t0,
        endedAt: t0.add(Duration(seconds: durationSec)),
        kind: kind,
        engineRunningSeconds: engineRunningSeconds,
      );

  test('the field tow is flagged: 76.5 km with the engine running 2%', () {
    expect(isEngineOffTransport(mk(engineRunningSeconds: 60)), isTrue);
  });

  test('a real drive is never flagged — engine running nearly throughout',
      () {
    expect(isEngineOffTransport(mk(engineRunningSeconds: 2900)), isFalse);
  });

  test('legacy trips (null field) are never flagged', () {
    expect(isEngineOffTransport(mk(engineRunningSeconds: null)), isFalse);
  });

  test('GPS-only trips are never flagged — no engine signal to be off', () {
    expect(
      isEngineOffTransport(
          mk(engineRunningSeconds: 0, kind: TripKind.gpsOnly)),
      isFalse,
    );
  });

  test('short adapter-connected shuffles are never flagged', () {
    expect(
      isEngineOffTransport(
          mk(distanceKm: 1.2, engineRunningSeconds: 0, durationSec: 300)),
      isFalse,
    );
  });

  test('transport trips are excluded from the canonical litres chokepoint '
      '— the 3.69 L/100km tow cannot poison the aggregates', () {
    final tow = mk(engineRunningSeconds: 60, avg: 3.69);
    expect(tripConsumedLitersOrNull(tow), isNull);
    // The same trip WITH a running engine keeps its figure.
    final drive = mk(engineRunningSeconds: 2900, avg: 11.5);
    expect(tripConsumedLitersOrNull(drive), isNotNull);
  });
}
