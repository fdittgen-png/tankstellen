// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/obd2_trip_features.dart';
import 'package:tankstellen/features/consumption/domain/trip_sample.dart';

TripSample _s({
  required int sec,
  double speedKmh = 50,
  double? rpm,
  double? fuelRateLPerHour,
  double? estimatedFuelRateLPerHour,
  double? throttlePercent,
  double? engineLoadPercent,
  double? absLoadPercent,
  double? pedalPercent,
  double? coolantTempC,
  double? lambda,
}) =>
    TripSample(
      timestamp: DateTime(2026, 1, 1, 0, 0, sec),
      speedKmh: speedKmh,
      rpm: rpm,
      fuelRateLPerHour: fuelRateLPerHour,
      estimatedFuelRateLPerHour: estimatedFuelRateLPerHour,
      throttlePercent: throttlePercent,
      engineLoadPercent: engineLoadPercent,
      absLoadPercent: absLoadPercent,
      pedalPercent: pedalPercent,
      coolantTempC: coolantTempC,
      lambda: lambda,
    );

void main() {
  group('Obd2TripFeatures.fromSamples', () {
    test('returns null for an empty trip', () {
      expect(Obd2TripFeatures.fromSamples(const []), isNull);
    });

    test('returns null for a pure-GPS trip (no engine signal) — the explicit '
        '0% OBD2-coverage marker', () {
      final gpsOnly = [
        _s(sec: 0, speedKmh: 30),
        _s(sec: 1, speedKmh: 32),
        _s(sec: 2, speedKmh: 35),
      ];
      expect(Obd2TripFeatures.fromSamples(gpsOnly), isNull);
    });

    test('computes coverage, RPM bands and idle share on a real OBD2 trip', () {
      final samples = [
        // idle: engine on, low rpm, stationary
        _s(sec: 0, speedKmh: 0, rpm: 800, throttlePercent: 0),
        _s(sec: 1, speedKmh: 40, rpm: 2000, throttlePercent: 30),
        _s(sec: 2, speedKmh: 60, rpm: 3500, throttlePercent: 80),
        // a GPS-fallback sample with no engine signal (link blip)
        _s(sec: 3, speedKmh: 62),
      ];

      final f = Obd2TripFeatures.fromSamples(samples)!;
      expect(f.sampleCount, 4);
      expect(f.obd2SampleCount, 3);
      expect(f.obd2Coverage, closeTo(0.75, 1e-9));
      // 1 of 3 RPM samples above 3000
      expect(f.rpmShareAbove3000, closeTo(1 / 3, 1e-9));
      // 1 of 4 samples idling
      expect(f.idleShare, closeTo(0.25, 1e-9));
      expect(f.rpm.mean, closeTo((800 + 2000 + 3500) / 3, 1e-6));
    });

    test('fuelSource = measured when any real fuel PID landed', () {
      final f = Obd2TripFeatures.fromSamples([
        _s(sec: 0, rpm: 1500, fuelRateLPerHour: 2.1),
        _s(sec: 1, rpm: 1600, estimatedFuelRateLPerHour: 3.0),
      ])!;
      expect(f.fuelSource, Obd2FuelSource.measured);
    });

    test('fuelSource = estimated when only the GPS-physics estimate exists', () {
      final f = Obd2TripFeatures.fromSamples([
        _s(sec: 0, rpm: 1500, estimatedFuelRateLPerHour: 3.0),
        _s(sec: 1, rpm: 1600, estimatedFuelRateLPerHour: 3.2),
      ])!;
      expect(f.fuelSource, Obd2FuelSource.estimated);
    });

    test('fuelSource = none when neither measured nor estimated fuel exists',
        () {
      final f = Obd2TripFeatures.fromSamples([
        _s(sec: 0, rpm: 1500),
        _s(sec: 1, rpm: 1600),
      ])!;
      expect(f.fuelSource, Obd2FuelSource.none);
    });

    test('signalCoverage reflects which PIDs the adapter exposed', () {
      final f = Obd2TripFeatures.fromSamples([
        _s(sec: 0, rpm: 1500, engineLoadPercent: 40, lambda: 0.99),
        _s(sec: 1, rpm: 1600, engineLoadPercent: 45),
      ])!;
      expect(f.signalCoverage['rpm'], closeTo(1.0, 1e-9));
      expect(f.signalCoverage['engineLoadPercent'], closeTo(1.0, 1e-9));
      expect(f.signalCoverage['lambda'], closeTo(0.5, 1e-9));
      // never present → 0.0, the "PID unsupported / link down" marker
      expect(f.signalCoverage['maf'], 0.0);
      expect(f.signalCoverage['absLoadPercent'], 0.0);
    });

    test('coolant operating-temperature flag', () {
      final cold = Obd2TripFeatures.fromSamples([
        _s(sec: 0, rpm: 1500, coolantTempC: 40),
        _s(sec: 1, rpm: 1500, coolantTempC: 60),
      ])!;
      expect(cold.coolantMaxC, 60);
      expect(cold.reachedOperatingTemp, isFalse);

      final warm = Obd2TripFeatures.fromSamples([
        _s(sec: 0, rpm: 1500, coolantTempC: 70),
        _s(sec: 1, rpm: 1500, coolantTempC: 88),
      ])!;
      expect(warm.reachedOperatingTemp, isTrue);
    });

    test('toJson is stable and rounds', () {
      final json = Obd2TripFeatures.fromSamples([
        _s(sec: 0, rpm: 800, engineLoadPercent: 20, throttlePercent: 10),
        _s(sec: 1, rpm: 2500, engineLoadPercent: 55, throttlePercent: 60),
      ])!.toJson();
      expect(json['fuelSource'], 'none');
      expect(json['obd2Coverage'], 1.0);
      expect((json['rpm'] as Map)['mean'], 1650.0);
      expect((json['signalCoverage'] as Map)['rpm'], 1.0);
    });
  });
}
