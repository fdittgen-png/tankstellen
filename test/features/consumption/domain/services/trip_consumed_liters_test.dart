// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/trip_consumed_liters.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Unit coverage for the canonical trip-litres helper (#2447) — the
/// single source of truth every trajets-total surface routes through.
TripSummary _summary({
  required double distanceKm,
  double? fuelLitersConsumed,
  double? avgLPer100Km,
  TripKind kind = TripKind.gpsPlusObd2,
}) =>
    TripSummary(
      distanceKm: distanceKm,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      fuelLitersConsumed: fuelLitersConsumed,
      avgLPer100Km: avgLPer100Km,
      kind: kind,
    );

void main() {
  group('tripConsumedLitersOrNull', () {
    test('uses the measured fuelLitersConsumed verbatim when present', () {
      final s = _summary(distanceKm: 100, fuelLitersConsumed: 6.3);
      expect(tripConsumedLitersOrNull(s), closeTo(6.3, 1e-9));
    });

    test('measured litres win over an estimate when BOTH are present', () {
      // A real fuel signal is never silently replaced by the estimate.
      final s = _summary(
        distanceKm: 100,
        fuelLitersConsumed: 6.3,
        avgLPer100Km: 9.0, // would imply 9 L — ignored.
      );
      expect(tripConsumedLitersOrNull(s), closeTo(6.3, 1e-9));
    });

    test('recovers the GPS estimate from avgLPer100Km × distance when '
        'litres are null (the null-fuel GPS/EV/legacy case)', () {
      // 8.0 L/100 km × 150 km = 12.0 L.
      final s = _summary(
        distanceKm: 150,
        avgLPer100Km: 8.0,
        kind: TripKind.gpsOnly,
      );
      expect(tripConsumedLitersOrNull(s), closeTo(12.0, 1e-9));
    });

    test('returns null when there is NEITHER litres NOR an estimate '
        '(honest no-data, never fabricated)', () {
      final s = _summary(distanceKm: 50, kind: TripKind.gpsOnly);
      expect(tripConsumedLitersOrNull(s), isNull);
    });

    test('returns null when an estimate exists but distance is zero', () {
      final s = _summary(distanceKm: 0, avgLPer100Km: 9.0);
      expect(tripConsumedLitersOrNull(s), isNull);
    });

    test('returns null when the avg estimate is non-positive', () {
      final s = _summary(distanceKm: 50, avgLPer100Km: 0);
      expect(tripConsumedLitersOrNull(s), isNull);
    });
  });

  group('tripConsumedLiters (summable)', () {
    test('folds a no-data trip in as 0, not as a fabricated figure', () {
      final s = _summary(distanceKm: 50, kind: TripKind.gpsOnly);
      expect(tripConsumedLiters(s), 0.0);
    });

    test('equals the nullable form when litres are known', () {
      final s = _summary(distanceKm: 100, avgLPer100Km: 5.0);
      expect(tripConsumedLiters(s), closeTo(5.0, 1e-9));
      expect(tripConsumedLiters(s), tripConsumedLitersOrNull(s));
    });
  });
}
