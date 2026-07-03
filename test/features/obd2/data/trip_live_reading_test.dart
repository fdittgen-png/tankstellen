// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/trip_live_reading.dart';

void main() {
  group('TripLiveReading constructor', () {
    test('optional fields default to null when only required are supplied',
        () {
      const reading = TripLiveReading(
        distanceKmSoFar: 1.5,
        elapsed: Duration(seconds: 45),
      );
      expect(reading.distanceKmSoFar, 1.5);
      expect(reading.elapsed, const Duration(seconds: 45));
      expect(reading.speedKmh, isNull);
      expect(reading.rpm, isNull);
      expect(reading.fuelRateLPerHour, isNull);
      expect(reading.fuelLevelPercent, isNull);
      expect(reading.engineLoadPercent, isNull);
      expect(reading.throttlePercent, isNull);
      expect(reading.coolantTempC, isNull);
      expect(reading.fuelLitersSoFar, isNull);
      expect(reading.odometerStartKm, isNull);
      expect(reading.odometerNowKm, isNull);
      // #2389 — the GPS-only live estimate defaults null so existing call
      // sites (notably the OBD2 controller, which never sets it) compile
      // unchanged and surface no estimate.
      expect(reading.gpsEstimatedLPer100Km, isNull);
    });

    test('an OBD2-style reading keeps its real fuel value and leaves the '
        'GPS estimate null — the estimate never clobbers ground truth '
        '(#2389)', () {
      // Mirrors what the OBD2 controller emits: a measured fuel-rate +
      // litres-so-far, and no GPS estimate (the OBD2 path never sets it).
      const reading = TripLiveReading(
        distanceKmSoFar: 20.0,
        elapsed: Duration(minutes: 15),
        fuelRateLPerHour: 4.0,
        fuelLitersSoFar: 1.0,
      );
      // The real measured average stays the source of truth.
      expect(reading.liveAvgLPer100Km, closeTo(5.0, 1e-9));
      expect(reading.fuelLitersSoFar, 1.0);
      // The GPS estimate is absent on an OBD2 trip.
      expect(reading.gpsEstimatedLPer100Km, isNull);
    });

    test('gpsEstimatedLPer100Km stores the value supplied by the GPS '
        'pipeline (#2389)', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 5.0,
        elapsed: Duration(minutes: 3),
        gpsEstimatedLPer100Km: 6.4,
      );
      expect(reading.gpsEstimatedLPer100Km, 6.4);
      // It is independent of the measured fuel path, which stays null.
      expect(reading.fuelLitersSoFar, isNull);
      expect(reading.liveAvgLPer100Km, isNull);
    });

    test('coolantTempC stores the value supplied by the controller (#1262)',
        () {
      const reading = TripLiveReading(
        coolantTempC: 78.5,
        distanceKmSoFar: 0,
        elapsed: Duration.zero,
      );
      expect(reading.coolantTempC, 78.5);
    });
  });

  group('TripLiveReading.liveAvgLPer100Km', () {
    test('returns null when fuelLitersSoFar is null', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 10.0,
        elapsed: Duration(minutes: 5),
      );
      expect(reading.liveAvgLPer100Km, isNull);
    });

    test('returns null when distanceKmSoFar is exactly 0.0', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 0.0,
        elapsed: Duration(seconds: 10),
        fuelLitersSoFar: 0.2,
      );
      expect(reading.liveAvgLPer100Km, isNull);
    });

    test('returns null when distanceKmSoFar is below the 0.01 km floor', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 0.005,
        elapsed: Duration(seconds: 5),
        fuelLitersSoFar: 0.01,
      );
      expect(reading.liveAvgLPer100Km, isNull);
    });

    test('returns a value at the boundary distanceKmSoFar == 0.01 km', () {
      // Boundary: the guard is `< 0.01`, so 0.01 exactly is *not* rejected.
      const reading = TripLiveReading(
        distanceKmSoFar: 0.01,
        elapsed: Duration(seconds: 5),
        fuelLitersSoFar: 0.001,
      );
      final value = reading.liveAvgLPer100Km;
      expect(value, isNotNull);
      expect(value, closeTo(10.0, 1e-9));
    });

    test('realistic values: 1 L over 20 km → 5.0 L/100km', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 20.0,
        elapsed: Duration(minutes: 15),
        fuelLitersSoFar: 1.0,
      );
      expect(reading.liveAvgLPer100Km, closeTo(5.0, 1e-9));
    });

    test('free-coast case: 0 L over 10 km → 0.0 L/100km', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 10.0,
        elapsed: Duration(minutes: 5),
        fuelLitersSoFar: 0.0,
      );
      expect(reading.liveAvgLPer100Km, 0.0);
    });

    test('very small distance above floor: 0.01 L over 0.02 km → 50.0 L/100km',
        () {
      const reading = TripLiveReading(
        distanceKmSoFar: 0.02,
        elapsed: Duration(seconds: 2),
        fuelLitersSoFar: 0.01,
      );
      expect(reading.liveAvgLPer100Km, closeTo(50.0, 1e-9));
    });
  });

  group('true-instant fields (#3431)', () {
    test('default null so existing call sites compile and show no signal',
        () {
      const reading = TripLiveReading(
        distanceKmSoFar: 1.0,
        elapsed: Duration(minutes: 1),
      );
      expect(reading.instantLPer100Km, isNull);
      expect(reading.instantLPerHour, isNull);
      expect(reading.instantIsIdle, isNull);
    });

    test('store the EMA-stamped values independently of the running average',
        () {
      const reading = TripLiveReading(
        distanceKmSoFar: 10.0,
        elapsed: Duration(minutes: 5),
        fuelLitersSoFar: 0.83, // running avg → 8.3
        instantLPer100Km: 12.5, // instant is a DIFFERENT signal
        instantLPerHour: 7.5,
        instantIsIdle: false,
      );
      expect(reading.liveAvgLPer100Km, closeTo(8.3, 1e-9));
      expect(reading.instantLPer100Km, 12.5);
      expect(reading.instantLPerHour, 7.5);
      expect(reading.instantIsIdle, isFalse);
    });

    test('copyWith keeps the instant fields on a null overlay', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 10.0,
        elapsed: Duration(minutes: 5),
        instantLPer100Km: 12.5,
        instantLPerHour: 7.5,
        instantIsIdle: true,
      );
      final overlaid = reading.copyWith(speedKmh: 42.0);
      expect(overlaid.speedKmh, 42.0);
      expect(overlaid.instantLPer100Km, 12.5);
      expect(overlaid.instantLPerHour, 7.5);
      expect(overlaid.instantIsIdle, isTrue);
    });
  });
}
