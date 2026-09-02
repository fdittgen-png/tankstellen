// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/domain/fuel_mixture_model.dart';
import 'package:tankstellen/features/obd2/domain/trip_live_reading.dart';

/// #3916 — the live reading's fuel-rate provenance: measured ECU PIDs vs
/// the air-mass estimates the pump gain calibrates (#3886), and the
/// keep-on-null `copyWith` contract for the two new fields.
void main() {
  TripLiveReading reading(FuelRateSourceTag? source) => TripLiveReading(
        elapsed: const Duration(minutes: 1),
        distanceKmSoFar: 1.0,
        fuelSource: source,
      );

  test('measured PIDs read true', () {
    for (final tag in [
      FuelRateSourceTag.pid9D,
      FuelRateSourceTag.pidA2,
      FuelRateSourceTag.pid5E,
    ]) {
      expect(reading(tag).fuelRateIsMeasured, isTrue, reason: '$tag');
    }
  });

  test('air-mass estimates read false', () {
    for (final tag in [
      FuelRateSourceTag.maf66,
      FuelRateSourceTag.maf,
      FuelRateSourceTag.speedDensity,
    ]) {
      expect(reading(tag).fuelRateIsMeasured, isFalse, reason: '$tag');
    }
  });

  test('no provenance reads null', () {
    expect(reading(null).fuelRateIsMeasured, isNull);
    expect(reading(FuelRateSourceTag.none).fuelRateIsMeasured, isNull);
  });

  test('copyWith keeps the provenance + read rate on a null overlay', () {
    const base = TripLiveReading(
      elapsed: Duration(minutes: 1),
      distanceKmSoFar: 1.0,
      fuelSource: FuelRateSourceTag.pid5E,
      obd2ReadsPerSecond: 9.5,
    );
    final overlaid = base.copyWith(speedKmh: 30);
    expect(overlaid.fuelSource, FuelRateSourceTag.pid5E);
    expect(overlaid.obd2ReadsPerSecond, 9.5);
    expect(overlaid.speedKmh, 30);
  });
}
