// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/fuel_energy_content.dart';
import 'package:tankstellen/features/trips/domain/services/gps_live_fuel_estimator.dart';

/// #3945 — the per-fuel energy content behind the all-prices estimate.
///
/// Pins the constants (a moved decimal here silently mis-prices every
/// estimated cell) AND ties them to the GPS live-fuel estimator's LHV table
/// (#2431): the two features may not import each other, so the test is the
/// single place that keeps one physics table in the app.
void main() {
  group('FuelEnergyContent — pinned values', () {
    test('petrol grades share the petrol figure', () {
      expect(FuelEnergyContent.petrolMjPerL, 31.9);
      for (final f in [FuelType.e5, FuelType.e10, FuelType.e98]) {
        expect(FuelEnergyContent.mjPerLitre(f), 31.9, reason: f.apiValue);
      }
    });

    test('diesel and premium diesel share the diesel figure', () {
      expect(FuelEnergyContent.dieselMjPerL, 35.8);
      expect(FuelEnergyContent.mjPerLitre(FuelType.diesel), 35.8);
      expect(FuelEnergyContent.mjPerLitre(FuelType.dieselPremium), 35.8);
    });

    test('E85 and LPG carry their own, lower figures', () {
      expect(FuelEnergyContent.mjPerLitre(FuelType.e85), 25.6);
      expect(FuelEnergyContent.mjPerLitre(FuelType.lpg), 26.0);
    });

    test('fuels without a per-litre energy content have no figure', () {
      for (final f in [
        FuelType.cng,
        FuelType.electric,
        FuelType.hydrogen,
        FuelType.all,
      ]) {
        expect(FuelEnergyContent.mjPerLitre(f), isNull, reason: f.apiValue);
      }
    });
  });

  group('FuelEnergyContent — one physics table in the app', () {
    test('matches the GPS live-fuel estimator LHV constants (#2431)', () {
      expect(
        FuelEnergyContent.petrolMjPerL,
        GpsLiveFuelEstimator.petrolLhvMjPerL,
      );
      expect(
        FuelEnergyContent.dieselMjPerL,
        GpsLiveFuelEstimator.dieselLhvMjPerL,
      );
      expect(FuelEnergyContent.e85MjPerL, GpsLiveFuelEstimator.e85LhvMjPerL);
      expect(FuelEnergyContent.lpgMjPerL, GpsLiveFuelEstimator.lpgLhvMjPerL);
    });
  });

  group('FuelEnergyContent.litreRatio', () {
    test('E85 needs ~25 % more litres than petrol for the same drive', () {
      final ratio = FuelEnergyContent.litreRatio(
        base: FuelType.e10,
        target: FuelType.e85,
      );
      expect(ratio, closeTo(31.9 / 25.6, 1e-12));
      expect(ratio, greaterThan(1.2));
      expect(ratio, lessThan(1.3));
    });

    test('is the inverse the other way round', () {
      final a = FuelEnergyContent.litreRatio(
        base: FuelType.e85,
        target: FuelType.e10,
      )!;
      final b = FuelEnergyContent.litreRatio(
        base: FuelType.e10,
        target: FuelType.e85,
      )!;
      expect(a * b, closeTo(1, 1e-12));
    });

    test('is exactly 1 between grades of the same family', () {
      expect(
        FuelEnergyContent.litreRatio(base: FuelType.e5, target: FuelType.e98),
        1.0,
      );
    });

    test('is null when either side has no volumetric figure', () {
      expect(
        FuelEnergyContent.litreRatio(base: FuelType.e10, target: FuelType.cng),
        isNull,
      );
      expect(
        FuelEnergyContent.litreRatio(base: FuelType.cng, target: FuelType.e10),
        isNull,
      );
    });
  });
}
