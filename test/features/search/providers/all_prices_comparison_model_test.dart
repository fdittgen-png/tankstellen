// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/providers/all_prices_comparison_model.dart';

/// #3933 — the maths behind the all-prices comparison table.
///
/// Pins the two numbers the view exists for: the delta against the
/// cheapest of the current results, and the cost of 100 km per fuel.
void main() {
  const franceFuels = <FuelType>{
    FuelType.e5,
    FuelType.e10,
    FuelType.e98,
    FuelType.diesel,
    FuelType.e85,
    FuelType.lpg,
    FuelType.electric,
  };

  const germanyFuels = <FuelType>{
    FuelType.e5,
    FuelType.e10,
    FuelType.diesel,
    FuelType.electric,
  };

  const flexStation = Station(
    id: 'fr-1',
    name: 'Flex',
    brand: 'TOTAL',
    street: 'Grande Rue',
    postCode: '34000',
    place: 'Montpellier',
    lat: 43.61,
    lng: 3.88,
    e10: 2.089,
    e98: 2.189,
    diesel: 1.929,
    e85: 0.839,
    isOpen: true,
  );

  group('selectFuelColumns', () {
    test('a country that fits keeps every fuel, in canonical order', () {
      final columns = selectFuelColumns(
        countryFuels: germanyFuels,
        vehicleFuels: const {},
        bestByFuel: const {},
      );

      expect(columns.visible, [FuelType.e5, FuelType.e10, FuelType.diesel]);
      expect(columns.overflow, isEmpty);
    });

    test('electric never takes a column — this is the liquid-fuel table', () {
      final columns = selectFuelColumns(
        countryFuels: germanyFuels,
        vehicleFuels: const {},
        bestByFuel: const {},
      );

      expect(columns.all, isNot(contains(FuelType.electric)));
    });

    test(
      'an overflowing country keeps the vehicle fuels and pushes the rest '
      'behind the expander',
      () {
        // A flex-fuel petrol car: E10 / E5 / E98 / E85 are all pumpable.
        final columns = selectFuelColumns(
          countryFuels: franceFuels,
          vehicleFuels: compatibleFuelsFor(FuelType.e10).toSet(),
          bestByFuel: const {FuelType.diesel: 1.7, FuelType.lpg: 0.9},
        );

        expect(columns.visible.length, kAllPricesMaxColumns);
        // Canonical order is preserved, so the columns line up across cards.
        expect(columns.visible, [
          FuelType.e5,
          FuelType.e10,
          FuelType.e98,
          FuelType.e85,
        ]);
        expect(columns.overflow, [FuelType.diesel, FuelType.lpg]);
      },
    );

    test(
      'with no vehicle the spare slots go to the cheapest fuels, still in '
      'canonical order',
      () {
        final columns = selectFuelColumns(
          countryFuels: franceFuels,
          vehicleFuels: const {},
          bestByFuel: const {
            FuelType.e5: 1.95,
            FuelType.e10: 1.89,
            FuelType.e98: 2.19,
            FuelType.diesel: 1.79,
            FuelType.e85: 0.84,
            FuelType.lpg: 0.95,
          },
        );

        // Cheapest four are e85, lpg, diesel, e10 — rendered canonically.
        expect(columns.visible, [
          FuelType.e10,
          FuelType.diesel,
          FuelType.e85,
          FuelType.lpg,
        ]);
        expect(columns.overflow, [FuelType.e5, FuelType.e98]);
      },
    );

    test('an unpriced fuel sorts last when filling the spare slots', () {
      final columns = selectFuelColumns(
        countryFuels: franceFuels,
        vehicleFuels: const {},
        bestByFuel: const {
          FuelType.e5: 1.95,
          FuelType.e10: 1.89,
          FuelType.diesel: 1.79,
          FuelType.e85: 0.84,
        },
        maxColumns: 4,
      );

      expect(columns.visible, isNot(contains(FuelType.e98)));
      expect(columns.visible, isNot(contains(FuelType.lpg)));
    });
  });

  group('bestPriceByFuel', () {
    test('takes the minimum per fuel and ignores out-of-stock rows', () {
      const dear = Station(
        id: 'a',
        name: 'a',
        brand: 'A',
        street: 's',
        postCode: '1',
        place: 'p',
        lat: 0,
        lng: 0,
        e10: 1.999,
        diesel: 1.899,
      );
      const cheapButEmpty = Station(
        id: 'b',
        name: 'b',
        brand: 'B',
        street: 's',
        postCode: '1',
        place: 'p',
        lat: 0,
        lng: 0,
        e10: 1.799,
        diesel: 1.499,
        unavailableFuels: ['diesel'],
      );

      final best = bestPriceByFuel(const [dear, cheapButEmpty]);

      expect(best[FuelType.e10], closeTo(1.799, 1e-9));
      // The 1,499 diesel is flagged out of stock, so it is not a reference.
      expect(best[FuelType.diesel], closeTo(1.899, 1e-9));
    });
  });

  group('buildStationComparison', () {
    const columns = AllPricesColumns(
      visible: [FuelType.e10, FuelType.e98, FuelType.diesel, FuelType.e85],
      overflow: [FuelType.lpg],
    );

    test('delta is measured against the best price in the results', () {
      final row = buildStationComparison(
        station: flexStation,
        columns: columns,
        bestByFuel: const {FuelType.e10: 2.029, FuelType.e85: 0.839},
      );

      final e10 = row.cells.firstWhere((c) => c.fuel == FuelType.e10);
      expect(e10.deltaToBest, closeTo(0.06, 1e-9));
      expect(e10.isBestInResults, isFalse);

      final e85 = row.cells.firstWhere((c) => c.fuel == FuelType.e85);
      expect(e85.deltaToBest, closeTo(0, 1e-9));
      expect(e85.isBestInResults, isTrue);
    });

    test('cost per 100 km is price x litres/100 km', () {
      final row = buildStationComparison(
        station: flexStation,
        columns: columns,
        bestByFuel: const {},
        litersPer100kmByFuel: const {FuelType.e85: 6.0, FuelType.e10: 4.6},
        usableFuels: const {FuelType.e10, FuelType.e85, FuelType.e98},
      );

      final e85 = row.cells.firstWhere((c) => c.fuel == FuelType.e85);
      expect(e85.costPer100km, closeTo(0.839 * 6.0, 1e-9));
      expect(e85.litersPer100km, 6.0);

      final e10 = row.cells.firstWhere((c) => c.fuel == FuelType.e10);
      expect(e10.costPer100km, closeTo(2.089 * 4.6, 1e-9));
    });

    test('the verdict names the fuel that is cheapest per 100 km here', () {
      final row = buildStationComparison(
        station: flexStation,
        columns: columns,
        bestByFuel: const {FuelType.e85: 0.839},
        litersPer100kmByFuel: const {FuelType.e85: 6.0, FuelType.e10: 4.6},
        usableFuels: const {FuelType.e10, FuelType.e85},
      );

      // 0,839 x 6,0 = 5,03 vs 2,089 x 4,6 = 9,61 — E85 wins on cost, even
      // though it burns 30% more litres.
      expect(row.verdictFuel, FuelType.e85);
      expect(row.verdictCostPer100km, closeTo(5.034, 1e-3));
      expect(row.hasVerdict, isTrue);
      // Its price is also the best in the results.
      expect(row.winsResults, isTrue);
    });

    test('an overflow fuel can still win the verdict', () {
      const lpgStation = Station(
        id: 'fr-2',
        name: 'LPG',
        brand: 'TOTAL',
        street: 's',
        postCode: '1',
        place: 'p',
        lat: 0,
        lng: 0,
        e10: 2.089,
        lpg: 0.959,
      );

      final row = buildStationComparison(
        station: lpgStation,
        columns: columns,
        bestByFuel: const {},
        litersPer100kmByFuel: const {FuelType.e10: 4.6, FuelType.lpg: 7.0},
        usableFuels: const {FuelType.e10, FuelType.lpg},
      );

      expect(row.verdictFuel, FuelType.lpg);
      expect(row.overflowCells.single.fuel, FuelType.lpg);
    });

    test('no consumption history — no per-100 km number, no verdict', () {
      final row = buildStationComparison(
        station: flexStation,
        columns: columns,
        bestByFuel: const {FuelType.e10: 2.029},
      );

      expect(row.cells.every((c) => c.costPer100km == null), isTrue);
      expect(row.verdictFuel, isNull);
      expect(row.hasVerdict, isFalse);
      // …but the price table with its deltas survives.
      final e10 = row.cells.firstWhere((c) => c.fuel == FuelType.e10);
      expect(e10.price, 2.089);
      expect(e10.deltaToBest, closeTo(0.06, 1e-9));
    });

    test('a fuel the vehicle cannot take is dimmed and gets no cost', () {
      final row = buildStationComparison(
        station: flexStation,
        columns: columns,
        bestByFuel: const {},
        litersPer100kmByFuel: const {FuelType.diesel: 4.0, FuelType.e85: 6.0},
        usableFuels: const {FuelType.e10, FuelType.e5, FuelType.e98,
          FuelType.e85},
      );

      final diesel = row.cells.firstWhere((c) => c.fuel == FuelType.diesel);
      expect(diesel.isUsable, isFalse);
      expect(diesel.costPer100km, isNull);
      expect(row.verdictFuel, FuelType.e85);
    });

    test('a fuel the station does not sell keeps a blank column', () {
      final row = buildStationComparison(
        station: flexStation,
        columns: columns,
        bestByFuel: const {},
      );

      expect(row.cells.length, columns.visible.length);
      final e5Absent = row.cells.where((c) => c.fuel == FuelType.e5);
      expect(e5Absent, isEmpty, reason: 'e5 is not one of these columns');
      final lpg = row.overflowCells.single;
      expect(lpg.isBlank, isTrue);
      expect(lpg.price, isNull);
    });

    test('an out-of-stock fuel is never the best and carries no delta', () {
      const outOfStock = Station(
        id: 'fr-3',
        name: 'x',
        brand: 'X',
        street: 's',
        postCode: '1',
        place: 'p',
        lat: 0,
        lng: 0,
        e10: 1.799,
        unavailableFuels: ['e10'],
      );

      final row = buildStationComparison(
        station: outOfStock,
        columns: columns,
        bestByFuel: const {FuelType.e10: 1.799},
      );

      final e10 = row.cells.firstWhere((c) => c.fuel == FuelType.e10);
      expect(e10.isUnavailable, isTrue);
      expect(e10.isBestInResults, isFalse);
      expect(e10.deltaToBest, isNull);
    });
  });
}
