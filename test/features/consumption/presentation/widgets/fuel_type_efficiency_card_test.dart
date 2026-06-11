// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fuel_type_efficiency_stats.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fuel_type_efficiency_card.dart';
import 'package:tankstellen/features/consumption/providers/fuel_type_efficiency_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Structural widget tests for the per-fuel-composition efficiency card
/// (#2928, ADR 0015). NO golden PNGs (Linux-CI golden trap) — these assert
/// presence / ordering / placeholder text via finders, now keyed by the
/// composition bucket (`E85` pure, `E85/E10` blend).
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

  /// A PURE bucket stats row for [fuel].
  FuelTypeEfficiencyStats pure({
    required FuelType fuel,
    double? l100,
    double? costPerKm,
    double totalSpent = 0,
    int fillCount = 0,
    int attributed = 0,
  }) =>
      FuelTypeEfficiencyStats(
        bucket: FuelEfficiencyBucket(dominant: fuel),
        avgL100km: l100,
        avgCostPerKm: costPerKm,
        totalSpent: totalSpent,
        fillCount: fillCount,
        attributedIntervalCount: attributed,
      );

  /// A MIX bucket stats row for [dominant]/[secondary].
  FuelTypeEfficiencyStats mix({
    required FuelType dominant,
    required FuelType secondary,
    double? l100,
    double? costPerKm,
    double totalSpent = 0,
    int fillCount = 0,
    int attributed = 0,
  }) =>
      FuelTypeEfficiencyStats(
        bucket: FuelEfficiencyBucket(dominant: dominant, secondary: secondary),
        avgL100km: l100,
        avgCostPerKm: costPerKm,
        totalSpent: totalSpent,
        fillCount: fillCount,
        attributedIntervalCount: attributed,
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
        pure(fuel: FuelType.e85, costPerKm: 0.086, fillCount: 3, attributed: 2),
        pure(fuel: FuelType.e10, costPerKm: 0.108, fillCount: 3, attributed: 2),
      ],
    );
    expect(find.byKey(const ValueKey('fuel_type_efficiency_card')),
        findsNothing);
  });

  testWidgets('hidden when fewer than two buckets are logged', (tester) async {
    await pumpCard(
      tester,
      vehicle: flexCar,
      data: [
        pure(fuel: FuelType.e85, costPerKm: 0.086, fillCount: 3, attributed: 2),
      ],
    );
    expect(find.byKey(const ValueKey('fuel_type_efficiency_card')),
        findsNothing);
  });

  testWidgets(
    'pure + mix buckets render in €/km order with the winner chip',
    (tester) async {
      // A pure E85 bucket and an E85/E10 blend, both clearing the verdict
      // gate → the cheaper one (the blend) is crowned across pure + mix.
      await pumpCard(
        tester,
        vehicle: flexCar,
        data: [
          mix(
            dominant: FuelType.e85,
            secondary: FuelType.e10,
            l100: 7.5,
            costPerKm: 0.072,
            totalSpent: 80,
            fillCount: 4,
            attributed: 2,
          ),
          pure(
            fuel: FuelType.e85,
            l100: 8.64,
            costPerKm: 0.086,
            totalSpent: 115,
            fillCount: 3,
            attributed: 2,
          ),
        ],
      );

      expect(find.byKey(const ValueKey('fuel_type_efficiency_card')),
          findsOneWidget);
      // Winner chip present, crowning the blend.
      expect(find.byKey(const ValueKey('fuel_efficiency_winner_chip')),
          findsOneWidget);
      // Both rows present — keyed by bucket key (pure: 'e85', mix: 'e85|e10').
      expect(find.byKey(const ValueKey('fuel_efficiency_row_e85')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('fuel_efficiency_row_e85|e10')),
          findsOneWidget);
      // Composition labels render.
      expect(find.text('E85/E10'), findsWidgets);

      // €/km ascending: the cheaper blend paints above the pure E85 row.
      final mixY = tester
          .getTopLeft(find.byKey(const ValueKey('fuel_efficiency_row_e85|e10')))
          .dy;
      final pureY = tester
          .getTopLeft(find.byKey(const ValueKey('fuel_efficiency_row_e85')))
          .dy;
      expect(mixY, lessThan(pureY),
          reason: 'cheapest €/km (the blend) sorts first');
    },
  );

  testWidgets(
    'mix row shows a Blend badge + "Mostly" dominant line; pure shows Pure',
    (tester) async {
      await pumpCard(
        tester,
        vehicle: flexCar,
        data: [
          pure(
            fuel: FuelType.e85,
            l100: 8.64,
            costPerKm: 0.086,
            totalSpent: 115,
            fillCount: 3,
            attributed: 2,
          ),
          mix(
            dominant: FuelType.e85,
            secondary: FuelType.e10,
            l100: 7.9,
            costPerKm: 0.099,
            totalSpent: 90,
            fillCount: 4,
            attributed: 2,
          ),
        ],
      );
      // Pure + Blend badges both render.
      expect(find.text('Pure'), findsOneWidget);
      expect(find.text('Blend'), findsOneWidget);
      // The blend names its dominant fuel.
      expect(find.textContaining('Mostly'), findsOneWidget);
      // The composition footnote discloses the bucketing rule.
      expect(
        find.textContaining('grouped by composition'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'insufficient data → NO winner chip + placeholder for the null per-km '
    'bucket, total-spent kept',
    (tester) async {
      await pumpCard(
        tester,
        vehicle: flexCar,
        data: [
          pure(
            fuel: FuelType.e85,
            l100: 8.64,
            costPerKm: 0.086,
            totalSpent: 115,
            fillCount: 3,
            attributed: 2,
          ),
          pure(
            fuel: FuelType.e10,
            totalSpent: 50,
            fillCount: 1,
            attributed: 1,
          ),
        ],
      );

      expect(find.byKey(const ValueKey('fuel_type_efficiency_card')),
          findsOneWidget);
      // No crown (E10 has only 1 attributed interval).
      expect(find.byKey(const ValueKey('fuel_efficiency_winner_chip')),
          findsNothing);
      // The insufficient-data footnote is shown.
      expect(
        find.text(
          'Log at least two full tanks per composition to crown the cheapest.',
        ),
        findsOneWidget,
      );
      // The null per-km bucket still keeps its total-spent figure.
      expect(find.textContaining('50'), findsWidgets);
      // The em-dash placeholder appears for the null L/100km & €/km cells.
      expect(find.textContaining('—'), findsWidgets);
    },
  );

  testWidgets(
    'odometer-reset edge: a bucket with attributed intervals but a '
    'clamped-to-zero distance shows "—" per-km, keeps totals, no crown',
    (tester) async {
      await pumpCard(
        tester,
        vehicle: flexCar,
        data: [
          pure(fuel: FuelType.e85, totalSpent: 115, fillCount: 3, attributed: 2),
          pure(fuel: FuelType.e10, totalSpent: 178.5, fillCount: 3,
              attributed: 2),
        ],
      );

      expect(find.byKey(const ValueKey('fuel_type_efficiency_card')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('fuel_efficiency_winner_chip')),
          findsNothing);
      expect(find.byKey(const ValueKey('fuel_efficiency_row_e85')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('fuel_efficiency_row_e10')),
          findsOneWidget);
      expect(find.textContaining('—'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'winner chip never shows a "(--)" cost: a crowned-but-null bucket is '
    'treated as no winner',
    (tester) async {
      await pumpCard(
        tester,
        vehicle: flexCar,
        data: [
          pure(fuel: FuelType.e85, totalSpent: 100, fillCount: 3, attributed: 2),
          pure(fuel: FuelType.e10, totalSpent: 120, fillCount: 3, attributed: 2),
        ],
      );
      expect(find.byKey(const ValueKey('fuel_efficiency_winner_chip')),
          findsNothing);
      expect(find.textContaining('(--)'), findsNothing);
    },
  );

  testWidgets('never throws on legacy/all fuel + zero data shape',
      (tester) async {
    await pumpCard(
      tester,
      vehicle: flexCar,
      data: [
        pure(fuel: FuelType.all, totalSpent: 10, fillCount: 1),
        pure(fuel: FuelType.e10, totalSpent: 20, fillCount: 1),
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
