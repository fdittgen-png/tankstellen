// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/fuel_rate_estimator.dart' show kPetrolAfr, kPetrolDensityGPerL, kDieselAfr, kDieselDensityGPerL;
import 'package:tankstellen/features/obd2/domain/services/obd2_analytics_signals.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Unit tests for the #2286 per-sample analytics derivation: the
/// instantaneous L/100km math, the fuel-rate→MAF fallback, idle
/// detection, harsh-event classification, and RPM banding.
void main() {
  group('RpmBand.fromRpm (#2286)', () {
    test('classifies the four bands at their edges', () {
      expect(RpmBand.fromRpm(0), RpmBand.idle);
      expect(RpmBand.fromRpm(900), RpmBand.idle);
      expect(RpmBand.fromRpm(901), RpmBand.cruise);
      expect(RpmBand.fromRpm(2000), RpmBand.cruise);
      expect(RpmBand.fromRpm(2001), RpmBand.spirited);
      expect(RpmBand.fromRpm(3000), RpmBand.spirited);
      expect(RpmBand.fromRpm(3001), RpmBand.hard);
      expect(RpmBand.fromRpm(5500), RpmBand.hard);
    });
  });

  group('Obd2AnalyticsSignals.fuelRateFromMaf (#2286)', () {
    test('petrol: L/h = MAF × 3600 / (AFR × density)', () {
      final lph = Obd2AnalyticsSignals.fuelRateFromMaf(mafGramsPerSecond: 10.0);
      const expected = 10.0 * 3600.0 / (kPetrolAfr * kPetrolDensityGPerL);
      expect(lph, isNotNull);
      expect(lph!, closeTo(expected, 1e-9));
    });

    test('diesel uses the leaner AFR + denser fuel → a lower L/h', () {
      final petrol =
          Obd2AnalyticsSignals.fuelRateFromMaf(mafGramsPerSecond: 10.0)!;
      final diesel = Obd2AnalyticsSignals.fuelRateFromMaf(
        mafGramsPerSecond: 10.0,
        diesel: true,
      )!;
      const expectedDiesel = 10.0 * 3600.0 / (kDieselAfr * kDieselDensityGPerL);
      expect(diesel, closeTo(expectedDiesel, 1e-9));
      expect(diesel, lessThan(petrol),
          reason: 'diesel AFR×density is larger → less L/h for the same MAF');
    });

    test('null / non-positive MAF → null', () {
      expect(Obd2AnalyticsSignals.fuelRateFromMaf(mafGramsPerSecond: null),
          isNull);
      expect(
          Obd2AnalyticsSignals.fuelRateFromMaf(mafGramsPerSecond: 0), isNull);
      expect(Obd2AnalyticsSignals.fuelRateFromMaf(mafGramsPerSecond: -5),
          isNull);
    });
  });

  group('Obd2AnalyticsSignals.instantLPer100Km (#2286)', () {
    test('prefers the direct fuel rate over MAF when both present', () {
      // 6 L/h at 60 km/h = 10 L/100km. The MAF value would give a
      // different number, so this proves precedence.
      final v = Obd2AnalyticsSignals.instantLPer100Km(
        fuelRateLPerHour: 6.0,
        speedKmh: 60.0,
        mafGramsPerSecond: 99.0,
      );
      expect(v, isNotNull);
      expect(v!, closeTo(10.0, 1e-9));
    });

    test('falls back to MAF-derived flow when no direct fuel rate', () {
      const maf = 8.0;
      final rateFromMaf =
          Obd2AnalyticsSignals.fuelRateFromMaf(mafGramsPerSecond: maf)!;
      final v = Obd2AnalyticsSignals.instantLPer100Km(
        fuelRateLPerHour: null,
        speedKmh: 50.0,
        mafGramsPerSecond: maf,
      );
      expect(v, isNotNull);
      expect(v!, closeTo(rateFromMaf / 50.0 * 100.0, 1e-9));
    });

    test('null when neither fuel rate nor MAF is available', () {
      final v = Obd2AnalyticsSignals.instantLPer100Km(
        fuelRateLPerHour: null,
        speedKmh: 50.0,
        mafGramsPerSecond: null,
      );
      expect(v, isNull);
    });

    test('null at standstill — a per-distance figure is meaningless', () {
      final v = Obd2AnalyticsSignals.instantLPer100Km(
        fuelRateLPerHour: 1.2,
        speedKmh: 0.0,
      );
      expect(v, isNull);
    });
  });

  group('Obd2AnalyticsSignals.isIdling (#2286)', () {
    test('engine on + stationary = idling', () {
      expect(Obd2AnalyticsSignals.isIdling(rpm: 800, speedKmh: 0), isTrue);
      expect(Obd2AnalyticsSignals.isIdling(rpm: 800, speedKmh: 1.0), isTrue);
    });

    test('moving is not idling even at low rpm', () {
      expect(Obd2AnalyticsSignals.isIdling(rpm: 800, speedKmh: 30), isFalse);
    });

    test('engine off is not idling', () {
      expect(Obd2AnalyticsSignals.isIdling(rpm: 0, speedKmh: 0), isFalse);
    });
  });

  group('Obd2AnalyticsSignals.derive (#2286)', () {
    test('flags harsh acceleration from a hard speed jump', () {
      final t0 = DateTime(2026, 5, 29, 9);
      final prev = TripSample(timestamp: t0, speedKmh: 0, rpm: 1500);
      // 0 → 20 km/h in 1 s ≈ 5.56 m/s² > 3.0 m/s² threshold.
      final curr = TripSample(
        timestamp: t0.add(const Duration(seconds: 1)),
        speedKmh: 20,
        rpm: 3200,
      );
      final s = Obd2AnalyticsSignals.derive(curr, previous: prev);
      expect(s.harshAcceleration, isTrue);
      expect(s.harshDeceleration, isFalse);
      expect(s.rpmBand, RpmBand.hard);
      expect(s.accelG, isNotNull);
      expect(s.accelG!, greaterThan(0));
    });

    test('flags harsh deceleration from a hard speed drop', () {
      final t0 = DateTime(2026, 5, 29, 9);
      final prev = TripSample(timestamp: t0, speedKmh: 50, rpm: 2500);
      // 50 → 30 km/h in 1 s ≈ -5.56 m/s² < -3.5 m/s² threshold.
      final curr = TripSample(
        timestamp: t0.add(const Duration(seconds: 1)),
        speedKmh: 30,
        rpm: 2000,
      );
      final s = Obd2AnalyticsSignals.derive(curr, previous: prev);
      expect(s.harshDeceleration, isTrue);
      expect(s.harshAcceleration, isFalse);
    });

    test('does not flag a gentle change as harsh', () {
      final t0 = DateTime(2026, 5, 29, 9);
      final prev = TripSample(timestamp: t0, speedKmh: 50, rpm: 2000);
      // 50 → 52 km/h in 1 s ≈ 0.56 m/s² — well under threshold.
      final curr = TripSample(
        timestamp: t0.add(const Duration(seconds: 1)),
        speedKmh: 52,
        rpm: 2050,
      );
      final s = Obd2AnalyticsSignals.derive(curr, previous: prev);
      expect(s.harshAcceleration, isFalse);
      expect(s.harshDeceleration, isFalse);
      expect(s.rpmBand, RpmBand.spirited);
    });

    test('first sample (no previous) has null accel and no harsh flags', () {
      final s = Obd2AnalyticsSignals.derive(
        TripSample(timestamp: DateTime(2026, 5, 29, 9), speedKmh: 0, rpm: 850),
      );
      expect(s.accelG, isNull);
      expect(s.harshAcceleration, isFalse);
      expect(s.harshDeceleration, isFalse);
      expect(s.idling, isTrue);
      expect(s.rpmBand, RpmBand.idle);
    });

    test('derives instant L/100km via the MAF fallback when no fuel rate',
        () {
      final t0 = DateTime(2026, 5, 29, 9);
      final sample = TripSample(timestamp: t0, speedKmh: 60, rpm: 1800);
      final s = Obd2AnalyticsSignals.derive(
        sample,
        mafGramsPerSecond: 9.0,
      );
      final expectedRate =
          Obd2AnalyticsSignals.fuelRateFromMaf(mafGramsPerSecond: 9.0)!;
      expect(s.instantLPer100Km, isNotNull);
      expect(s.instantLPer100Km!,
          closeTo(expectedRate / 60.0 * 100.0, 1e-9));
    });
  });
}
