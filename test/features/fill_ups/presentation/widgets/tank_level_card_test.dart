// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_level_estimator.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_mix_estimator.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_mix_provider.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/tank_level_card.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_level_provider.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Widget-level coverage for [TankLevelCard] (#1195).
///
/// The card itself is presentational — it reads
/// [tankLevelProvider] and reflects the [TankLevelEstimate] with a big
/// number, a range sub-text, a `LinearProgressIndicator`, and a method
/// caption. These tests pin:
///   * empty state when no fill-ups
///   * populated rendering of level + range
///   * low-fuel colour switch at < 15 % capacity
///   * detail bottom-sheet open on tap
///   * method-label localisation across the three enum values
class _StubVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'stub-vehicle',
          name: 'Stub Car',
          type: VehicleType.combustion,
          tankCapacityL: 50,
        ),
      ];
}

class _StubActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => const VehicleProfile(
        id: 'stub-vehicle',
        name: 'Stub Car',
        type: VehicleType.combustion,
        tankCapacityL: 50,
      );
}

List<Object> _activeVehicleOverrides() => <Object>[
      vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
      activeVehicleProfileProvider.overrideWith(() => _StubActiveVehicle()),
    ];

List<Object> _tankLevelOverride(TankLevelEstimate estimate) => <Object>[
      ..._activeVehicleOverrides(),
      tankLevelProvider('stub-vehicle').overrideWith((ref) => estimate),
    ];

