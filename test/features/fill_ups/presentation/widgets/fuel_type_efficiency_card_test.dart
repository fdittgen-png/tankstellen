// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fuel_type_efficiency_stats.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fuel_type_efficiency_card.dart';
import 'package:tankstellen/features/fill_ups/providers/fuel_type_efficiency_provider.dart';
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
      // #3828 — pump inside a scrollable, which is how the card is actually
      // used: consumption_statistics_screen.dart puts it in a ListView. A
      // bare Scaffold gives the card the screen's exact height, so the card
      // growing by a few lines reads as a RenderFlex overflow rather than as
      // the scrolling content it really is. Assertions are unchanged.
      const SingleChildScrollView(child: FuelTypeEfficiencyCard()),
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
    '#3764 — every bucket row (pure AND mix) shows its interval count '
    'first-class next to the fill count',
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
            secondary: FuelType.e5,
            l100: 7.5,
            costPerKm: 0.072,
            totalSpent: 80,
            fillCount: 4,
            attributed: 1,
          ),
        ],
      );

      // Both counts lines render, keyed per bucket.
      expect(find.byKey(const ValueKey('fuel_efficiency_counts_e85')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('fuel_efficiency_counts_e85|e5')),
          findsOneWidget);
      // Interval count + fill count on one line, per row.
      expect(find.text('2 full tanks · 3 fills'), findsOneWidget);
      expect(find.text('1 full tank · 4 fills'), findsOneWidget);
      // The mix row still carries its blend label + metrics first-class.
      expect(find.text('E85/E5'), findsWidgets);
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

  testWidgets('#3828 states the cost/emissions trade-off, not just prices',
      (tester) async {
    // The field shape: E5 cheaper per km, E85 markedly cleaner (WTW 1.40 vs
    // 2.31 kg/L). A cost-only screen cannot express that, which is exactly
    // why the emissions axis was added.
    await pumpCard(
      tester,
      vehicle: flexCar,
      data: [
        pure(
            fuel: FuelType.e5,
            l100: 6.4,
            costPerKm: 0.057,
            totalSpent: 32.12,
            fillCount: 2,
            attributed: 2),
        pure(
            fuel: FuelType.e85,
            l100: 5.5,
            costPerKm: 0.070,
            totalSpent: 130.09,
            fillCount: 3,
            attributed: 3),
      ],
    );

    expect(find.byKey(const ValueKey('fuel_compare_analysis')), findsOneWidget);
    expect(find.byKey(const ValueKey('fuel_compare_verdict')), findsOneWidget);
    // Cheapest and cleanest are DIFFERENT fuels here, so a trade-off must be
    // stated rather than the "wins on both" line.
    expect(find.byKey(const ValueKey('fuel_compare_cleanest')), findsOneWidget);
    expect(find.byKey(const ValueKey('fuel_compare_tradeoff')), findsOneWidget);
    // Break-even is the actionable number for a flex-fuel driver.
    expect(find.byKey(const ValueKey('fuel_compare_breakeven_e85')),
        findsOneWidget);
    // The CO2 figures name their source and intended precision.
    expect(find.byKey(const ValueKey('fuel_compare_co2_source')),
        findsOneWidget);
  });

  testWidgets('#3828 says so plainly when one fuel wins on BOTH axes',
      (tester) async {
    // E10 is cheaper per km AND has the lower factor (2.27 vs 2.31), so
    // there is nothing to weigh.
    await pumpCard(
      tester,
      vehicle: flexCar,
      data: [
        pure(
            fuel: FuelType.e10,
            l100: 6.0,
            costPerKm: 0.050,
            totalSpent: 60,
            fillCount: 2,
            attributed: 2),
        pure(
            fuel: FuelType.e5,
            l100: 6.4,
            costPerKm: 0.060,
            totalSpent: 60,
            fillCount: 2,
            attributed: 2),
      ],
    );
    expect(find.byKey(const ValueKey('fuel_compare_both_e5')), findsOneWidget);
    expect(find.byKey(const ValueKey('fuel_compare_tradeoff')), findsNothing,
        reason: 'inventing a trade-off where none exists would be noise');
  });

  testWidgets('#3828 a blend carries no invented CO2 figure', (tester) async {
    await pumpCard(
      tester,
      vehicle: flexCar,
      data: [
        pure(
            fuel: FuelType.e85,
            l100: 8.6,
            costPerKm: 0.086,
            totalSpent: 115,
            fillCount: 3,
            attributed: 2),
        mix(
            dominant: FuelType.e85,
            secondary: FuelType.e10,
            l100: 7.5,
            costPerKm: 0.072,
            totalSpent: 80,
            fillCount: 4,
            attributed: 2),
      ],
    );
    // A blend's true factor depends on shares the row does not record.
    expect(find.byKey(const ValueKey('fuel_efficiency_co2_e85|e10')),
        findsNothing);
    expect(find.byKey(const ValueKey('fuel_efficiency_co2_e85')),
        findsOneWidget);
    // And the omission is explained rather than left as a silent gap.
    expect(find.byKey(const ValueKey('fuel_compare_co2_blend_note')),
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
