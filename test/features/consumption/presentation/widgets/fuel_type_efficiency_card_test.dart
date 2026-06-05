// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fuel_type_efficiency_stats.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fuel_type_efficiency_card.dart';
import 'package:tankstellen/features/consumption/providers/fuel_type_efficiency_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Structural widget tests for the per-fuel efficiency card (#2887,
/// Epic #2881). NO golden PNGs (Linux-CI golden trap) — these assert
/// presence / ordering / placeholder text via finders.
void main() {
  const flexCar = VehicleProfile(
    id: 'flex-1',
    name: 'Saxo Flex',
    type: VehicleType.combustion,
    preferredFuelType: 'e85',
    multiFuelCapable: true,
  );

  const singleFuelCar = VehicleProfile(
    id: 'mono-1',
    name: 'Golf',
    type: VehicleType.combustion,
    preferredFuelType: 'e10',
  );

  FuelTypeEfficiencyStats stats({
    required FuelType fuel,
    double? l100,
    double? costPerKm,
    double totalSpent = 0,
    int fillCount = 0,
    int attributed = 0,
    int mixed = 0,
  }) =>
      FuelTypeEfficiencyStats(
        fuelType: fuel,
        avgL100km: l100,
        avgCostPerKm: costPerKm,
        totalSpent: totalSpent,
        fillCount: fillCount,
        attributedIntervalCount: attributed,
        mixedIntervalCount: mixed,
      );

  Future<void> pumpCard(
    WidgetTester tester, {
    VehicleProfile? vehicle,
    required List<FuelTypeEfficiencyStats> data,
  }) async {
    await pumpApp(
      tester,
      const FuelTypeEfficiencyCard(),
      overrides: [
        activeVehicleProfileProvider.overrideWith(() => _FakeActive(vehicle)),
        fuelTypeEfficiencyComparisonProvider.overrideWithValue(data),
      ],
    );
  }

  testWidgets('hidden when the active vehicle is not multiFuelCapable',
      (tester) async {
    await pumpCard(
      tester,
      vehicle: singleFuelCar,
      data: [
        stats(fuel: FuelType.e85, costPerKm: 0.086, fillCount: 3, attributed: 2),
        stats(fuel: FuelType.e10, costPerKm: 0.108, fillCount: 3, attributed: 2),
      ],
    );
    expect(find.byKey(const ValueKey('fuel_type_efficiency_card')),
        findsNothing);
  });

  testWidgets('hidden when fewer than two fuels are logged', (tester) async {
    await pumpCard(
      tester,
      vehicle: flexCar,
      data: [
        stats(fuel: FuelType.e85, costPerKm: 0.086, fillCount: 3, attributed: 2),
      ],
    );
    expect(find.byKey(const ValueKey('fuel_type_efficiency_card')),
        findsNothing);
  });

  testWidgets(
    '2+ fuels render in €/km order with the winner chip when the gate opens',
    (tester) async {
      // Both fuels clear the 2-interval verdict gate → crown E85.
      await pumpCard(
        tester,
        vehicle: flexCar,
        data: [
          stats(
            fuel: FuelType.e85,
            l100: 8.64,
            costPerKm: 0.086,
            totalSpent: 115,
            fillCount: 3,
            attributed: 2,
          ),
          stats(
            fuel: FuelType.e10,
            l100: 7.08,
            costPerKm: 0.108,
            totalSpent: 178.5,
            fillCount: 3,
            attributed: 2,
          ),
        ],
      );

      expect(find.byKey(const ValueKey('fuel_type_efficiency_card')),
          findsOneWidget);
      // Winner chip present.
      expect(find.byKey(const ValueKey('fuel_efficiency_winner_chip')),
          findsOneWidget);
      // Both rows present.
      expect(find.byKey(const ValueKey('fuel_efficiency_row_e85')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('fuel_efficiency_row_e10')),
          findsOneWidget);

      // €/km ascending: the E85 row paints above the E10 row.
      final e85Y = tester
          .getTopLeft(find.byKey(const ValueKey('fuel_efficiency_row_e85')))
          .dy;
      final e10Y = tester
          .getTopLeft(find.byKey(const ValueKey('fuel_efficiency_row_e10')))
          .dy;
      expect(e85Y, lessThan(e10Y),
          reason: 'cheapest €/km (E85) sorts first');
    },
  );

  testWidgets(
    'insufficient data → NO winner chip + placeholder for the null per-km '
    'fuel, total-spent kept',
    (tester) async {
      // E10 has only 1 attributed interval → verdict gate stays shut; the
      // minority fuel has 0 attributed intervals → null per-km metrics.
      await pumpCard(
        tester,
        vehicle: flexCar,
        data: [
          stats(
            fuel: FuelType.e85,
            l100: 8.64,
            costPerKm: 0.086,
            totalSpent: 115,
            fillCount: 3,
            attributed: 2,
          ),
          stats(
            fuel: FuelType.e10,
            totalSpent: 50,
            fillCount: 1,
            attributed: 0,
          ),
        ],
      );

      expect(find.byKey(const ValueKey('fuel_type_efficiency_card')),
          findsOneWidget);
      // No crown.
      expect(find.byKey(const ValueKey('fuel_efficiency_winner_chip')),
          findsNothing);
      // The insufficient-data footnote is shown.
      expect(
        find.text(
          'Log at least two full tanks per fuel to crown the cheapest.',
        ),
        findsOneWidget,
      );
      // The null per-km fuel still keeps its total-spent figure.
      expect(find.textContaining('50'), findsWidgets);
      // The em-dash placeholder appears for the null L/100km & €/km cells.
      expect(find.textContaining('—'), findsWidgets);
    },
  );

  testWidgets('mixed-tank footnote is shown when any mixedIntervalCount > 0',
      (tester) async {
    await pumpCard(
      tester,
      vehicle: flexCar,
      data: [
        stats(
          fuel: FuelType.e85,
          l100: 8.64,
          costPerKm: 0.086,
          totalSpent: 115,
          fillCount: 3,
          attributed: 2,
        ),
        stats(
          fuel: FuelType.e10,
          l100: 7.08,
          costPerKm: 0.108,
          totalSpent: 178.5,
          fillCount: 3,
          attributed: 2,
          mixed: 1,
        ),
      ],
    );

    expect(
      find.text('1 mixed tank counted toward its main fuel'),
      findsOneWidget,
    );
  });

  testWidgets(
    '#2888 — odometer-reset edge: a fuel with attributed intervals but a '
    'clamped-to-zero distance shows "—" per-km, keeps totals, no crown',
    (tester) async {
      // Mirrors the aggregator clamp: an odometer reset zeroes the
      // interval distance, so avgL100km / avgCostPerKm come back null even
      // though the fuel HAS an attributed interval. The card must null-skip
      // the per-km cells and withhold the crown (no fuel has a €/km).
      await pumpCard(
        tester,
        vehicle: flexCar,
        data: [
          stats(
            fuel: FuelType.e85,
            totalSpent: 115,
            fillCount: 3,
            attributed: 2,
          ),
          stats(
            fuel: FuelType.e10,
            totalSpent: 178.5,
            fillCount: 3,
            attributed: 2,
          ),
        ],
      );

      expect(find.byKey(const ValueKey('fuel_type_efficiency_card')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('fuel_efficiency_winner_chip')),
          findsNothing);
      // Both rows render with placeholders but keep the spent totals.
      expect(find.byKey(const ValueKey('fuel_efficiency_row_e85')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('fuel_efficiency_row_e10')),
          findsOneWidget);
      expect(find.textContaining('—'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('never throws on legacy/all fuel + zero data shape',
      (tester) async {
    // A degenerate "all" wildcard fuel with null metrics must render
    // without crashing (defensive against legacy data).
    await pumpCard(
      tester,
      vehicle: flexCar,
      data: [
        stats(fuel: FuelType.all, totalSpent: 10, fillCount: 1),
        stats(fuel: FuelType.e10, totalSpent: 20, fillCount: 1),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('fuel_type_efficiency_card')),
        findsOneWidget);
  });
}

/// Override that pins the active vehicle for the card under test.
class _FakeActive extends ActiveVehicleProfile {
  _FakeActive(this._vehicle);

  final VehicleProfile? _vehicle;

  @override
  VehicleProfile? build() => _vehicle;
}