void main() {
  group('TankLevelCard — populated rendering', () {
    testWidgets('renders the localized title and big number',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 32.4,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 462,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(find.text('Tank level'), findsOneWidget);
      expect(find.text('32,4 L'), findsOneWidget);
    });

    testWidgets('renders the range sub-text when rangeKm is non-null',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 32.4,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 462,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(find.textContaining('462'), findsOneWidget);
      expect(find.textContaining('km of range'), findsOneWidget);
    });

    testWidgets('renders the LinearProgressIndicator with the fraction',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 25,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 357,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('tank_level_progress')),
      );
      expect(bar.value, closeTo(0.5, 0.0001));
    });
  });

  group('TankLevelCard — range at last consumption (#3764)', () {
    TankLevelEstimate estimate({
      double? rangeKm,
      double? rangeKmLastInterval,
    }) =>
        TankLevelEstimate(
          levelL: 32.4,
          capacityL: 50,
          lastFillUpDate: DateTime(2026, 4, 27),
          source: TankLevelSource.fillUp,
          sensorReadAt: null,
          rangeKm: rangeKm,
          rangeKmLastInterval: rangeKmLastInterval,
        );

    testWidgets('leads with the last-interval projection and shows the '
        'long-run average as secondary context', (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(
          estimate(rangeKm: 405, rangeKmLastInterval: 324),
        ),
      );

      // Primary line = the last-tank projection.
      expect(
        find.text("≈ 324 km at your last tank's consumption"),
        findsOneWidget,
      );
      // Secondary context = the long-run figure.
      expect(find.text('Long-run average: ≈ 405 km'), findsOneWidget);
      // The generic range string does NOT render.
      expect(find.textContaining('km of range'), findsNothing);
    });

    testWidgets('no closed interval yet → today\'s long-run range string, '
        'no long-run context line', (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate(rangeKm: 462)),
      );

      expect(find.textContaining('462'), findsOneWidget);
      expect(find.textContaining('km of range'), findsOneWidget);
      expect(find.byKey(const Key('tank_level_range_long_run')), findsNothing);
      expect(find.textContaining("last tank's consumption"), findsNothing);
    });

    testWidgets('long-run context hidden when it rounds to the same figure '
        'as the last-interval projection', (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(
          estimate(rangeKm: 324.2, rangeKmLastInterval: 324.4),
        ),
      );

      expect(
        find.text("≈ 324 km at your last tank's consumption"),
        findsOneWidget,
      );
      expect(find.byKey(const Key('tank_level_range_long_run')), findsNothing);
    });
  });

  group('TankLevelCard — low-fuel colouring', () {
    testWidgets('applies error colour to the bar at < 15% capacity',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 6, // 6 / 50 = 12 % → low-fuel
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 86,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('tank_level_progress')),
      );
      // The bar's color reflects the theme's error colour at < 15 %.
      // We check non-null + non-default; the exact MaterialColor varies
      // by theme so we just lock in that the override fired.
      expect(bar.color, isNotNull);
    });

    testWidgets('does NOT apply low-fuel colouring at >= 15% capacity',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 10, // 20 %
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 143,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('tank_level_progress')),
      );
      // Above the threshold the widget passes `null` for color so the
      // theme's primary tint takes over.
      expect(bar.color, isNull);
    });
  });

  group('TankLevelCard — empty state', () {
    testWidgets('shows the "Log a fill-up" message when there are no fills',
        (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(const TankLevelEstimate.unknown()),
      );

      expect(find.text('Log a fill-up to see your tank level'), findsOneWidget);
      // No big number / progress bar in the empty state.
      expect(find.byKey(const Key('tank_level_big_number')), findsNothing);
      expect(find.byKey(const Key('tank_level_progress')), findsNothing);
    });
  });

  group('TankLevelCard — detail sheet', () {
    testWidgets('tap opens the bottom sheet with the localized title',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 32.4,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 462,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      await tester.tap(find.byType(TankLevelCard));
      await tester.pumpAndSettle();

      expect(find.text('Trips since last fill-up'), findsOneWidget);
    });
  });

  group('TankLevelCard — method label', () {
    testWidgets('fill-up source captions the anchor date (#3647)',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 30,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 400,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(
        // #3903 — localized medium date, not a raw YYYY-MM-DD.
        find.textContaining('Anchored at the last fill-up: Apr 27, 2026'),
        findsOneWidget,
      );
    });

    testWidgets('OBD2-sensor source captions the reading date (#3647)',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 28.5,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.obd2Sensor,
        sensorReadAt: DateTime(2026, 4, 29),
        rangeKm: 380,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(
        find.textContaining('OBD2 tank sensor · Apr 29, 2026'),
        findsOneWidget,
      );
    });
  });

  group('TankLevelCard — tank mix line (#3652)', () {
    TankLevelEstimate estimate() => TankLevelEstimate(
          levelL: 32.4,
          capacityL: 50,
          lastFillUpDate: DateTime(2026, 4, 27),
          source: TankLevelSource.fillUp,
          sensorReadAt: null,
          rangeKm: 462,
        );

    testWidgets('renders the blend of a multi-fuel tank with grade names '
        'and percentages', (tester) async {
      final mix = TankMixEstimate(
        shares: const [
          TankMixShare(fuel: FuelType.e10, share: 0.57),
          TankMixShare(fuel: FuelType.e85, share: 0.43),
        ],
        asOf: DateTime(2026, 4, 27),
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._tankLevelOverride(estimate()),
          tankMixProvider('stub-vehicle').overrideWith((ref) => mix),
        ],
      );

      expect(find.byKey(const Key('tank_mix_line')), findsOneWidget);
      expect(
        find.textContaining('Super E10 57 %'),
        findsOneWidget,
      );
      expect(
        find.textContaining('E85'),
        findsOneWidget,
      );
    });

    testWidgets('no mix line for a single-fuel vehicle (provider null)',
        (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._tankLevelOverride(estimate()),
          tankMixProvider('stub-vehicle').overrideWith((ref) => null),
        ],
      );
      expect(find.byKey(const Key('tank_mix_line')), findsNothing);
    });

    testWidgets('a pure tank (100 % one grade) stays silent', (tester) async {
      final mix = TankMixEstimate(
        shares: const [TankMixShare(fuel: FuelType.e85, share: 1.0)],
        asOf: DateTime(2026, 4, 27),
      );
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._tankLevelOverride(estimate()),
          tankMixProvider('stub-vehicle').overrideWith((ref) => mix),
        ],
      );
      expect(find.byKey(const Key('tank_mix_line')), findsNothing);
    });

    testWidgets('an UNWIRED mix graph degrades silently — shell safety '
        '(#2163)', (tester) async {
      // No tankMixProvider override: the provider reaches
      // fillUpListProvider, which isolated harnesses don't wire; the
      // guard must swallow it and render no mix line.
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate()),
      );
      expect(find.byKey(const Key('tank_mix_line')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
