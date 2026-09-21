// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fill_up_vehicle_scope.dart';
import 'package:tankstellen/features/fill_ups/domain/services/price_baseline.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';

/// #4150 — what this driver normally pays, and normally buys.
///
/// `savings_ledger_test.dart` exercises the baseline through the ledger;
/// these are the baseline's own acceptance criteria, including the three
/// the ledger never reaches: the window boundary, two vehicles, and a
/// history made only of corrections.
void main() {
  final now = DateTime.utc(2026, 9, 14, 12);

  FillUp fill({
    required String id,
    required double litres,
    required double pricePerLitre,
    int daysAgo = 0,
    FuelType fuel = FuelType.e10,
    bool correction = false,
    String? vehicleId,
  }) =>
      FillUp(
        id: id,
        date: now.subtract(Duration(days: daysAgo)),
        liters: litres,
        totalCost: litres * pricePerLitre,
        odometerKm: 10000 + daysAgo.toDouble(),
        fuelType: fuel,
        isCorrection: correction,
        vehicleId: vehicleId,
      );

  List<FillUp> regular({double litres = 40, double price = 1.70}) => [
        for (var i = 0; i < 4; i++)
          fill(
            id: 'f$i',
            litres: litres,
            pricePerLitre: price,
            daysAgo: i * 10,
          ),
      ];

  PriceBaseline? baseline(List<FillUp> fills, {FuelType? fuel}) =>
      priceBaselineFor(fills, fuelType: fuel ?? FuelType.e10, now: now);

  group('median, not mean', () {
    test('one motorway fill cannot move what the driver is judged '
        'against', () {
      // The mean of these is ~1.79; the median is 1.71. A baseline that
      // moved with the outlier would quietly raise the bar every saving
      // is measured against, which is the opposite of what it is for.
      final fills = [
        fill(id: '1', litres: 40, pricePerLitre: 1.70),
        fill(id: '2', litres: 40, pricePerLitre: 1.71, daysAgo: 10),
        fill(id: '3', litres: 40, pricePerLitre: 1.72, daysAgo: 20),
        fill(id: '4', litres: 40, pricePerLitre: 2.05, daysAgo: 30),
      ];
      final b = baseline(fills)!;
      expect(b.typicalPricePerLitre, closeTo(1.715, 0.001));
      expect(b.typicalPricePerLitre, lessThan(1.75),
          reason: 'the mean would be dragged up by the motorway fill');
    });

    test('a jerrycan does not become the usual fill', () {
      final fills = [
        fill(id: '1', litres: 45, pricePerLitre: 1.70),
        fill(id: '2', litres: 46, pricePerLitre: 1.70, daysAgo: 10),
        fill(id: '3', litres: 44, pricePerLitre: 1.70, daysAgo: 20),
        fill(id: '4', litres: 5, pricePerLitre: 1.70, daysAgo: 30),
      ];
      expect(baseline(fills)!.typicalLitres, closeTo(44.5, 0.01));
    });
  });

  group('the window', () {
    test('a fill inside the window counts', () {
      final fills = [
        ...regular().take(3),
        fill(
          id: 'edge',
          litres: 40,
          pricePerLitre: 1.70,
          daysAgo: kBaselineWindow.inDays - 1,
        ),
      ];
      expect(baseline(fills)?.sampleCount, 4);
    });

    test('a fill outside it does not, and can drop the baseline entirely',
        () {
      // Exactly the minimum sample count, with one of them just past the
      // edge: the baseline must vanish rather than quietly compute on
      // three.
      final fills = [
        ...regular().take(3),
        fill(
          id: 'stale',
          litres: 40,
          pricePerLitre: 1.70,
          daysAgo: kBaselineWindow.inDays + 1,
        ),
      ];
      expect(baseline(fills), isNull);
    });

    test('the window follows the market, not a year of price history',
        () {
      // Old fills at a very different price are excluded outright rather
      // than averaged in.
      final fills = [
        ...regular(price: 1.70),
        for (var i = 0; i < 6; i++)
          fill(
            id: 'old$i',
            litres: 40,
            pricePerLitre: 1.20,
            daysAgo: kBaselineWindow.inDays + 10 + i,
          ),
      ];
      expect(baseline(fills)!.typicalPricePerLitre, closeTo(1.70, 0.001));
    });
  });

  group('null is a real answer, not a failure', () {
    test('below the minimum there is no baseline', () {
      expect(baseline(regular().take(kMinBaselineSamples - 1).toList()),
          isNull);
      expect(baseline(regular()), isNotNull);
    });

    test('the sample count is exposed so a surface can say what is '
        'missing', () {
      expect(baseline(regular())!.sampleCount, kMinBaselineSamples);
    });

    test('a history of corrections only yields nothing', () {
      // Corrections are bookkeeping, not purchases.
      final fills = [
        for (var i = 0; i < 8; i++)
          fill(
            id: 'c$i',
            litres: 40,
            pricePerLitre: 1.70,
            daysAgo: i * 5,
            correction: true,
          ),
      ];
      expect(baseline(fills), isNull);
    });

    test('corrections are excluded but do not hide the real fills', () {
      final fills = [
        ...regular(),
        fill(
            id: 'c',
            litres: 40,
            pricePerLitre: 9.99,
            daysAgo: 5,
            correction: true),
      ];
      final b = baseline(fills)!;
      expect(b.sampleCount, 4);
      expect(b.typicalPricePerLitre, closeTo(1.70, 0.001));
    });
  });

  group('per fuel and per vehicle', () {
    test('two fuels keep two baselines', () {
      final fills = [
        ...regular(price: 1.70),
        for (var i = 0; i < 4; i++)
          fill(
            id: 'e85-$i',
            litres: 50,
            pricePerLitre: 0.90,
            daysAgo: i * 10,
            fuel: FuelType.e85,
          ),
      ];
      expect(baseline(fills)!.typicalPricePerLitre, closeTo(1.70, 0.001));
      expect(baseline(fills, fuel: FuelType.e85)!.typicalPricePerLitre,
          closeTo(0.90, 0.001));
    });

    test('two vehicles do not share one — the caller scopes first', () {
      // The baseline is a pure function over the fills it is handed, and
      // the production path hands it `activeVehicleFillUpsProvider`.
      // This pins the composition: scope, then baseline. Mixing a
      // 40 L hatchback with a 70 L estate makes BOTH numbers wrong.
      const hatch = VehicleProfile(id: 'hatch', name: 'Hatch');
      const estate = VehicleProfile(id: 'estate', name: 'Estate');
      final fills = [
        for (var i = 0; i < 4; i++)
          fill(
              id: 'h$i',
              litres: 40,
              pricePerLitre: 1.70,
              daysAgo: i * 10,
              vehicleId: 'hatch'),
        for (var i = 0; i < 4; i++)
          fill(
              id: 'e$i',
              litres: 70,
              pricePerLitre: 1.70,
              daysAgo: i * 10,
              vehicleId: 'estate'),
      ];

      final hatchBaseline = baseline(
          scopeFillUpsToVehicle(fills, vehicle: hatch, vehicleCount: 2))!;
      final estateBaseline = baseline(
          scopeFillUpsToVehicle(fills, vehicle: estate, vehicleCount: 2))!;

      expect(hatchBaseline.typicalLitres, closeTo(40, 0.01));
      expect(estateBaseline.typicalLitres, closeTo(70, 0.01));

      // And the unscoped answer is the one nobody should ever show: a
      // 55 L "usual fill" that neither car has ever bought.
      expect(baseline(fills)!.typicalLitres, closeTo(55, 0.01));
    });
  });
}
